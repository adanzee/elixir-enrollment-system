defmodule StudentLiveWeb.StudentSessionController do
  use StudentLiveWeb, :controller
  alias StudentLiveWeb.UserAuth


  alias StudentLive.Accounts

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(conn, %{"email" => email, "password" => password}) do
    authenticate(conn, email, password)
  end

  def create(conn, %{"student" => %{"email" => email, "password" => password}}) do
    authenticate(conn, email, password)
  end

  def create(conn, %{"student" => %{"email" => email, "password" => password}}) do
    case Accounts.authenticate_student(email, password) do
      {:ok, student} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> UserAuth.log_in_student(student)

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Invalid email or password.")
        |> redirect(to: ~p"/login")
    end
  end



def register(conn, %{"student" => student_params}) do
  case Accounts.create_student(student_params) do
    {:ok, student} ->
      conn
      |> put_flash(:info, "Account created successfully.")
      |> UserAuth.log_in_student(student)

    {:error, %Ecto.Changeset{} = changeset} ->
      conn
      |> put_flash(:error, "Email is invalid or already taken.")
      |> redirect(to: ~p"/register")
  end
end


  def delete(conn, _params) do
    UserAuth.log_out_student(conn)
  end

  defp authenticate(conn, email, password) do
    case Accounts.authenticate_student(email, password) do
      {:ok, student} ->
        conn
        |> put_flash(:info, "Logged in successfully!")
        |> UserAuth.log_in_student(student)

      {:error, :user_not_found} ->
        conn
        |> put_flash(:error, "User doesn't exist. Please register yourself first.")
        |> redirect(to: ~p"/register")

      {:error, :invalid_password} ->
        conn
        |> put_flash(:error, "Invalid password. Please try again.")
        |> redirect(to: ~p"/login")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid email or password.")
        |> redirect(to: ~p"/login")
    end
  end

end
