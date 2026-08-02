defmodule StudentLiveWeb.AssignmentLive.Show do
  use StudentLiveWeb, :live_view

  alias StudentLive.{Courses, Accounts, Submissions}

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    case Courses.get_assignment(id) do
      nil ->
        {:ok,
        socket
        |> put_flash(:error, "Assignment not found.")
        |> push_navigate(to: ~p"/")}

      assignment ->
        raw_email = params["email"] || ""
        email = URI.decode(raw_email) |> String.trim()

        socket =
          socket
          |> assign(:assignment, assignment)
          |> assign(:student, nil)
          |> assign(:submissions, [])
          |> assign(:submission_count, 0)
          |> assign(:remaining_attempts, assignment.maximum_submissions_per_student)
          |> allow_upload(:assignment_file,
            accept: ~w(.pdf .docx application/pdf application/vnd.openxmlformats-officedocument.wordprocessingml.document),
            max_entries: 1,
            max_file_size: 10_000_000
          )

        if email != "" do
          {:ok, load_student_context(socket, email, assignment)}
        else
          {:ok, socket}
        end
    end
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("load_student", %{"email" => email}, socket) do
    email = String.trim(email)
    assignment = socket.assigns.assignment
    {:noreply, load_student_context(socket, email, assignment)}
  end

  @impl true
  def handle_event("save_submission", _params, socket) do
    student = socket.assigns.student
    assignment = socket.assigns.assignment

    status = if student, do: Courses.get_enrollment_status(student.id, assignment.course_id), else: nil
    is_enrolled = status in [:active, "active"]

    cond do
      is_nil(student) or not is_enrolled ->
        {:noreply, put_flash(socket, :error, "You must be enrolled in this course to submit files.")}

      socket.assigns.remaining_attempts <= 0 ->
        {:noreply, put_flash(socket, :error, "Maximum submission limit reached for this assignment.")}

      true ->
        upload_errors =
          for {_ref, entry} <- socket.assigns.uploads.assignment_file.entries,
              error <- upload_errors(socket.assigns.uploads.assignment_file, entry),
              do: error

        if upload_errors != [] do
          error_msg = Enum.map_join(upload_errors, ", ", &to_string/1)
          {:noreply, put_flash(socket, :error, "Upload error: #{error_msg}")}
        else
          uploaded_files =
            consume_uploaded_entries(socket, :assignment_file, fn %{path: path}, entry ->
              dest_dir = Path.join([File.cwd!(), "priv", "static", "submissions"])
              File.mkdir_p!(dest_dir)

              file_uuid = Ecto.UUID.generate()
              ext = Path.extname(entry.client_name)
              saved_file_name = "#{file_uuid}#{ext}"
              dest_path = Path.join(dest_dir, saved_file_name)

              File.cp!(path, dest_path)

              file_attrs = %{
                "file_name" => entry.client_name,
                "file_path" => "/submissions/#{saved_file_name}",
                "file_size" => entry.client_size
              }

              {:ok, file_attrs}
            end)

          case uploaded_files do
            [file_attrs] ->
              case Submissions.create_submission(student, assignment, file_attrs) do
                {:ok, _submission} ->
                  socket = refresh_submissions(socket)

                  socket =
                    if socket.assigns.remaining_attempts <= 0 do
                      put_flash(socket, :error, "Maximum submission limit reached for this assignment.")
                    else
                      put_flash(socket, :info, "File uploaded successfully.")
                    end

                  {:noreply, socket}

                {:error, reason} ->
                  reason_str =
                    if is_struct(reason, Ecto.Changeset) do
                      Enum.map_join(reason.errors, ", ", fn {k, {v, _}} -> "#{k} #{v}" end)
                    else
                      to_string(reason)
                    end

                  {:noreply, put_flash(socket, :error, "Failed to record submission: #{reason_str}")}
              end

            [] ->
              {:noreply, put_flash(socket, :error, "No valid file selected. Please select a .pdf or .docx file.")}
          end
        end
    end
  end

  # --- Private Helpers ---

  defp load_student_context(socket, email, assignment) do
    case Accounts.get_student_by_email(email) do
      nil ->
        socket
        |> put_flash(:error, "Student record not found.")

      student ->
        status = Courses.get_enrollment_status(student.id, assignment.course_id)

        if status in [:active, "active"] do
          socket
          |> assign(:student, student)
          |> refresh_submissions()
        else
          socket
          |> put_flash(:error, "You are not actively enrolled in this course (Status: #{inspect(status)}).")
        end
    end
  end

  defp refresh_submissions(socket) do
    student = socket.assigns.student
    assignment = socket.assigns.assignment

    submissions = Submissions.list_submissions_for_student(student.id, assignment.id)
    count = length(submissions)
    remaining = max(0, assignment.maximum_submissions_per_student - count)

    socket
    |> assign(:submissions, submissions)
    |> assign(:submission_count, count)
    |> assign(:remaining_attempts, remaining)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto py-8 px-4">
      <.link navigate={~p"/courses/#{@assignment.course_id}"} class="text-white-600 hover:underline text-sm mb-4 inline-block font-medium">
        &larr; Back to Course Details
      </.link>

      <div class="bg-white p-6 rounded-lg shadow-sm border mb-8">
        <h1 class="text-2xl text-gray-800 font-bold mb-2"><%= @assignment.title %></h1>
        <p class="text-gray-600 mb-4"><%= @assignment.description %></p>
        <p class="text-sm text-gray-500">
          <strong>Allowed Limit:</strong> <%= @assignment.maximum_submissions_per_student %> submission(s) max
        </p>
      </div>

      <%= if is_nil(@student) do %>
        <div class="bg-gray-50 p-6 rounded-lg border mb-8">
          <h2 class="text-lg text-gray-900 font-semibold mb-4">Identify Yourself to Submit</h2>
          <form phx-submit="load_student" class="flex gap-2">
            <input
              type="email"
              name="email"
              required
              placeholder="Enter enrolled student email"
              class="border rounded p-2 flex-grow text-sm"
            />
            <button type="submit" class="bg-teal-600 text-white text-sm px-4 py-2 rounded hover:bg-teal-700">
              Access Assignment
            </button>
          </form>
        </div>
      <% else %>
        <div class="bg-white p-6 rounded-lg border mb-8 shadow-sm">
          <h2 class="text-xl text-gray-900 font-bold mb-2">Upload Submission</h2>
          <p class="text-sm text-gray-600 mb-4">
            Logged in as <strong><%= @student.name %></strong> (<%= @student.email %>).<br />
            Submissions made: <strong class="text-blue-600"><%= @submission_count %></strong> |
            Remaining attempts: <strong class="text-blue-600"><%= @remaining_attempts %></strong>
          </p>

          <%= if @remaining_attempts > 0 do %>
            <form phx-submit="save_submission" phx-change="validate" class="space-y-4">
              <div
                class="border-2 border-dashed border-gray-300 text-blue-700 rounded-lg p-6 text-center"
                phx-drop-target={@uploads.assignment_file.ref}
              >
                <.live_file_input upload={@uploads.assignment_file} class="mb-2" />
                <p class="text-xs text-gray-500">Allowed formats: .pdf, .docx (Max 10MB)</p>
              </div>

              <%= for entry <- @uploads.assignment_file.entries do %>
                <div class="text-sm text-gray-700">
                  <span><%= entry.client_name %></span> - <span><%= entry.progress %>%</span>
                  <%= for err <- upload_errors(@uploads.assignment_file, entry) do %>
                    <p class="text-red-500 text-xs"><%= error_to_string(err) %></p>
                  <% end %>
                </div>
              <% end %>

              <div class="flex justify-end">
                <button type="submit" class="bg-green-600 text-white px-4 py-2 rounded text-sm hover:bg-green-700 font-medium">
                  Submit File
                </button>
              </div>
            </form>
          <% else %>
            <div class="p-4 bg-red-50 text-red-700 rounded border border-red-200 text-sm font-semibold">
               Maximum submission limit reached for this assignment.
            </div>
          <% end %>
        </div>

        <%!-- Submission History --%>
        <div class="bg-white p-6 rounded-lg border shadow-sm">
          <h2 class="text-xl text-gray-900 font-bold mb-4">Submission History</h2>

          <%= if Enum.empty?(@submissions) do %>
            <p class="text-gray-500 text-sm italic">No submissions recorded yet.</p>
          <% else %>
            <div class="divide-y" id="submissions-list">
              <%= for sub <- @submissions do %>
                <div id={"submission-#{sub.id}"} class="py-3 flex justify-between items-center text-sm px-2">
                  <div>
                    <p class="font-medium text-gray-800">📄 <%= sub.file_name %></p>
                    <p class="text-xs text-gray-500"><%= Float.round(sub.file_size / 1024, 2) %> KB</p>
                  </div>
                  <div class="text-right">
                    <span class="inline-block px-2 py-0.5 text-xs font-semibold rounded bg-green-100 text-green-800 mb-1">
                      Submitted
                    </span>
                    <p class="text-xs text-gray-500">
                      <%= if sub.inserted_at do %>
                        <%= Calendar.strftime(sub.inserted_at, "%Y-%m-%d %H:%M UTC") %>
                      <% else %>
                        Just now
                      <% end %>
                    </p>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp error_to_string(:too_large), do: "File exceeds maximum size limit (10MB)."
  defp error_to_string(:not_accepted), do: "Invalid file type. Only .pdf and .docx are allowed."
  defp error_to_string(:too_many_files), do: "You can only upload one file at a time."
end
