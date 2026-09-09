defmodule StudentLiveWeb.Test.SigninLiveTest do
  use StudentLiveWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "registration page" do
    test "submitting the registration form navigates to login", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/register")

      password = "Password123!"

      params = %{
        "student" => %{
          "name" => Faker.Person.name(),
          "email" => Faker.Internet.email(),
          "password" => password,
          "confirm_password" => password,
        }
      }

      view
      |> form("#registration-form", params)
      |> render_submit()

      assert_redirect(view, "/login")
    end
  end
end
