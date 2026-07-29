defmodule StudentLiveWeb.CourseLive.Access do
  use StudentLiveWeb, :live_view
  alias StudentLive.Academic
  alias StudentLive.Accounts
  alias StudentLive.Schemas.{Course, Enrollment, Assignment, Submission, Student}

  @impl true
  def mount(%{"course_id" => course_id}, _session, socket) do
    course = Academic.get_course!(course_id)

    {:ok,
     socket
     |> assign(:course, course)
     |> assign(:form, to_form(%{"email" => "", "name" => ""}))}
  end

  @impl true
  def handle_event("authenticate_student", %{"email" => email, "name" => name}, socket) do
    course = socket.assigns.course
    email = String.trim(email || "")
    name = String.trim(name || "")

    result =
      case Accounts.get_or_create_student(email, name) do
        {:ok, student} ->
          case Academic.enroll_student(student.email, course.id) do
            {:ok, _enrollment} -> {:ok, student}
            {:error, "Student is already enrolled in this course."} -> {:ok, student}
            {:error, reason} -> {:error, reason}
          end

        {:error, _changeset} ->
          {:error, "Invalid student data provided."}
      end

    case result do
      {:ok, student} ->
        {:noreply,
         socket
         |> Plug.Conn.put_session(:student_id, student.id)
         |> Plug.Conn.put_session(:student_email, student.email)
         |> put_flash(:info, "Welcome back, #{student.name}!")
         |> push_navigate(to: ~p"/courses/#{course.id}/outline")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto mt-20 p-8 bg-white border rounded-xl shadow-sm space-y-6">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Student Access</h1>
        <p class="text-sm text-gray-500 mt-1">Course: <span class="font-medium text-gray-800"><%= @course.title %></span></p>
      </div>

      <.form for={@form} phx-submit="authenticate_student" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700">Email Address</label>
          <input
            type="email"
            name="email"
            required
            placeholder="student@university.edu"
            class="mt-1 block w-full rounded-md text-gray-900 border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700">Full Name (Required if new student)</label>
          <input
            type="text"
            name="name"
            placeholder="Jane Doe"
            class="mt-1 block w-full text-gray-900 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          />
        </div>

        <button
          type="submit"
          class="w-full py-2 px-4 bg-indigo-600 hover:bg-indigo-700 text-white font-medium rounded-md shadow-sm text-sm"
        >
          Continue to Course Outline
        </button>
      </.form>
    </div>
    """
  end
end
