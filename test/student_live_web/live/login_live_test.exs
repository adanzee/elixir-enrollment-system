defmodule StudentLiveWeb.LoginLiveTest do
  use StudentLiveWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "Login Page" do

    test "renders login page correctly", %{conn: conn} do
      {:ok, view, html} = live(conn, "/login")

      assert html =~ "Welcome back"
      assert html =~ "Sign in to access your dashboard"

      assert has_element?(view, "#login-form")
      assert has_element?(view, "input[name=email]")
      assert has_element?(view, "#login-password")
      assert has_element?(view, "button[type=submit]", "Sign In")
    end

    test "forgot password link navigates to forgot password page", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/login")

      view
      |> element(~s(a[href="/forgot-password"]))
      |> render_click()

      assert_redirect(view, "/forgot-password")
    end

    test "create account link navigates to registration page", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/login")

      view
      |> element(~s(a[href="/register"]))
      |> render_click()

      assert_redirect(view, "/register")
    end

    test "password visibility toggle elements exist", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/login")

      assert has_element?(view, "#login-password")
      assert has_element?(view, "#login-password-show")
      assert has_element?(view, "#login-password-hide")
    end

  end
end
