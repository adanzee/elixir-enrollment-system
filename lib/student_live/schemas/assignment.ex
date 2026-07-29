defmodule StudentLive.Schemas.Assignment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "assignments" do
    field :title, :string
    field :description, :string
    field :maximum_submissions_per_student, :integer, default: 1

    belongs_to :course, StudentLive.Schemas.Course
    has_many :submissions, StudentLive.Schemas.Submission

    timestamps()
  end

  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:title, :description, :maximum_submissions_per_student, :course_id])
    |> validate_required([:title, :maximum_submissions_per_student, :course_id])
    |> validate_number(:maximum_submissions_per_student, greater_than: 0)
  end
end
