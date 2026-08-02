defmodule StudentLive.Accounts do
  alias StudentLive.Repo
  alias StudentLive.Schemas.Student

  def get_student_by_email(email) when is_binary(email) do
    email = String.downcase(String.trim(email))
    Repo.get_by(Student, email: email)
  end

  def create_student(attrs) do
  %Student{}
  |> Student.changeset(attrs)
  |> Repo.insert()
  end

  def get_student!(id) do
  Repo.get!(Student, id)
 end

  def find_or_create_student(attrs) do
    case get_student_by_email(attrs.email) do
      nil ->
        create_student(attrs)
      student ->
        {:ok, student}
    end
  end
end
