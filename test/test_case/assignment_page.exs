defmodule StudentLiveWeb.AssignmentPage do
  use StudentLiveWeb.ConnCase, async: true
  decribe "assignment page" do
    test "submit assignment button navigates to assignment page", %{conn: conn} do
    student = create_student()
    course = create_course()
    assignment = create_assignment(course)

    enroll_student(student.id, course.id)

    conn = log_in_student(conn, student)

    {:ok, view, _html} = live(conn, "/courses/#{course.id}")

    view
    |> element("#submit-assignment-#{assignment.id}")
    |> render_click()

    assert_redirect(view, "/assignments/#{assignment.id}")

    end

  test "shows error when assignment does not exist", %{conn: conn} do
    student = create_student()
    course = create_course()

    enroll_student(student.id, course.id)

    conn = log_in_student(conn, student)

    {:ok, _view, html} = live(conn, "/assignments/#{assignment.id}")

    assert html =~ "Assignment not found"
  end

  test "student can submit an existing assignment", %{conn: conn} do
    student = create_student()
    course = create_course()
    assignment = create_assignment(course)

    enroll_student(student.id, course.id)

    conn = log_in_student(conn, student)

    {:ok, view, _html} = live(conn, "/assignments/#{assignment.id}")

    html =
      view
      |> form("#assignment-form", submission: %{
        content: "Choose your assignment file and submit it."
      })
      |> render_submit()

    assert html =~ "Upload Assignment"
    assert html =~ "Submission History"
  end
end
end
