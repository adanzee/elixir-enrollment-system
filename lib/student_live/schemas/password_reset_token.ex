defmodule StudentLive.Schemas.PasswordResetToken do
  use Ecto.Schema
  import Ecto.Changeset

  schema "password_reset_tokens" do
    belongs_to :student, StudentLive.Schemas.Student

    field :token_hash, :string
    field :expires_at, :utc_datetime_usec
    field :used_at, :utc_datetime_usec
    field :revoked_at, :utc_datetime_usec
    timestamps()

  end
  def changeset(password_reset_token, attrs) do
    password_reset_token
    |> cast(attrs, [:student_id, :token_hash, :expires_at, :used_at, :revoked_at])
    |> validate_required([:student_id, :token_hash, :expires_at])
  end
end
