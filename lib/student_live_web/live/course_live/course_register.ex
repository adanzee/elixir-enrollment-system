defmodule StudentLiveWeb.CourseLive.CourseRegister do
  use StudentLiveWeb, :live_view
  alias StudentLive.Courses

  @impl true
  def mount(%{"id" => id}, _session, socket) do
  course_id = String.to_integer(id)
  course = Courses.get_course_with_assignments(course_id)
  count = Courses.active_enrollment_count(course_id)

  current_student = socket.assigns.current_student

  email =
    if current_student do
      current_student.email
    else
      ""

    end

  {:ok,
   socket
   |> assign(:course, course)
   |> assign(:email, email)
   |> assign(:course_id, course_id)
   |> assign(:active_enrollment_count, count)
   |> assign(:course_status, Courses.get_course_status(course, count))
   |> assign(:student, current_student)
   |> assign(:registration_needed, true)}
end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/dashboard")}

  end

  @impl true
  def handle_event("register_and_enroll", _params, socket) do
    student = socket.assigns.current_student
    course_id = socket.assigns.course_id

    case Courses.enroll_student_in_course(student, course_id) do
      {:ok, _enrollment} ->
        {:noreply,
        socket
        |> put_flash(:info, "Successfully enrolled in the course!")
        |> push_navigate(to: ~p"/dashboard")}

      {:error, :already_enrolled} ->
        {:noreply,
        put_flash(socket, :error, "You are already enrolled in this course.")}

      {:error, reason} when is_binary(reason) ->
        {:noreply,
        put_flash(socket, :error, reason)}

      {:error, _reason} ->
        {:noreply,
        put_flash(socket, :error, "Unable to enroll in this course.")}
    end
  end


  @impl true
  def render(assigns) do
    ~H"""
    <%= if @registration_needed do %>
      <div class="fixed inset-0 bg-[#0d1322]/80 backdrop-blur-sm flex items-center justify-center z-50 p-4">
        <div class="bg-[#151c2e] text-slate-100 rounded-xl p-6 w-full max-w-md border border-slate-800 shadow-2xl space-y-4">
          <div class="flex items-center justify-between border-b border-slate-800 pb-3">
            <h2 class="font-bold text-white text-lg tracking-tight">
              <%= case @course_status do %>
                <% "Open" -> %>Register Course
                <% "Full" -> %>Join Waitlist
                <% status -> %>Registration <%= status %>
              <% end %>
            </h2>
            <button
              type="button"
              phx-click="close_modal"
              class="text-slate-400 hover:text-white transition-colors text-xl font-bold leading-none"
            >
              &times;
            </button>
          </div>

          <%= case @course_status do %>
            <% status when status in ["Closed", "Started"] -> %>
              <div class="bg-red-500/10 border border-red-500/30 text-red-400 p-4 rounded-lg text-xs font-medium">
                Cannot register. Course is <strong class="text-red-300"><%= status %></strong>.
              </div>
            <% "Full" -> %>
              <div class="bg-amber-500/10 border border-amber-500/30 text-amber-300 p-3 rounded-lg text-xs font-medium">
                Course is full. You will be added to the waitlist.
              </div>
              <.registration_form student={@student} email={@email} course_status={@course_status} />
            <% "Open" -> %>
              <.registration_form student={@student} email={@email} course_status={@course_status} />
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  defp registration_form(assigns) do
    ~H"""
    <form phx-submit="register_and_enroll" class="space-y-4">
      <div>
        <label class="block text-xs font-semibold text-slate-300 mb-1.5">Full Name</label>
        <input
          type="text"
          name="name"
          value={if @student, do: @student.name, else: ""}
          required
          placeholder="Enter your full name"
          class="w-full bg-[#0d1322] border border-slate-700/80 rounded-lg p-2.5 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-[#00a878] transition-colors"
        />
      </div>
      <div>
        <label class="block text-xs font-semibold text-slate-300 mb-1.5">Email Address</label>
        <input type="email" name="email" value={@email} readonly class="w-full bg-[#0d1322]/60 border border-slate-800 rounded-lg p-2.5 text-xs text-slate-400 cursor-not-allowed"
        />
      </div>
      <div class="flex justify-end gap-3 pt-2">
        <button type="button" phx-click="close_modal" class="px-4 py-2 text-xs font-bold text-slate-300 bg-[#0d1322] hover:bg-slate-800 border border-slate-700/80 rounded-lg transition-colors">
          Cancel
        </button>
        <button type="submit" class="px-4 py-2 text-xs font-bold text-white bg-[#00a878] hover:bg-[#008f66] rounded-lg shadow-md transition-colors">
          <%= if @course_status == "Full", do: "Join Waitlist", else: "Register & Enroll" %>
        </button>
      </div>
    </form>
    """
  end
end
