defmodule StudentLive.Courses do
  import Ecto.Query
  alias StudentLive.{Repo, Mailer}
  alias StudentLive.Schemas.{Course, Assignment, Enrollment}
  alias StudentLive.Schemas.Student
  alias StudentLive.Emails.StudentEmail

  def list_courses do
    Repo.all(Course)
  end

  def get_course!(id), do: Repo.get(Course, id)

  def get_course_with_assignments(id) do
    Course
    |> Repo.get(id)
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



 def register_and_enroll(attrs, course_id) do
  result =
  Repo.transaction(fn ->

    course = lock_course(course_id)

    student =
      case Repo.get_by(Student, email: String.downcase(String.trim(attrs["email"]))) do
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

  case result do
    {:ok, {student, enrollment}} -> {:ok, student, enrollment}
    {:error, reason} -> {:error, reason}
  end
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


def register_student(attrs \\ %{}) do
    %Student{}
    |> Student.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, student} ->
        # Send welcome email and broadcast to this student's mailbox
        student
        |> StudentEmail.student_registered()
        |> Mailer.deliver_and_notify(student.id)

        {:ok, student}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def deregister_student(%Student{} = student, course_id, student_email) do
    course_id = if is_binary(course_id), do: String.to_integer(course_id), else: course_id
    course = Repo.get(Course, course_id)

    enrollment =
      Enrollment
      |> where([e], e.student_id == ^student.id and e.course_id == ^course_id)
      |> Repo.one()

    cond do
      is_nil(course) ->
        {:error, "Course not found"}

      is_nil(enrollment) ->
        {:error, "You are not enrolled in this course"}

      student.email != student_email ->
        {:error, "Email verification failed"}

      true ->
        Repo.transaction(fn ->
          Repo.delete!(enrollment)

          student
          |> StudentEmail.student_deregistered(course)
          |> Mailer.deliver_and_notify(student.id)

          if Code.ensure_loaded?(StudentLive.Workers.ProcessWaitlistWorker) do
            %{course_id: course.id}
            |> StudentLive.Workers.ProcessWaitlistWorker.new()
            |> Oban.insert!()
          end

          :ok
        end)
        |> case do
          {:ok, _result} -> {:ok, :deregistered}
          {:error, reason} -> {:error, reason}
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

  def list_enrolled_courses_for_student(student_id) do
    query =
      from c in Course,
        join: e in Enrollment,
        on: e.course_id == c.id,
        where: e.student_id == ^student_id and e.status == :active,
        select: c

    Repo.all(query)
  end

 def enroll_student_in_course(%Student{} = current_student, course_id) do
  execute_enrollment(current_student.id, course_id)
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


  defp execute_enrollment(student_id, course_id) do
    Repo.transaction(fn ->
      course = lock_course(course_id)
      create_enrollment(student_id, course)
    end)
  end
end
