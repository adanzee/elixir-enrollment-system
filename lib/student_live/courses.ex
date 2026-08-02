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


  def enrolled?(%StudentLive.Schemas.Student{id: student_id}, course_id) do
    enrolled?(student_id, course_id)
  end


  def enrolled?(student_id, course_id) when is_integer(student_id) and is_integer(course_id) do
    from(e in Enrollment, where: e.student_id == ^student_id and e.course_id == ^course_id and e.status == :active)
    |> Repo.exists?()
  end

  def enrolled?(_student, _course_id), do: false
def enroll_student(student_id, course_id) do
  Repo.transaction(fn ->

    course = lock_course(course_id)

    create_enrollment(student_id, course)

  end)
end


 def register_and_enroll(attrs, course_id) do
  Repo.transaction(fn ->

    course = lock_course(course_id)

    student =
      case Repo.get_by(Student, email: attrs["email"]) do
        nil ->
          case %Student{}
               |> Student.changeset(attrs)
               |> Repo.insert() do

            {:ok, student} ->
              student

            {:error, changeset} ->
              Repo.rollback(changeset)
          end

        student ->
          student
      end


    enrollment = create_enrollment(student.id, course)

    {student, enrollment}

  end)
end

  defp lock_course(course_id) do
    Course
    |> where(id: ^course_id)
    |> lock("FOR UPDATE")
    |> Repo.one!()
  end

  defp create_enrollment(student_id, course) do

  existing =
    Repo.get_by(
      Enrollment,
      student_id: student_id,
      course_id: course.id
    )


  case existing do
    %Enrollment{} ->
      Repo.rollback(:already_enrolled)


    nil ->

      active_count =
        Repo.aggregate(
          from(e in Enrollment,
            where:
              e.course_id == ^course.id and
              e.status == :active
          ),
          :count
        )


      status =
        if active_count < course.maximum_capacity do
          :active
        else
          :waitlisted
        end


      changeset =
        %Enrollment{}
        |> Enrollment.changeset(%{
          student_id: student_id,
          course_id: course.id,
          status: status
        })


      case Repo.insert(changeset) do

        {:ok, enrollment} ->
          enrollment


        {:error, changeset} ->
          Repo.rollback(changeset)

      end
  end
end

  def deregister_student(student_id, course_id) do
  enrollment = Repo.get_by(Enrollment, student_id: student_id, course_id: course_id)

  case enrollment do
    nil ->
      {:error, :not_found}

    enrollment ->
      course = Repo.get!(Course, course_id)

      if Date.compare(Date.utc_today(), course.start_date) != :lt do
        {:error, :course_started}
      else
        handle_deregister(enrollment, course_id)
      end
  end
end

  def get_assignment(id) do
    Repo.get(Assignment, id)
  end

  def get_course_with_enrollments!(id) do
  Course
  |> Repo.get!(id)
  |> Repo.preload([
    #
    assignments: from(a in StudentLive.Schemas.Assignment, order_by: [asc: a.id]),
    enrollments:
      from(e in StudentLive.Schemas.Enrollment,
        join: s in assoc(e, :student),
        preload: [student: s],
        order_by: [asc: e.inserted_at]
      )
  ])
  end



  def active_enrollment_count(course_id) do
  Enrollment
  |> where([e], e.course_id == ^course_id and e.status == :active)
  |> Repo.aggregate(:count, :id)
  end

  def get_course_status(course, active_count) do
  today = Date.utc_today()

  cond do
    Date.compare(today, course.start_date) != :lt ->
      "Started"

    active_count >= course.maximum_capacity ->
      "Full"

    true ->
      "Open"
  end
  end

  defp handle_deregister(%Enrollment{status: status} = enrollment, course_id) do
    case status do
      status when status in [:active, "active"] ->
      waitlisted_exists? =
        Repo.exists?(
          from e in Enrollment,
            where: e.course_id == ^course_id and e.status == :waitlisted
        )

      multi =
        Ecto.Multi.new()
        |> Ecto.Multi.delete(:delete_enrollment, enrollment)

      if waitlisted_exists? do
        changeset =
          StudentLive.Workers.ProcessWaitlistWorker.new(%{"course_id" => course_id})

        multi
        |> Oban.insert(:enqueue_waitlist_worker, changeset)
        |> Repo.transaction()
      else
        Repo.transaction(multi)
      end
    end
  end

  def get_enrollment_status(student_id, course_id) when is_integer(student_id) and is_integer(course_id) do
  case Repo.get_by(Enrollment, student_id: student_id, course_id: course_id) do
    nil -> nil
    %Enrollment{status: status} -> status
  end
  end

  def list_courses_with_capacity do
    from(c in Course, left_join: e in Enrollment,
    on: e.course_id == c.id and e.status == :active,
    group_by: c.id,
    select: %{
      c | active_enrollment_count: count(e.id)
    })
  |> Repo.all()
  end

  def get_assignment!(id), do: Repo.get!(Assignment, id)
end
