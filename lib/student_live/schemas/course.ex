defmodule StudentLive.Schemas.Course do
  use Ecto.Schema
  import Ecto.Changeset

  schema "courses" do
    field :title, :string
    field :description, :string
    field :outline_pdf_path, :string
    field :start_date, :date
    field :end_date, :date
    field :maximum_capacity, :integer
    field :current_enrollment_count, :integer, default: 0

    has_many :assignments, StudentLive.Schemas.Assignment
    has_many :enrollments, StudentLive.Schemas.Enrollment
    has_many :students, through: [:enrollments, :student]

    timestamps()
  end

  def changeset(course, attrs) do
    course
    |> cast(attrs, [:title, :description, :outline_pdf_path, :start_date, :end_date, :maximum_capacity, :current_enrollment_count])
    |> validate_required([:title, :start_date, :end_date, :maximum_capacity])
    |> validate_number(:maximum_capacity, greater_than: 0)
  end
end
