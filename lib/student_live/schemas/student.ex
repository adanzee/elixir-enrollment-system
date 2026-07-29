defmodule StudentLive.Schemas.Student do
  use Ecto.Schema
  import Ecto.Changeset

  schema "students" do
    field :name, :string
    field :email, :string

    has_many :enrollments, StudentLive.Schemas.Enrollment
    has_many :courses, through: [:enrollments, :course]
    has_many :submissions, StudentLive.Schemas.Submission

    timestamps()
  end

  def changeset(student, attrs) do
    student
    |> cast(attrs, [:name, :email])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> unique_constraint(:email)
  end
end
