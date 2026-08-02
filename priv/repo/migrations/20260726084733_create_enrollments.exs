defmodule StudentLive.Repo.Migrations.CreateEnrollments do
  use Ecto.Migration

  def change do
    create table(:enrollments) do
      add :student_id, references(:students, on_delete: :delete_all), null: false
      add :course_id, references(:courses, on_delete: :delete_all), null: false
      add :status, :string, null: false, default: "active"

      timestamps()
    end

    create unique_index(:enrollments, [:student_id, :course_id])
    create index(:enrollments, [:course_id])
    # for FIFO
    create index(:enrollments, [:course_id, :status, :inserted_at])

  end
end
