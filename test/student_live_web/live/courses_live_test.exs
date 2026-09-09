defmodule StudentLiveWeb.CoursesLiveTest do
  use StudentLiveWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias StudentLive.Courses
  alias StudentLive.StudentFixtures
  alias StudentLive.CourseFixtures
  alias StudentLive.Repo
  alias StudentLive.Schemas.Enrollment

  describe "Courses Page" do
    test "shows view details and unenroll options for enrolled course", %{conn: conn} do
      student = StudentFixtures.student_fixture()
      course = CourseFixtures.course_fixture()

      Courses.enroll_student_in_course(student, course.id)

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session(:student_id, student.id)

      {:ok, view, _html} = live(conn, "/dashboard")

      view
      |> element("[phx-click='toggle_courses']")
      |> render_click()

      html = render(view)

      assert html =~ course.title
      assert html =~ "View Details"
      assert html =~ "Unenroll"
    end

test "clicking unenroll removes student from course", %{conn: conn} do
  student = StudentFixtures.student_fixture()
  course = CourseFixtures.course_fixture()

 {:ok, enrollment} = Courses.enroll_student_in_course(student, course.id)

  conn =
    conn
    |> Plug.Test.init_test_session(%{})
    |> Plug.Conn.put_session(:student_id, student.id)

  {:ok, view, _html} = live(conn, "/dashboard")

  view
  |> element("[phx-click='toggle_courses']")
  |> render_click()

  view
  |> element(
    "button[phx-click='unenroll'][phx-value-course-id='#{course.id}']"
  )
  |> render_click()

  assert Repo.get(Enrollment, enrollment.id) == nil
end


    test "view details navigates to course page", %{conn: conn} do
      student = StudentFixtures.student_fixture()
      course = CourseFixtures.course_fixture()

      Courses.enroll_student_in_course(student, course.id)

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session(:student_id, student.id)

      {:ok, view, _html} = live(conn, "/dashboard")

      view
      |> element("[phx-click='toggle_courses']")
      |> render_click()

      view
      |> element("a[href^='/courses/#{course.id}?email=']")
      |> render_click()

    assert_redirect(
  view,
  "/courses/#{course.id}?email=#{URI.encode_www_form(student.email)}"
)
    end
  end
end
