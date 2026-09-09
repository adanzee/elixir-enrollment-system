defmodule StudentLiveWeb.ResetPasswordLiveTest do
  use StudentLiveWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias StudentLive.StudentFixtures
  alias StudentLive.PasswordResetTokenFixtures

  describe "Forgot Password" do
    test "forgot password link navigates to forgot password page", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/login")

      view
      |> element(~s(a[href="/forgot-password"]))
      |> render_click()

      assert_redirect(view, "/forgot-password")
    end

    test "renders forgot password page", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/forgot-password")

      assert html =~ "Forgot Password"
      assert html =~ "Email"
    end

    test "accepts reset request for an existing student email", %{conn: conn} do
      student = StudentFixtures.student_fixture()

      {:ok, view, _html} = live(conn, "/forgot-password")

      html =
        view
        |> form("#forgot-password-form", %{
          email: student.email
        })
        |> render_submit()

      assert html =~ "reset"
    end

    test "shows error when student email does not exist", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/forgot-password")

      html =
        view
        |> form("#forgot-password-form", %{
          email: Faker.Internet.email()
        })
        |> render_submit()

      assert html =~ "No user exists with this email address."
    end
  end

  describe "Reset Password" do
    test "loads reset password page with valid token and resets password", %{conn: conn} do
      student = StudentFixtures.student_fixture()

      %{raw_token: token} =
        PasswordResetTokenFixtures.password_reset_token_fixture(student.id)

      {:ok, view, html} =
        live(conn, "/reset-password?token=#{token}")

      assert html =~ "Reset Password"
      assert has_element?(view, "#reset-password-form")
      assert has_element?(view, "#reset-password")
      assert has_element?(view, "#reset-confirm-password")

      view
      |> form("#reset-password-form", %{
        password: "NewPassword123!",
        confirm_password: "NewPassword123!"
      })
      |> render_submit()

      assert_redirect(view, "/login")
    end

    test "shows error when reset token has already been used", %{conn: conn} do
      student = StudentFixtures.student_fixture()

      %{raw_token: token} =
        PasswordResetTokenFixtures.password_reset_token_fixture(
          student.id,
          %{used_at: DateTime.utc_now()}
        )

      {:ok, view, _html} =
        live(conn, "/reset-password?token=#{token}")

      view
      |> form("#reset-password-form", %{
        password: "AnotherPassword123!",
        confirm_password: "AnotherPassword123!"
      })
      |> render_submit()

      assert render(view) =~ "This password link has been already used."
    end

    test "shows error when reset token has expired", %{conn: conn} do
      student = StudentFixtures.student_fixture()

      %{raw_token: token} =
        PasswordResetTokenFixtures.password_reset_token_fixture(
          student.id,
          %{
            expires_at: DateTime.add(DateTime.utc_now(), -1, :second)
          }
        )

      {:ok, view, _html} =
        live(conn, "/reset-password?token=#{token}")

      view
      |> form("#reset-password-form", %{
        password: "NewPassword123!",
        confirm_password: "NewPassword123!"
      })
      |> render_submit()

      assert render(view) =~ "Reset link has expired"
    end
  end

end
