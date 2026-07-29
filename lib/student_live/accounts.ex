defmodule StudentLive.Accounts do
  alias StudentLive.Repo
  alias StudentLive.Schemas.Student

  def get_student_by_email(email) when is_binary(email) do
    email = String.downcase(String.trim(email))
    Repo.get_by(Student, email: email)
  end

  def find_or_create_student(attrs) do
    email = attrs["email"] || attrs[:email]

    case get_student_by_email(email) do
      %Student{} = student ->
        {:ok, student}

      nil ->
        %Student{}
        |> Student.changeset(attrs)
        |> Repo.insert()
    end
  end
end
