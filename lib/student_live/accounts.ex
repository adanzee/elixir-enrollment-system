defmodule StudentLive.Accounts do
  alias StudentLive.Repo
  alias StudentLive.Schemas.{Student, Enrollment}
  import Ecto.Query


  def authenticate_student(email, password) do
    student = get_student_by_email(email)

    cond do
      is_nil(student) ->
        {:error, :user_not_found}

      Bcrypt.verify_pass(password, student.hashed_password) ->
        {:ok, student}

      true ->
        {:error, :invalid_password}
    end
  end


  def create_student(attrs) do
  %Student{}
  |> Student.changeset(attrs)
  |> Repo.insert()
  end

  def get_student(id) do
  Repo.get(Student, id)
 end

 def get_student_by_email(email) do
  Student
  |> where(email: ^email)
  |> Repo.one()

 end

  def find_or_create_student(attrs) do
    case get_student_by_email(attrs.email) do
      nil ->
        create_student(attrs)
      student ->
        {:ok, student}
    end
  end

  def count_enrolled_courses(student_id) do
    Enrollment
    |> where([e], e.student_id == ^student_id)
    |> Repo.aggregate(:count, :id)
  end


end
