defmodule StudentLiveWeb.CourseLive.Show do
  use StudentLiveWeb, :live_view
  alias StudentLive.{Courses, Accounts, Submissions}


  @impl true
  def mount(%{"id" => id}, _session, socket) do
    course = Courses.get_course_with_assignments!(id)

    {:ok,
     socket
     |> assign(:course, course)
     |> assign(:course_status, Courses.get_course_status(course))
     |> assign(:pdf_url, static_pdf_path(course.outline_pdf_path))
     |> assign(:email, "")
     |> assign(:student, nil)
     |> assign(:is_enrolled, false)
     |> assign(:submissions_by_assignment, %{})
     |> assign(:registration_needed, false)}
  end


  @impl true
  def handle_event("lookup_email", %{"email" => email}, socket) do
    email = String.trim(email)
    course = socket.assigns.course

    case Accounts.get_student_by_email(email) do
      nil ->

        {:noreply,
         socket
         |> assign(:email, email)
         |> assign(:student, nil)
         |> assign(:is_enrolled, false)
         |> assign(:registration_needed, true)}

      student ->
        is_enrolled = Courses.enrolled?(student.id, course.id)

        if is_enrolled do

          submissions_map = load_student_submissions(student.id, course.assignments)

          {:noreply,
           socket
           |> assign(:email, email)
           |> assign(:student, student)
           |> assign(:is_enrolled, true)
           |> assign(:submissions_by_assignment, submissions_map)
           |> assign(:registration_needed, false)}
        else

          {:noreply,
           socket
           |> assign(:email, email)
           |> assign(:student, student)
           |> assign(:is_enrolled, false)
           |> assign(:registration_needed, true)}
        end
    end
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :registration_needed, false)}
  end


  @impl true
  def handle_event("register_and_enroll", %{"name" => name, "email" => email}, socket) do
    if socket.assigns.course_status == "Open" do
      student_params = %{"name" => String.trim(name), "email" => String.trim(email)}

      case Accounts.find_or_create_student(student_params) do
        {:ok, student} ->
          perform_enrollment(socket, student)

        {:error, changeset} ->
          error_msg = Enum.map_join(changeset.errors, ", ", fn {k, {v, _}} -> "#{k} #{v}" end)
          {:noreply, put_flash(socket, :error, "Registration failed: #{error_msg}")}
      end
    else
      {:noreply, put_flash(socket, :error, "Cannot enroll. Course status is currently #{socket.assigns.course_status}.")}
    end
  end


  @impl true
  def handle_event("deregister", _params, socket) do
    student = socket.assigns.student
    course = socket.assigns.course

    case Courses.deregister_student(student.id, course.id) do
      {:ok, _} ->

        updated_course = Courses.get_course_with_assignments!(course.id)
        updated_status = Courses.get_course_status(updated_course)

        {:noreply,
         socket
         |> assign(:course, updated_course)
         |> assign(:course_status, updated_status)
         |> assign(:is_enrolled, false)
         |> assign(:submissions_by_assignment, %{})
         |> put_flash(:info, "Successfully deregistered. A seat has been freed up.")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  defp perform_enrollment(socket, student) do
    case Courses.enroll_student(student.id, socket.assigns.course.id) do
      {:ok, _enrollment} ->
        updated_course = Courses.get_course_with_assignments!(socket.assigns.course.id)
        submissions_map = load_student_submissions(student.id, updated_course.assignments)

        {:noreply,
         socket
         |> assign(:student, student)
         |> assign(:email, student.email)
         |> assign(:course, updated_course)
         |> assign(:course_status, Courses.get_course_status(updated_course))
         |> assign(:pdf_url, static_pdf_path(updated_course.outline_pdf_path))
         |> assign(:is_enrolled, true)
         |> assign(:submissions_by_assignment, submissions_map)
         |> assign(:registration_needed, false)
         |> put_flash(:info, "Successfully enrolled in course.")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  defp load_student_submissions(student_id, assignments) when is_list(assignments) do
    Enum.reduce(assignments, %{}, fn assignment, acc ->
      submissions = Submissions.list_submissions_for_student(student_id, assignment.id)
      Map.put(acc, assignment.id, submissions)
    end)
  end

  defp load_student_submissions(_student_id, _), do: %{}

  defp static_pdf_path(nil), do: nil
  defp static_pdf_path("/" <> _ = path), do: path
  defp static_pdf_path(path) do
    filename = Path.basename(path)
    "/uploads/#{filename}"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto py-8 px-4">
      <.link navigate={~p"/"} class="text-white-600 hover:underline text-sm mb-4 inline-block">&larr; Back to Courses</.link>


      <div class="bg-white p-6 rounded-lg shadow-sm border mb-8">
        <div class="flex justify-between items-center mb-2">
          <h1 class="text-3xl text-black font-bold"><%= @course.title %></h1>
          <span class="text-sm font-semibold px-3 py-1 rounded bg-gray-100 text-gray-800">
            Status: <%= @course_status %>
          </span>
        </div>
        <p class="text-gray-600 mb-4"><%= @course.description %></p>


        <p class="text-sm text-gray-500">
          <strong>Capacity:</strong> <%= @course.current_enrollment_count %> / <%= @course.maximum_capacity %>
          <span class="ml-2 font-medium text-indigo-600">
            (<%= max(0, @course.maximum_capacity - @course.current_enrollment_count) %> seats available)
          </span>
        </p>
      </div>


      <div class="bg-stone-50 p-6 rounded-lg border mb-8">
        <h2 class="text-lg text-gray-700 font-semibold mb-4">Student Access</h2>

        <form phx-submit="lookup_email" class="mb-4">
          <label class="block text-sm font-medium text-gray-700 mb-1">Enter your email address</label>
          <div class="flex gap-2">
            <input type="email" name="email" value={@email} required placeholder="student@example.com" class="border text-gray-900 border-solid border-gray-400 rounded p-2 flex-grow text-sm" />
            <button type="submit" class="bg-indigo-600 text-white text-sm px-4 py-2 rounded hover:bg-indigo-700">Verify Email</button>
          </div>
        </form>


        <%= if @student && @is_enrolled do %>
          <div class="mt-4 p-4 bg-green-50 border border-green-200 rounded flex justify-between items-center text-green-900">
            <span>Enrolled as <strong><%= @student.name %></strong> (<%= @student.email %>)</span>

            <button type="button" phx-click="deregister" class="bg-red-600 text-white text-sm px-4 py-2 rounded hover:bg-red-700">
              Deregister from Course
            </button>
          </div>
        <% end %>
      </div>


      <%= if @registration_needed do %>
        <div class="fixed inset-0 bg-gray-500/75 flex items-center justify-center p-4 z-50">
          <div class="bg-white rounded-lg shadow-xl max-w-md w-full p-6 border">
            <div class="flex justify-between items-center mb-4">
              <h3 class="text-lg font-bold text-gray-900">Student Course Registration</h3>
              <button phx-click="close_modal" type="button" class="text-gray-400 hover:text-gray-600 text-lg font-bold">&times;</button>
            </div>

            <%= if @course_status != "Open" do %>
              <div class="p-4 bg-amber-50 border border-amber-200 text-amber-800 rounded text-sm mb-4">
                Cannot register. Course status is currently <strong><%= @course_status %></strong>.
              </div>
              <div class="flex justify-end">
                <button type="button" phx-click="close_modal" class="px-4 py-2 text-sm border rounded text-gray-700 hover:bg-gray-100">Close</button>
              </div>
            <% else %>
              <p class="text-sm text-gray-600 mb-4">
                Enter your details below to register and enroll in this course.
              </p>

              <form phx-submit="register_and_enroll" class="space-y-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Full Name</label>
                  <input type="text" name="name" value={if @student, do: @student.name, else: ""} required placeholder="Full Name" class="w-full text-gray-900 border border-gray-300 rounded p-2 text-sm" />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Email Address</label>
                  <input type="email" name="email" value={@email} required readonly class="w-full border border-gray-300 rounded p-2 text-sm bg-gray-100 text-gray-600" />
                </div>

                <div class="flex justify-end gap-2 pt-2">
                  <button type="button" phx-click="close_modal" class="px-4 py-2 text-sm border rounded text-gray-700 hover:bg-gray-100">Cancel</button>
                  <button type="submit" class="px-4 py-2 text-sm bg-green-600 text-white rounded hover:bg-green-700">Register & Enroll</button>
                </div>
              </form>
            <% end %>
          </div>
        </div>
      <% end %>


      <%= if @is_enrolled do %>
        <div class="mb-8">
          <h2 class="text-xl font-bold mb-4">Course Outline</h2>
          <%= if @pdf_url do %>
            <iframe src={@pdf_url} class="w-full h-96 border rounded-lg"></iframe>
          <% else %>
            <p class="text-gray-500 italic">No outline PDF available.</p>
          <% end %>
        </div>

        <div>
          <h2 class="text-xl font-bold mb-4">Course Assignments</h2>
          <div class="space-y-4">
            <%= for assignment <- @course.assignments do %>
              <% past_submissions = Map.get(@submissions_by_assignment, assignment.id, []) %>

              <div class="border rounded-lg p-5 bg-white shadow-sm space-y-3">
                <div class="flex justify-between items-start">
                  <div>
                    <h3 class="font-semibold text-lg text-gray-800"><%= assignment.title %></h3>
                    <p class="text-sm text-gray-600"><%= assignment.description %></p>
                  </div>

                  <.link navigate={~p"/assignments/#{assignment.id}?email=#{@student.email}"} class="bg-indigo-600 text-white text-sm px-4 py-2 rounded hover:bg-indigo-700">
                    Submit Assignment &rarr;
                  </.link>
                </div>

                <div class="border-t pt-3">
                  <h4 class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">Past Activity / Submissions</h4>
                  <%= if Enum.empty?(past_submissions) do %>
                    <p class="text-xs text-gray-400 italic">No submissions made yet.</p>
                  <% else %>
                    <ul class="divide-y divide-gray-100">
                      <%= for sub <- past_submissions do %>
                        <li class="py-1 flex justify-between text-xs text-gray-600">
                          <span>📄 <%= sub.file_name %></span>
                          <span>Uploaded on <%= Calendar.strftime(sub.inserted_at, "%b %d, %Y at %H:%M") %></span>
                        </li>
                      <% end %>
                    </ul>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
