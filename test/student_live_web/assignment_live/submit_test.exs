defmodule StudentLiveWeb.AssignmentLive.SubmitTest do
  use StudentLiveWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias StudentLive.Repo
  alias StudentLive.Schemas.{Assignment, Course, Enrollment, Student}

  test "renders the upload page for an enrolled student" do
    student = insert_student("student@example.com", "Student")
    course = insert_course()
    assignment = insert_assignment(course.id)

    Repo.insert!(%Enrollment{student_id: student.id, course_id: course.id})

    {:ok, view, _html} =
      live_isolated(conn(), StudentLiveWeb.AssignmentLive.Submit,
        session: %{"student_id" => student.id},
        params: %{"course_id" => course.id, "assignment_id" => assignment.id}
      )

    assert has_element?(view, "#submissions-list-container")
    assert has_element?(view, "#submission-form")
  end

  defp insert_student(email, name) do
    %Student{}
    |> Student.changeset(%{email: email, name: name})
    |> Repo.insert!()
  end

  defp insert_course do
    attrs = %{
      title: "Advanced Elixir",
      description: "Security review",
      start_date: ~D[2026-01-01],
      end_date: ~D[2026-12-31],
      capacity: 10
    }

    %Course{}
    |> Course.changeset(attrs)
    |> Repo.insert!()
  end

  defp insert_assignment(course_id) do
    attrs = %{
      title: "Capstone",
      description: "Upload your work",
      due_date: ~U[2026-12-31 00:00:00Z],
      course_id: course_id,
      max_submissions: 2
    }

    %Assignment{}
    |> Assignment.changeset(attrs)
    |> Repo.insert!()
  end
end
