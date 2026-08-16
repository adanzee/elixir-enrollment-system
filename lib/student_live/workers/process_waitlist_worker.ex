defmodule StudentLive.Workers.ProcessWaitlistWorker do
  use Oban.Worker,
    queue: :enrollments,
    max_attempts: 3,
    unique: [period: 10, fields: [:args, :queue]]

  import Ecto.Query
  alias StudentLive.{Repo, Mailer}
  alias StudentLive.Schemas.{Course, Enrollment}
  alias StudentLive.Emails.StudentEmail

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"course_id" => course_id}}) do
    Repo.transaction(fn ->
      course =
        Course
        |> where(id: ^course_id)
        |> lock("FOR UPDATE")
        |> Repo.one()

      case course do
        nil ->
          :course_not_found

        course ->
          active_count =
            Repo.aggregate(
              from(e in Enrollment, where: e.course_id == ^course.id and e.status == :active),
              :count
            )

          if active_count < course.maximum_capacity do
            promote_next_student(course)
          else
            :course_at_capacity
          end
      end
    end)
    |> case do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end

  defp promote_next_student(course) do
  next_waitlisted =
    Enrollment
    |> where(course_id: ^course.id, status: :waitlisted)
    |> order_by([e], asc: e.inserted_at)
    |> preload(:student)
    |> limit(1)
    |> Repo.one()

  case next_waitlisted do
    %Enrollment{} = enrollment ->
      updated_enrollment =
        enrollment
        |> Enrollment.changeset(%{status: :active})
        |> Repo.update!()

      # Send promotion email using deliver_and_notify
      enrollment.student
      |> StudentEmail.waitlist_promoted(course)
      |> Mailer.deliver_and_notify(enrollment.student_id)

      Phoenix.PubSub.broadcast(
        StudentLive.PubSub,
        "course:#{course.id}",
        {:student_promoted, updated_enrollment.student_id}
      )

      :promoted

    nil ->
      :no_waitlisted_students
  end
end
end
