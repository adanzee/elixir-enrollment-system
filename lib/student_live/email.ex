defmodule StudentLive.Email do

  alias StudentLive.{Repo, Mailer}
  alias StudentLive.Schemas.{Enrollment, Course, Student}
  alias StudentLive.Emails.StudentEmail
  import Ecto.Query

  def enroll_student(%Student{} = student, %Course{} = course) do
    active_count =
        Repo.aggregate(
          from(e in Enrollment,
            where: e.course_id == ^course.id and e.status == :active
          ),
          :count,
          :id
        )

    if active_count < course.maximum_capacity do
      %Enrollment{}
      |> Enrollment.changeset(%{student_id: student.id, course_id: course.id, status: :active})
      |> Repo.insert()
      |> case do
        {:ok, enrollment} ->
          student
          |> StudentEmail.enrollment_confirmed(course)
          |> Mailer.deliver()

          {:ok, :enrolled, enrollment}
          error -> error
      end
        else
          %Enrollment{}
          |> Enrollment.changeset(%{student_id: student.id, course_id: course.id, status: :waitlisted})
          |> Repo.insert()
          |> case do
            {:ok, enrollment} ->
              #sending waitlist email
              student
              |> StudentEmail.waitlist_joined(course)
              |> Mailer.deliver()
              {:ok, :waitlisted, enrollment}

            error -> error
      end
    end
  end

  def deregister_student(enrollment_id) do
    enrollment = Repo.get!(Enrollment, enrollment_id)
    Repo.transaction(fn ->
      Repo.delete!(enrollment)
      #oban worker to promote
      %{course_id: enrollment.course_id}
      |> StudentLive.Workers.ProcessWaitlistWorker.new()
      |> Oban.insert!()

    end)
  end
end
