defmodule StudentLiveWeb.CourseLive.Show do
  use StudentLiveWeb, :live_view
  alias StudentLive.{Courses, Accounts, Submissions}
  alias StudentLive.Schemas.{Student, Course}

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    IO.inspect(params, label: ">>> COURSE SHOW MOUNT PARAMS")

    course_id = String.to_integer(id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(StudentLive.PubSub, "course:#{id}")
    end

    course = Courses.get_course_with_assignments!(course_id)
    email = params["email"] || ""

    IO.inspect(email, label: ">>> MOUNT EMAIL EXTRACTED")

    socket =
      socket
      |> assign(:course, course)
      |> assign(:course_status, Courses.get_course_status(course))
      |> assign(:pdf_url, static_pdf_path(course.outline_pdf_path))
      |> assign(:email, email)
      |> assign(:student, nil)
      |> assign(:is_enrolled, false)
      |> assign(:submissions_by_assignment, %{})
      |> assign(:registration_needed, false)

      if email != "" do
        {:ok, load_student_by_email(socket, email, course_id)}
      else
      {:ok, socket}
    end
  end


  @impl true
  def handle_info({:waitlist_promoted, student_id}, socket) do
    current_student = socket.assigns.student

    socket =
      if current_student && current_student.id == student_id do
        put_flash(socket, :info, "🎉 You have been promoted from the waitlist to active enrollment!")
      else
        socket
      end

    {:noreply, reload_course(socket)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    email = params["email"] || socket.assigns.email || ""
    course_id = socket.assigns.course.id

    if email != "" do
      {:noreply, load_student_by_email(socket, email, course_id)}
    else
      {:noreply, socket}
    end
  end


  @impl true
  def handle_event("lookup_email", %{"email" => email}, socket) do
    course_id = socket.assigns.course.id

    case Accounts.get_student_by_email(email) do
      nil ->
        {:noreply,
         socket
         |> assign(:email, email)
         |> assign(:student, nil)
         |> assign(:is_enrolled, false)
         |> assign(:registration_needed, true)}

      %Student{} = student ->
        status = Courses.get_enrollment_status(student.id, course_id)
        is_enrolled = status in [:active, "active"]
        submissions = load_student_submissions(student.id, socket.assigns.course.assignments)

        {:noreply,
         socket
         |> assign(:email, email)
         |> assign(:student, student)
         |> assign(:is_enrolled, is_enrolled)
         |> assign(:submissions_by_assignment, submissions)
         |> assign(:registration_needed, not is_enrolled)}
    end
  end

  @impl true
  def handle_event("register_and_enroll", params, socket) do
    course_id = socket.assigns.course.id

    case Courses.register_and_enroll(params, course_id) do
      {:ok, {student, enrollment}} ->
        updated_course = Courses.get_course_with_assignments!(course_id)
        is_active = enrollment.status in [:active, "active"]

        msg =
          if is_active do
            "Successfully registered and enrolled in the course!"
          else
            "Course is full. You have been added to the waitlist."
          end

        submissions = load_student_submissions(student.id, updated_course.assignments)

        {:noreply,
         socket
         |> assign(:course, updated_course)
         |> assign(:course_status, Courses.get_course_status(updated_course))
         |> assign(:student, student)
         |> assign(:is_enrolled, is_active)
         |> assign(:submissions_by_assignment, submissions)
         |> assign(:registration_needed, false)
         |> put_flash(:info, msg)}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not complete registration.")}
    end
  end

  @impl true
  def handle_event("deregister", _params, socket) do
    student_id = socket.assigns.student.id
    course_id = socket.assigns.course.id

    case Courses.deregister_student(student_id, course_id) do
      {:ok, _} ->
        updated_course = Courses.get_course_with_assignments!(course_id)

        {:noreply,
         socket
         |> assign(:course, updated_course)
         |> assign(:course_status, Courses.get_course_status(updated_course))
         |> assign(:is_enrolled, false)
         |> assign(:submissions_by_assignment, %{})
         |> put_flash(:info, "Successfully deregistered from course.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to deregister.")}
    end
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :registration_needed, false)}
  end

  #  Private Helpers

  defp load_student_by_email(socket, email, course_id) do
    IO.inspect(email, label: ">>> LOOKING UP STUDENT BY EMAIL")

    case Accounts.get_student_by_email(email) do
      %Student{} = student ->
        IO.inspect(student, label: ">>> FOUND STUDENT STRUCT")
        status = Courses.get_enrollment_status(student.id, course_id)
        IO.inspect(status, label: ">>> ENROLLMENT STATUS IN DB")

        is_enrolled = status in [:active, "active"]
        submissions = load_student_submissions(student.id, socket.assigns.course.assignments)

        socket
        |> assign(:student, student)
        |> assign(:email, email)
        |> assign(:is_enrolled, is_enrolled)
        |> assign(:submissions_by_assignment, submissions)

      nil ->
        IO.inspect(email, label: ">>> STUDENT LOOKUP RETURNED NIL!")
        socket
    end
  end

  defp reload_course(socket) do
    course_id = socket.assigns.course_id
    student = socket.assigns.student

    course = Courses.get_course_with_assignments!(course_id)
    enrollment_status = Courses.get_enrollment_status(student.id, course_id)

    socket
    |> assign(:course, course)
    |> assign(:enrollment_status, enrollment_status)
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
      <.link navigate={~p"/"} class="text-white-600 hover:underline text-sm mb-4 inline-block font-medium">&larr; Back to Courses</.link>


      <div class="bg-white p-6 rounded-lg shadow-sm border mb-8">
        <div class="flex justify-between items-center mb-2">
          <h1 class="text-3xl text-gray-900 font-bold"><%= @course.title %></h1>
          <span class="text-sm font-semibold px-3 py-1 rounded bg-gray-100 text-gray-800">
            Status: <%= @course_status %>
          </span>
        </div>
        <p class="text-gray-600 mb-4"><%= @course.description %></p>

        <p class="text-sm text-gray-500">
          <strong>Capacity:</strong> <%= @course.current_enrollment_count %> / <%= @course.maximum_capacity %>
          <span class="ml-2 font-medium text-green-600">
            (<%= max(0, @course.maximum_capacity - @course.current_enrollment_count) %> seats available)
          </span>
        </p>
      </div>


      <div class="bg-stone-50 p-6 rounded-lg border mb-8">
        <h2 class="text-lg text-gray-700 font-semibold mb-4">Student Access Verification</h2>

        <form phx-submit="lookup_email" class="mb-4">
          <label class="block text-sm font-medium text-gray-700 mb-1">Enter your email address</label>
          <div class="flex gap-2">
            <input type="email" name="email" value={@email} required placeholder="student@example.com" class="border text-gray-900 border-solid border-gray-400 rounded p-2 flex-grow text-sm" />
            <button type="submit" class="bg-blue-600 text-white text-sm px-4 py-2 rounded hover:bg-blue-700">Verify Email</button>
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
              <h3 class="text-lg font-bold text-gray-900">
                <%= case @course_status do %>
                  <% "Full" -> %> Join Course Waitlist
                  <% "Open" -> %> Student Course Registration
                  <% status -> %> Registration <%= status %>
                <% end %>
              </h3>
              <button phx-click="close_modal" type="button" class="text-gray-400 hover:text-gray-600 text-lg font-bold">&times;</button>
            </div>

            <%= case @course_status do %>
              <% status when status in ["Closed", "Started"] -> %>
                <div class="p-4 bg-red-50 border border-red-200 text-red-800 rounded text-sm mb-4">
                  Cannot register. Course is currently <strong><%= status %></strong>.
                </div>
                <div class="flex justify-end">
                  <button type="button" phx-click="close_modal" class="px-4 py-2 text-sm border rounded text-gray-700 hover:bg-gray-100">Close</button>
                </div>

              <% "Full" -> %>
                <div class="p-3 bg-amber-50 border border-amber-200 text-amber-800 rounded text-sm mb-4">
                  Course capacity is <strong>Full</strong>. Submitting your details will add you to the <strong>waitlist</strong>.
                </div>

                <form phx-submit="register_and_enroll" class="space-y-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Full Name</label>
                    <input type="text" name="name" value={if @student, do: @student.name, else: ""} required placeholder="Enter your full name" class="w-full text-gray-900 border border-gray-300 rounded p-2 text-sm" />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Email Address</label>
                    <input type="email" name="email" value={@email} required readonly class="w-full border border-gray-300 rounded p-2 text-sm bg-gray-100 text-gray-600" />
                  </div>
                  <div class="flex justify-end gap-2 pt-2">
                    <button type="button" phx-click="close_modal" class="px-4 py-2 text-sm border rounded text-gray-700 hover:bg-gray-100">Cancel</button>
                    <button type="submit" class="px-4 py-2 text-sm bg-green-600 text-white rounded hover:bg-green-700">Join Waitlist</button>
                  </div>
                </form>

              <% "Open" -> %>
                <p class="text-sm text-gray-600 mb-4">Enter your details below to register and enroll in this course.</p>
                <form phx-submit="register_and_enroll" class="space-y-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Full Name</label>
                    <input type="text" name="name" value={if @student, do: @student.name, else: ""} required placeholder="Enter your full name" class="w-full text-gray-900 border border-gray-300 rounded p-2 text-sm" />
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


      <%= if @student && @is_enrolled do %>

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

                  <.link navigate={~p"/assignments/#{assignment.id}?email=#{@student.email}"} class="bg-teal-600 text-white text-sm px-4 py-2 rounded hover:bg-teal-700">
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
