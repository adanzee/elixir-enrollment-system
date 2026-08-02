defmodule StudentLive.Repo.Migrations.RemoveCurrentEnrollmentCountFromCourses do
  use Ecto.Migration

  def change do
  alter table(:courses) do
    remove :current_enrollment_count
  end
end
end
