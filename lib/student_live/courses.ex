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
      course =
        Course
        |> where(id: ^course_id)
        |> lock("FOR UPDATE")
        |> Repo.one!()

      active_count =
        Repo.aggregate(
          from(e in Enrollment, where: e.course_id == ^course_id and e.status == :active),
          :count
        )

      status = if active_count < course.maximum_capacity, do: :active, else: :waitlisted

      %Enrollment{}
      |> Enrollment.changeset(%{student_id: student_id, course_id: course_id, status: status})
      |> Repo.insert!()
    end)
  end

 def register_and_enroll(attrs, course_id) do
  Repo.transaction(fn ->

    course =
      Course
      |> where(id: ^course_id)
      |> lock("FOR UPDATE")
      |> Repo.one!()

    student =
      case Repo.get_by(Student, email: attrs["email"]) do
        nil ->
          %Student{}
          |> Student.changeset(attrs)
          |> Repo.insert!()

        student ->
          student
      end

    existing_enrollment =
      Repo.get_by(
        Enrollment,
        student_id: student.id,
        course_id: course_id
      )

    case existing_enrollment do
      %Enrollment{} ->
        Repo.rollback(:already_enrolled)

      nil ->
        active_count =
          Repo.aggregate(
            from(e in Enrollment,
              where:
                e.course_id == ^course_id and
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

        enrollment =
          %Enrollment{}
          |> Enrollment.changeset(%{
            student_id: student.id,
            course_id: course_id,
            status: status
          })
          |> Repo.insert!()



        {student, enrollment}
    end
  end)
  end


  def deregister_student(student_id, course_id) do
  enrollment = Repo.get_by(Enrollment, student_id: student_id, course_id: course_id)

  case enrollment do
    nil ->
      {:error, :not_found}

    %Enrollment{status: status} when status in [:waitlisted, "waitlisted"] ->
      Repo.delete(enrollment)

    %Enrollment{status: status} when status in [:active, "active"] ->
      changeset = StudentLive.Workers.ProcessWaitlistWorker.new(%{"course_id" => course_id})

      Ecto.Multi.new()
      |> Ecto.Multi.delete(:delete_enrollment, enrollment)

      |> Oban.insert(:enqueue_waitlist_worker, changeset)
      |> Repo.transaction()

    other ->
      {:error, {:unexpected_state, other}}
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



  def get_course_status(%Course{} = course) do
  today = Date.utc_today()

  cond do
    course.start_date &&
        Date.compare(today, course.start_date) in [:eq, :gt] ->
      "Started"

    course.current_enrollment_count >= course.maximum_capacity ->
      "Full"

    true ->
      "Open"
  end
end

  def get_enrollment_status(student_id, course_id) when is_integer(student_id) and is_integer(course_id) do
  case Repo.get_by(Enrollment, student_id: student_id, course_id: course_id) do
    nil -> nil
    %Enrollment{status: status} -> status
  end
  end

  def get_assignment!(id), do: Repo.get!(Assignment, id)
end
