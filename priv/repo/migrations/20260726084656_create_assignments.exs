defmodule StudentLive.Repo.Migrations.CreateAssignments do
  use Ecto.Migration

  def change do
    create table(:assignments) do
      add :title, :string, null: false
      add :description, :text
      add :maximum_submissions_per_student, :integer, null: false, default: 1
      add :course_id, references(:courses, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:assignments, [:course_id])
  end
end
