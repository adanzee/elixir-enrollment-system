defmodule StudentLiveWeb.LoginPage do
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


  describe "Login Page" do

    test "logs in with valid credentials and navigates to dashboard", %{conn: conn} do
      password = "Password123!"
      student = create_student(password)

      {:ok, view, _html} = live(conn, "/login")

      view
      |> form("#login-form", student: %{
        email: student.email,
        password: password
      })
      |> render_submit()

      assert_redirect(view, "/dashboard")
    end

    test "user does not exist error for invalid email", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/login")

      html =
        view
        |> form("#login-form", student: %{
          email: Faker.Internet.email(),
          password: "Password123!"
        })
        |> render_submit()

      assert html =~ "User doesn't exist"
      assert html =~ "Login"
    end

    test "invalid credentials error for incorrect password", %{conn: conn} do
      student = create_student()

      {:ok, view, _html} = live(conn, "/login")

      html =
        view
        |> form("#login-form", student: %{
          email: student.email,
          password: "WrongPassword123!"
        })
        |> render_submit()

      assert html =~ "Invalid credentials"
      assert html =~ "Login"
    end

  end
end
