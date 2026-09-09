defmodule StudentLiveWeb.Test.SigninLiveTest do
  use StudentLiveWeb.ConnCase, async: true

  describe "registration page" do
    test "submitting the registration form navigates to login", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/register")

      params = %{
        "student" => %{
          "email" => Faker.Internet.email(),
          "password" => "password123",
          "name" => Faker.Person.name(),
          "contact" => Faker.Phone.EnUs.phone()
        }
      }

      render_submit(view, "register", params)

      assert_redirect(view, "/login")
    end

  end
end
