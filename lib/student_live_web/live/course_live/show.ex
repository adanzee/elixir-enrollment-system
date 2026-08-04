defmodule StudentLiveWeb.CourseLive.Show do
  use StudentLiveWeb, :live_view
  alias StudentLive.{Courses, Accounts}
  alias StudentLive.Schemas.Student

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    course_id = String.to_integer(id)
    course =Courses.get_course_with_assignments!(course_id)
    count = Courses.active_enrollment_count(course_id)
    if connected?(socket) do
        IO.inspect(course_id, label: "SUBSCRIBED TO COURSE")
      Phoenix.PubSub.subscribe(StudentLive.PubSub, "course:#{course_id}")
    end



    socket =
      socket
      |> assign(:course, course)
      |> assign(:active_enrollment_count, count)
      |> assign(:course_status, Courses.get_course_status(course, count))
      |> assign(:pdf_url, static_pdf_path(course.outline_pdf_path))
      |> assign(:email, "")
      |> assign(:student, nil)
      |> assign(:is_enrolled, false)
      |> assign(:registration_needed, false)
      |> assign(:submissions_by_assignment, %{})

    {:ok, socket}
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

        submissions =
          load_student_submissions(
            student.id,
            socket.assigns.course.assignments
          )

        {:noreply,
         socket
         |> assign(:email, email)
         |> assign(:student, student)
         |> assign(:is_enrolled, is_enrolled)
         |> assign(:registration_needed, not is_enrolled)
         |> assign(:submissions_by_assignment, submissions)}
    end
  end


  @impl true
  def handle_event("register_and_enroll", params, socket) do
    course_id = socket.assigns.course.id

    case Courses.register_and_enroll(params, course_id) do
      {:ok, {student, enrollment}} ->

        is_active =
          enrollment.status in [:active, "active"]

        msg =
          if is_active do
            "Successfully registered and enrolled in the course!"
          else
            "Course is full. You have been added to the waitlist."
          end


        socket =
          socket
          |> refresh_course(course_id)


        submissions =
          load_student_submissions(
            student.id,
            socket.assigns.course.assignments
          )


        {:noreply,
         socket
         |> assign(:student, student)
         |> assign(:is_enrolled, is_active)
         |> assign(:submissions_by_assignment, submissions)
         |> assign(:registration_needed, false)
         |> put_flash(:info, msg)}


      {:error, :already_enrolled} ->
        {:noreply,
         put_flash(socket, :error, "You are already enrolled.")}


      {:error, reason} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Registration failed: #{inspect(reason)}"
         )}
    end
  end


  @impl true
  def handle_event("deregister", _params, socket) do
    student_id = socket.assigns.student.id
    course_id = socket.assigns.course.id


    case Courses.deregister_student(student_id, course_id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> refresh_course(course_id)
         |> assign(:is_enrolled, false)
         |> assign(:submissions_by_assignment, %{})
         |> put_flash(:info, "Successfully deregistered from course.")}


      {:error, :course_started} ->
        {:noreply,
         put_flash(socket, :error, "Course already started. Cannot deregister." )}


      {:error, :not_found} ->
        {:noreply, put_flash( socket, :error, "Enrollment not found." )}


      {:error, _} ->
        {:noreply, put_flash( socket, :error, "Failed to deregister." )}
    end
  end


  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     assign(socket, :registration_needed, false)}
  end

  defp load_student_by_email(socket, email, course_id) do
    case Accounts.get_student_by_email(email) do
      %Student{} = student ->
        status =
          Courses.get_enrollment_status(student.id, course_id)
          is_enrolled = status in [:active, "active"]
          submissions =
          load_student_submissions(student.id,
            socket.assigns.course.assignments)
         socket
        |> assign(:student, student)
        |> assign(:email, email)
        |> assign(:is_enrolled, is_enrolled)
        |> assign(:registration_needed, not is_enrolled)
        |> assign(:submissions_by_assignment, submissions)


      nil ->
        socket
        |> assign(:email, email)
        |> assign(:student, nil)
        |> assign(:registration_needed, true)

    end
  end


@impl true
def handle_info({:student_promoted, student_id}, socket) do
  course_id = socket.assigns.course.id
  student = Accounts.get_student!(student_id)

  socket =
    socket
    |> refresh_course(course_id)
    |> put_flash(:info, "#{student.email} has been promoted from the waitlist.")

  {:noreply, socket}
end

  defp refresh_course(socket, course_id) do
    course = Courses.get_course_with_assignments!(course_id)
    count = Courses.active_enrollment_count(course_id)

    socket
    |> assign(:course, course)
    |> assign(:active_enrollment_count, count)
    |> assign(:course_status, Courses.get_course_status(course, count))
  end

  defp load_student_submissions(_student_id, _assignments) do
    %{}
  end

  defp static_pdf_path(nil), do: nil

  defp static_pdf_path("/" <> _ = path), do: path

  defp static_pdf_path(path) do
    filename = Path.basename(path)
    "/uploads/#{filename}"
  end

  defp registration_form(assigns) do
  ~H"""
  <form phx-submit="register_and_enroll" class="space-y-4">

    <div>
      <label class="block text-sm font-medium text-gray-700 mb-1">Full Name</label>
      <input type="text" name="name" value={if @student, do: @student.name, else: ""} required placeholder="Enter your full name"
        class="w-full text-gray-900 border border-gray-300 rounded p-2 text-sm"/>
    </div>
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-1">Email Address</label>
      <input type="email" name="email" value={@email} readonly class="w-full border border-gray-300 rounded p-2 text-sm bg-gray-100 text-gray-600"/>
    </div>
    <div class="flex justify-end gap-2 pt-2">
    <button type="button" phx-click="close_modal" class="px-4 py-2 text-sm border rounded">Cancel</button>
    <button type="submit" class="px-4 py-2 text-sm bg-green-600 text-white rounded">
        <%= if @course_status == "Full" do %>
          Join Waitlist
        <% else %>
          Register & Enroll
        <% end %>
      </button>

    </div>

  </form>
  """
end


@impl true
def render(assigns) do
  ~H"""
  <div class="max-w-5xl mx-auto py-8 px-4">
    <%= for {type, message} <- @flash do %>
      <div class="mb-4 p-4 rounded bg-green-100 text-green-800">
        <%= message %>
      </div>
    <% end %>
    <.link navigate={~p"/"} class="text-white-600 hover:underline text-sm mb-4 inline-block font-medium">&larr; Back to Courses</.link>
    <div class="bg-white p-6 rounded-lg shadow-sm border mb-8">
    <div class="flex justify-between items-center mb-2">
     <h1 class="text-3xl text-gray-900 font-bold"><%= @course.title %></h1>
        <span class="text-sm font-semibold px-3 py-1 rounded bg-gray-100 text-gray-800">Status: <%= @course_status %></span>
    </div>
     <p class="text-gray-600 mb-4"><%= @course.description %> </p>
      <div class="text-sm text-gray-500"><p><strong>Capacity:</strong> <%= @active_enrollment_count %>/<%= @course.maximum_capacity %></p>
        <p><strong>Available Seats:</strong><%= max(0, @course.maximum_capacity - @active_enrollment_count) %></p>
        <p> <strong>Schedule:</strong><%= @course.start_date %>-<%= @course.end_date %></p>
      </div>
    </div>
     <div class="bg-stone-50 p-6 rounded-lg border mb-8">
        <h2 class="text-lg font-semibold text-gray-700 mb-4">Student Access Verification</h2>
          <form phx-submit="lookup_email">
          <div class="flex gap-2"><input type="email" name="email" value={@email} required placeholder="student@example.com" class="border rounded p-2 flex-grow text-gray-900"/>
        <button type="submit" class="bg-blue-600 text-white px-4 py-2 rounded"> Verify Email</button>
      </div>
      </form>
      <%= if @student && @is_enrolled do %>
        <div class="mt-4 p-4 bg-green-50 text-green-900 border border-green-200 rounded flex justify-between items-center">
          <span> Enrolled as:<strong> <%= @student.name %></strong> (<%= @student.email %>)</span>
          <button phx-click="deregister" class="bg-red-600 text-white px-4 py-2 rounded"> Deregister </button>
        </div>
      <% end %>
      </div>
      <%= if @registration_needed do %>
        <div class="fixed inset-0 bg-gray-500/75 flex items-center justify-center z-50">
          <div class="bg-white rounded-lg p-6 w-full max-w-md">
            <div class="flex justify-between mb-4">
              <h2 class="font-bold text-gray-900 text-lg">
              <%= case @course_status do %>
              <% "Open" -> %>Register Course
              <% "Full" -> %> Join Waitlist
              <% status -> %>Registration <%= status %>
          <% end %>
                </h2>
                <button phx-click="close_modal" class="text-gray-500">✕</button>
            </div>
          <%= case @course_status do %>
            <% status when status in ["Closed", "Started"] -> %>
            <div class="bg-red-50 border text-red-800 border-red-200 p-4 rounded">Cannot register.Course is <strong><%= status %></strong>.
          </div>
              <% "Full" -> %>
                <div class="bg-yellow-50 border text-yellow-900 p-3 rounded mb-4">Course is full. You will be added to waitlist.
              </div>
                <.registration_form student={@student} email={@email} course_status={@course_status}/>
                <% "Open" -> %>
                <.registration_form student={@student} email={@email} course_status={@course_status}/>
           <% end %>
           </div>
          </div>
      <% end %>

    <%= if @student && @is_enrolled do %>
      <div class="mb-8">
          <h2 class="text-xl font-bold mb-4">Course Outline</h2>
      <%= if @pdf_url do %>
          <iframe src={@pdf_url} class="w-full h-96 border rounded"></iframe>
      <% else %>
        <p>No outline available.</p>
        <% end %>
      </div>

      <div>
        <h2 class="text-xl font-bold mb-4"> Assignments</h2>
        <%= for assignment <- @course.assignments do %>
        <div class="border bg-white rounded-lg p-5 mb-4">
          <h3 class="font-semibold text-gray-800 text-lg"><%= assignment.title %></h3>
          <p class="text-gray-600"><%= assignment.description %></p>
          <.link navigate={ ~p"/assignments/#{assignment.id}?email=#{@student.email}"} class="inline-block mt-3 bg-teal-600 text-white px-4 py-2 rounded"> Submit Assignment</.link>
        </div>
        <% end %>
      </div>
      <% end %>
    </div>
  """

  end
end
