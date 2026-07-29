defmodule StudentLive.Schemas.Submission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "submissions" do
    field :file_name, :string
    field :file_path, :string
    field :file_size, :integer

    belongs_to :assignment, StudentLive.Schemas.Assignment
    belongs_to :student, StudentLive.Schemas.Student

    timestamps()
  end

  def changeset(submission, attrs) do
    submission
    |> cast(attrs, [:file_name, :file_path, :file_size, :assignment_id, :student_id])
    |> validate_required([:file_name, :file_path, :file_size, :assignment_id, :student_id])
  end
end
