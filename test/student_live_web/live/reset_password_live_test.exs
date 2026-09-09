defmodule StudentLiveWeb.ResetPasswordLiveTest do
  use StudentLiveWeb.ConnCase, async: true

    alias StudentLive.Accounts

  defp create_student(password \\ "Password123!") do
    attrs = %{
      name: Faker.Person.name(),
      email: Faker.Internet.email(),
      password: password,
      contact: Faker.Phone.EnUs.phone()
    }

    {:ok, student} = Accounts.create_student(attrs)

    student
  end

  defp create_course() do
     course = %Course{
    title: Faker.Lorem.sentence(),
    description: Faker.Lorem.paragraph(),
    outline_pdf_path: "/uploads/#{Faker.File.file_name()}",
    start_date: Date.add(Date.utc_today(), 3),
    end_date: Date.add(Date.utc_today(), 33),
    maximum_capacity: Faker.Random.random_between(1, 10)
    }

    {:ok, course} = Accounts.create_course(course)

    course
  end

  describe "Forgot Password" do

  test "forgot password link navigates to forgot password page", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/login")

    view
    |> element("a", "Forgot Password?")
    |> render_click()

    assert_redirect(view, "/forgot-password")
  end

  test "renders forgot password page", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/forgot-password")

    assert html =~ "Forgot Password"
    assert html =~ "Email"
  end

  #@USER user = %{
   # name: Faker.Person.name(),
    #email: Faker.Internet.email(),
    #password: "Password123!",
  #}
  test "accepts reset request for an existing student email", %{conn: conn} do
  student = create_student()

  {:ok, view, _html} = live(conn, "/forgot-password")

  html =
    view
    |> form("#forgot-password-form", student: %{
      email: student.email
    })
    |> render_submit()

  assert html =~ "reset"
end

test "shows error when student email does not exist", %{conn: conn} do
  {:ok, view, _html} = live(conn, "/forgot-password")

  html =
    view
    |> form("#forgot-password-form", student: %{
      email: Faker.Internet.email()
    })
    |> render_submit()

  assert html =~ "User doesn't exist"
end
end
end
