defmodule StudentLiveWeb.AssignmentLiveTest do
  use StudentLiveWeb.ConnCase, async: true

 import Phoenix.LiveViewTest
 import Phoenix.LiveViewTest.Upload

  alias StudentLive.Courses
  alias StudentLive.StudentFixtures
  alias StudentLive.CourseFixtures
  alias StudentLive.AssignmentFixtures


  describe "assignment page" do
    test "submit assignment button navigates to assignment page", %{conn: conn} do
    student = StudentFixtures.student_fixture()
    course = CourseFixtures.course_fixture()
    assignment = AssignmentFixtures.assignment_fixture(course.id)

    Courses.enroll_student_in_course(student, course.id)

    conn =
      conn
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_session(:student_id, student.id)

    {:ok, view, _html} = live(conn, "/courses/#{course.id}")

      view
      |> element("a[href='/assignments/#{assignment.id}']")
      |> render_click()

    assert_redirect(view, "/assignments/#{assignment.id}")

    end

  test "shows error when assignment does not exist", %{conn: conn} do
    student = StudentFixtures.student_fixture()
    course = CourseFixtures.course_fixture()

    Courses.enroll_student_in_course(student, course.id)
    conn =
      conn
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_session(:student_id, student.id)

    nonexistent_assignment_id = 999_999

    assert {:error, {:live_redirect, redirect}} = live(conn, "/assignments/#{nonexistent_assignment_id}")

    assert redirect.flash["error"] == "Assignment not found."
    assert redirect.to == "/courses/:id"
  end

  test "student can submit an existing assignment", %{conn: conn} do
    student = StudentFixtures.student_fixture()
    course = CourseFixtures.course_fixture()
    assignment = AssignmentFixtures.assignment_fixture(course.id)

    Courses.enroll_student_in_course(student, course.id)

    conn =
      conn
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_session(:student_id, student.id)

    {:ok, view, _html} = live(conn, "/assignments/#{assignment.id}")

   file_input =
  file_input(view, "form", :assignment_file, [
    %{
      name: "test.pdf",
      content: "test assignment content",
      type: "application/pdf"
    }
  ])

    render_upload(file_input, "test.pdf")

    html =
      view
      |> element("form[phx-submit='save_submission']")
      |> render_submit()

    assert html =~ "Upload Submission"
    assert html =~ "Submission History"
  end
end
end
