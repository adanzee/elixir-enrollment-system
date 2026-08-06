defmodule StudentLiveWeb.UserAuth do
  use StudentLiveWeb, :verified_routes

  import Plug.Conn

  alias StudentLive.{Accounts, Academic}


  def log_in_student(conn, student) do
    conn
    |> put_session(:student_id, student.id)
    |> configure_session(renew: true)
    |> Phoenix.Controller.redirect(to: ~p"/dashboard")
  end

def log_out_student(conn) do
    conn
    |> clear_session()
    |> Phoenix.Controller.put_flash(:info, "Logged out successfully.")
    |> Phoenix.Controller.redirect(to: ~p"/login")
  end



  def fetch_current_student(conn, _opts) do
    student_id = get_session(conn, :student_id)

    if student_id do
      student = Accounts.get_student(student_id)
      Plug.Conn.assign(conn, :current_student, student)
    else
      Plug.Conn.assign(conn, :current_student, nil)
    end
  end

  def require_authenticated_student(conn, _opts) do
    if conn.assigns[:current_student] do
      conn
    else
      conn
      |> Phoenix.Controller.put_flash(:error, "You must log in to access this page.")
      |> Phoenix.Controller.redirect(to: ~p"/courses")
      |> halt()
    end
  end

  def redirect_if_authenticated_student(conn, _opts) do
    if conn.assigns[:current_student] do
      conn
      |> Phoenix.Controller.redirect(to: ~p"/courses")
      |> halt()
    else
      conn
    end
  end



  def on_mount(:ensure_authenticated, _params, session, socket) do
    case session["student_id"] do
      nil ->
        {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/login")}

      student_id ->
        case Accounts.get_student(student_id) do
          nil ->
            {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/login")}

          student ->
            {:cont, Phoenix.Component.assign(socket, :current_student, student)}
        end
    end
  end

  def on_mount(:redirect_if_authenticated_student, _params, session, socket) do
    if session["student_id"] do
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/dashboard")}
    else
      {:cont, socket}
    end
  end

  def on_mount(:mount_current_student, _params, session, socket) do
    case session["student_id"] do
      nil ->
        {:cont, Phoenix.Component.assign(socket, :current_student, nil)}

      student_id ->
        student = Accounts.get_student(student_id)
        {:cont, Phoenix.Component.assign(socket, :current_student, student)}
    end
  end
end
