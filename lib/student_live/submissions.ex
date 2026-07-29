defmodule StudentLive.Submissions do
  import Ecto.Query
  alias StudentLive.Repo
  alias StudentLive.Schemas.Submission
  alias StudentLive.Courses

  def count_submissions(student_id, assignment_id) do
    Repo.aggregate(
      from(s in Submission, where: s.student_id == ^student_id and s.assignment_id == ^assignment_id),
      :count
    )
  end

  def list_submissions_for_student(student_id, assignment_id) do
    from(s in Submission,
      where: s.student_id == ^student_id and s.assignment_id == ^assignment_id,
      order_by: [desc: s.inserted_at]
    )
    |> Repo.all()
  end

  def create_submission(student, assignment, file_attrs) do
    count = count_submissions(student.id, assignment.id)

    cond do
      not Courses.enrolled?(student, assignment.course_id) ->
        {:error, "Student is not enrolled in this course"}

      count >= assignment.maximum_submissions_per_student ->
        {:error, "Submission limit reached (#{assignment.maximum_submissions_per_student} max)"}

      true ->
        %Submission{}
        |> Submission.changeset(Map.merge(file_attrs, %{
          "student_id" => student.id,
          "assignment_id" => assignment.id
        }))
        |> Repo.insert()
    end
  end
end
