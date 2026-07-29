defmodule StudentLive.Repo.Migrations.CreateSubmissions do
  use Ecto.Migration

  def change do
    create table(:submissions) do
      add :file_name, :string, null: false
      add :file_path, :string, null: false
      add :file_size, :integer, null: false
      add :assignment_id, references(:assignments, on_delete: :delete_all), null: false
      add :student_id, references(:students, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:submissions, [:assignment_id])
    create index(:submissions, [:student_id])

  end
end
