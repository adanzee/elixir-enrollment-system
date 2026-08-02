defmodule StudentLive.Repo.Migrations.CreateCourses do
  use Ecto.Migration

  def change do
   create table(:courses) do
      add :title, :string, null: false
      add :description, :text
      add :outline_pdf_path, :string
      add :start_date, :date, null: false
      add :end_date, :date, null: false
      add :maximum_capacity, :integer, null: false, default: 0
      add :current_enrollment_count, :integer, null: false, default: 0


      timestamps()
    end

  end
end
