defmodule StudentLive.Repo.Migrations.CreateEnrollments do
  use Ecto.Migration

  def change do
    create table(:enrollments) do
      add :student_id, references(:students, on_delete: :delete_all), null: false
      add :course_id, references(:courses, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:enrollments, [:student_id, :course_id])
    create index(:enrollments, [:course_id])

  end
end
