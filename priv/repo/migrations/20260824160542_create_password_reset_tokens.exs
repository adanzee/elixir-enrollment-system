defmodule StudentLive.Repo.Migrations.CreatePasswordResetTokens do
  use Ecto.Migration

  def change do
    create table(:password_reset_tokens) do
      add :student_id, references(:students, on_delete: :delete_all), null: false
      add :token_hash, :string, null: false
      add :expires_at, :utc_datetime_usec, null: false
      add :used_at, :utc_datetime_usec
      add :revoked_at, :utc_datetime_usec

      timestamps()
    end

  end
end
