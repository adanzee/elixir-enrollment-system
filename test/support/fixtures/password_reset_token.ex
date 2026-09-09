defmodule StudentLive.PasswordResetTokenFixtures do
  alias StudentLive.Repo
  alias StudentLive.Schemas.PasswordResetToken

  def password_reset_token_fixture(student_id, attrs \\ %{}) do
    raw_token =
      :crypto.strong_rand_bytes(32)
      |> Base.url_encode64(padding: false)

    token_hash =
      :crypto.hash(:sha256, raw_token)
      |> Base.encode16(case: :lower)

    default_attrs = %{
      student_id: student_id,
      token_hash: token_hash,
      expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
    }

    attrs = Map.merge(default_attrs, attrs)

    reset_token =
      %PasswordResetToken{}
      |> struct(attrs)
      |> Repo.insert!()

    %{
      raw_token: raw_token,
      reset_token: reset_token
    }
  end
end
