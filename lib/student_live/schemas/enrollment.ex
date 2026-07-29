defmodule StudentLive.Schemas.Enrollment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "enrollments" do
    belongs_to :student, StudentLive.Schemas.Student
    belongs_to :course, StudentLive.Schemas.Course

    timestamps()
  end

  def changeset(enrollment, attrs) do
    enrollment
    |> cast(attrs, [:student_id, :course_id])
    |> validate_required([:student_id, :course_id])
    |> unique_constraint([:student_id, :course_id], message: "Student is already enrolled in this course")
  end
end
