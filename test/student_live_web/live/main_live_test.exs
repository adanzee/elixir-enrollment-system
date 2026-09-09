defmodule StudentLiveWeb.Test.MainLiveTest do
  use StudentLiveWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias StudentLive.StudentFixtures
  alias StudentLive.CourseFixtures
  alias StudentLiveWeb.UserAuth

  describe "available course page" do
    test "render course information", %{conn: conn} do
      course = CourseFixtures.course_fixture()

      {:ok, _view, html} = live(conn, "/courses")

      assert html =~ course.title
      assert html =~ course.description
      assert html =~ "Register"
    end

    test "logged in user navigate to course registration", %{conn: conn} do
      student = StudentFixtures.student_fixture()
      course = CourseFixtures.course_fixture()


      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session(:student_id, student.id)

     {:ok, _view, html} = live(conn, "/courses")

      assert html =~ "/course/register/#{course.id}"
    end

    test "unauthenticated user navigate to course registration", %{conn: conn} do
      course = CourseFixtures.course_fixture()

      {:ok, _view, html} = live(conn, "/courses")

      assert html =~ ~p"/login"
    end

    test "authenticated user navigate to dashboard", %{conn: conn} do
      student = StudentFixtures.student_fixture()

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session(:student_id, student.id)

      {:ok, _view, html} = live(conn, "/dashboard")

      assert html =~ "Student Overview"
      assert html =~ student.name
      assert html =~ student.email
    end

    test "unauthenticated user navigate to dashboard", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/register"}}} =
               live(conn, "/dashboard")
    end
  end
end
