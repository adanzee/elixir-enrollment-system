defmodule StudentLive.Schemas.Enrollment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "enrollments" do
    field :status, Ecto.Enum, values: [:active, :waitlisted], default: :active

    belongs_to :student, StudentLive.Schemas.Student
    belongs_to :course, StudentLive.Schemas.Course

    timestamps()
  end

  def changeset(enrollment, attrs) do
    enrollment
    |> cast(attrs, [:student_id, :course_id, :status])
    |> validate_required([:student_id, :course_id, :status])
    |> unique_constraint([:student_id, :course_id], name: :enrollments_student_id_course_id_index, message: "Student is already enrolled in this course")
  end
end
