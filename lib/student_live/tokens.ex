defmodule StudentLive.Tokens do
  import Ecto.Query
  alias StudentLive.{Repo, Mailer}
  alias StudentLive.Schemas.Student
  alias StudentLive.Schemas.PasswordResetToken
  alias StudentLive.Emails.StudentEmail

  def request_password_reset(email) do
  case Repo.get_by(Student, email: email) do
    nil ->
      {:error, :student_not_found}

    student ->

      from(t in PasswordResetToken,
        where:
          t.student_id == ^student.id and
            is_nil(t.used_at) and
            is_nil(t.revoked_at),
        update: [set: [revoked_at: ^DateTime.utc_now()]]
      )
      |> Repo.update_all([])


      raw_token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)


      token_hash =
        :crypto.hash(:sha256, raw_token)
        |> Base.encode16(case: :lower)


      expires_at = DateTime.add(DateTime.utc_now(), 3600, :second)
      #environments base url, use helper function
      base_url = Application.fetch_env!(:student_live, :base_url)
      reset_url = "#{base_url}/reset-password?token=#{raw_token}"

      changeset =
        PasswordResetToken.changeset(%PasswordResetToken{}, %{
          student_id: student.id,
          token_hash: token_hash,
          expires_at: expires_at
        })

      case Repo.insert(changeset) do
        {:ok, _reset_token} ->
          student
          |> StudentEmail.password_reset(reset_url)
          |> Mailer.deliver()

          {:ok, raw_token}

        {:error, changeset} ->
          {:error, changeset}
      end
  end
end

def verify_reset_token(token) do
  token_hash =
    :crypto.hash(:sha256, token)
    |> Base.encode16(case: :lower)

  case Repo.get_by(PasswordResetToken, token_hash: token_hash) do
    nil ->
      {:error, :invalid_token}

    reset_token ->
      cond do
        not is_nil(reset_token.used_at) ->
          {:error, :token_already_used}

        not is_nil(reset_token.revoked_at) ->
          {:error, :token_revoked}

        DateTime.compare(reset_token.expires_at, DateTime.utc_now()) != :gt ->
          {:error, :token_expired}

        true ->
          {:ok, reset_token}
      end
  end
end

def reset_password(token, new_password) do
  case verify_reset_token(token) do
    {:ok, reset_token} ->
      student = Repo.get!(Student, reset_token.student_id)

      hashed_password = Bcrypt.hash_pwd_salt(new_password)

      Ecto.Multi.new()
      |> Ecto.Multi.update(
        :student,
        Ecto.Changeset.change(student, hashed_password: hashed_password)
      )
      |> Ecto.Multi.update(
        :token,
        Ecto.Changeset.change(reset_token, used_at: DateTime.utc_now())
      )
      |> Repo.transaction()
      |> case do
        {:ok, _result} ->
          {:ok, :password_reset}

        {:error, _step, changeset, _changes} ->
          {:error, changeset}
      end

    error ->
      error
  end
end
end
