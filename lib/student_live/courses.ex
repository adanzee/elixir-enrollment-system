defmodule StudentLive.Courses do
  import Ecto.Query
  alias StudentLive.Repo
  alias StudentLive.Schemas.{Course, Assignment, Enrollment}
  alias StudentLive.Schemas.Student

  def list_courses do
    Repo.all(Course)
  end

  def get_course!(id), do: Repo.get!(Course, id)

  def get_course_with_assignments!(id) do
    Course
    |> Repo.get!(id)
    |> Repo.preload(:assignments)
  end

 def get_course_status(%Course{} = course, today \\ Date.utc_today()) do
    cond do
      Date.compare(today, course.start_date) != :lt -> "Started"
      course.current_enrollment_count >= course.maximum_capacity -> "Full"
      true -> "Open"
    end
  end

 def enrolled?(student_id, course_id) when is_integer(student_id) and is_integer(course_id) do
    Repo.exists?(
      from e in Enrollment,
        where: e.student_id == ^student_id and e.course_id == ^course_id
    )
  end

  def enrolled?(%StudentLive.Schemas.Student{id: student_id}, course_id) do
    enrolled?(student_id, course_id)
  end

  def enrolled?(_student, _course_id), do: false

  def enroll_student(student_id, course_id, today \\ Date.utc_today()) do
    course = Repo.get!(Course, course_id)
    status = get_course_status(course, today)

    cond do
      status != "Open" ->
        {:error, "Cannot enroll. Course status is currently #{status}."}

      enrolled?(student_id, course_id) ->
        {:error, "Student is already enrolled in this course."}

      true ->
        Repo.transaction(fn ->
          changeset = Enrollment.changeset(%Enrollment{}, %{student_id: student_id, course_id: course_id})

          case Repo.insert(changeset) do
            {:ok, enrollment} ->
              from(c in Course, where: c.id == ^course_id)
              |> Repo.update_all(inc: [current_enrollment_count: 1])

              enrollment

            {:error, cs} ->
              Repo.rollback(cs)
          end
        end)
    end
  end

  # Explicitly find and delete the exact enrollment record
  def deregister_student(student_id, course_id, today \\ Date.utc_today()) do
    course = Repo.get!(Course, course_id)

    cond do
      Date.compare(today, course.start_date) != :lt ->
        {:error, "Cannot deregister from a course that has already started."}

      true ->
        case Repo.get_by(Enrollment, student_id: student_id, course_id: course_id) do
          nil ->
            {:error, "Student is not enrolled in this course."}

          %Enrollment{} = enrollment ->
            Repo.transaction(fn ->
              Repo.delete!(enrollment)


              from(c in Course, where: c.id == ^course_id and c.current_enrollment_count > 0)
              |> Repo.update_all(inc: [current_enrollment_count: -1])
            end)
            |> case do
              {:ok, _} -> {:ok, :deregistered}
              {:error, reason} -> {:error, reason}
            end
        end
    end
  end
  def get_assignment!(id), do: Repo.get!(Assignment, id)
end
