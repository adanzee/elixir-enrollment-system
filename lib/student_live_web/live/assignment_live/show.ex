defmodule StudentLiveWeb.AssignmentLive.Show do
  use StudentLiveWeb, :live_view

  alias StudentLive.{Courses, Submissions}

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    case Courses.get_assignment(id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Assignment not found.")
         |> push_navigate(to: ~p"/courses/:id")}

      assignment ->
        student = socket.assigns.current_student

        socket =
          socket
          |> assign(:assignment, assignment)
          |> assign(:student, student)
          |> assign(:submissions, [])
          |> assign(:submission_count, 0)
          |> assign(:remaining_attempts, assignment.maximum_submissions_per_student)
          |> allow_upload(:assignment_file,
            accept: ~w(.pdf .docx application/pdf application/vnd.openxmlformats-officedocument.wordprocessingml.document),
            max_entries: 1,
            max_file_size: 10_000_000
          )

        if student do
          status = Courses.get_enrollment_status(student.id, assignment.course_id)
          if status in [:active, "active"] do
            {:ok, refresh_submissions(socket)}
          else
            {:ok, socket
            |> put_flash(:error, "nazr aya kuch👀")
            |> push_navigate(to: ~p"/courses")}
        end

      else
        {:ok, socket
        |> put_flash(:error, "Must logged in ")
        |> push_navigate(to: ~p"/courses") }
      end


    end
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end


  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :assignment_file, ref)}
  end

  @impl true
  def handle_event("save_submission", _params, socket) do
    student = socket.assigns.student
    assignment = socket.assigns.assignment
    cond do
      socket.assigns.remaining_attempts <= 0  ->
        {:noreply, put_flash(socket, :error, "Maximum limit reached ")}

         true ->
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
                  socket = socket
                    |> refresh_submissions()
                    |> put_flash(:info, "Assignment submitted succesfully.")
                  {:noreply, socket}

                {:error, reason} ->
                  reason =
                    if is_struct(reason, Ecto.Changeset) do
                  Enum.map_join(reason.errors, ", ", fn {field, {message, _}} ->
                    "#{field} #{message}"
                  end)
                else
                  to_string(reason)
                end

                {:noreply,
                  put_flash(socket, :error, "Failed to record submission: #{reason}")}
                end


            [] ->
              {:noreply, put_flash(socket, :error, "No valid file selected. Please select a .pdf or .docx file.")}
          end
        end
    end




  defp refresh_submissions(socket) do
  student = socket.assigns.student
  assignment = socket.assigns.assignment

  submissions =
    Submissions.list_submissions_for_student(
      student.id,
      assignment.id
    )

  count = length(submissions)

  max_allowed =
    assignment.maximum_submissions_per_student

  remaining =
    max(0, max_allowed - count)

  socket
  |> assign(:submissions, submissions)
  |> assign(:submission_count, count)
  |> assign(:remaining_attempts, remaining)
end

  @impl true
def render(assigns) do
  ~H"""
  <div class="min-h-screen bg-[#0d1322] text-slate-100 p-6 sm:p-10">
    <div class="mx-auto max-w-4xl space-y-6">

      <div class="flex items-center justify-between">
        <.link
          navigate={~p"/courses/#{@assignment.course_id}"}
          class="text-slate-400 hover:text-white text-xs font-semibold tracking-wide transition-colors"
        >
          &larr; Back to Course Details
        </.link>

        <.link
          navigate={~p"/dashboard"}
          class="bg-[#00a878] hover:bg-[#008f66] text-white text-xs font-bold px-4 py-2 rounded-lg shadow-md transition-colors"
        >
          Go to Dashboard
        </.link>
      </div>

      <div class="bg-[#151c2e] rounded-xl p-6 border border-slate-800 shadow-xl space-y-3">
        <div class="flex flex-col sm:flex-row sm:items-start justify-between gap-4">
          <h1 class="text-2xl font-bold text-white tracking-tight">
            <%= @assignment.title %>
          </h1>

          <span class="inline-flex items-center px-3 py-1 rounded-full text-[11px] font-semibold bg-[#00a878]/10 text-[#00a878] border border-[#00a878]/30 whitespace-nowrap self-start sm:self-auto">
            Allowed Limit: <%= @assignment.maximum_submissions_per_student %> submission(s) max
          </span>
        </div>

        <p class="text-xs text-slate-300 leading-relaxed">
          <%= @assignment.description %>
        </p>
      </div>


      <div class="bg-[#151c2e] rounded-xl p-6 border border-slate-800 shadow-xl space-y-4">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between border-b border-slate-800 pb-4 gap-2">
          <div>
            <h2 class="text-lg font-bold text-white">
              Upload Submission
            </h2>
            <p class="text-xs text-slate-400 mt-0.5">
              Choose your assignment file and submit it.
            </p>
          </div>

          <div class="flex items-center gap-2 text-xs font-medium self-start sm:self-auto">
            <span class="px-3 py-1 rounded bg-[#0d1322] text-slate-300 border border-slate-800">
              Submissions: <strong class="text-[#00a878]"><%= @submission_count %></strong> / <%= @assignment.maximum_submissions_per_student %>
            </span>
          </div>
        </div>

        <%= if @remaining_attempts > 0 do %>
          <form phx-submit="save_submission" phx-change="validate" class="space-y-4" >
            <div class="border border-dashed border-slate-700/80 rounded-xl p-8 bg-[#0d1322]/50 text-center relative flex flex-col items-center justify-center transition-all hover:border-[#00a878]/60" phx-drop-target={@uploads.assignment_file.ref}>
              <svg class="w-8 h-8 text-slate-500 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                  d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"/>
              </svg>

              <div class="flex items-center justify-center gap-2 mb-2">
                <label class="bg-[#00a878] hover:bg-[#008f66] text-white text-xs font-semibold px-3 py-1.5 rounded cursor-pointer transition-colors inline-block">
                  Choose File
                  <.live_file_input upload={@uploads.assignment_file} class="hidden" />
                </label>

                <span class="text-xs text-slate-400">
                  <%= case @uploads.assignment_file.entries do %>
                    <% [entry | _] -> %>
                      <%= entry.client_name %>
                    <% [] -> %>
                      No file chosen
                  <% end %>
                </span>
              </div>

              <p class="text-[11px] text-slate-400">
                 drop your file here. Allowed formats: <strong class="text-slate-300">.pdf, .docx</strong>(Max 10MB)
              </p>
            </div>
            <%= for entry <- @uploads.assignment_file.entries do %>
              <div class="text-xs text-slate-300 bg-[#0d1322] p-3 rounded-lg border border-slate-800 space-y-1">
                <div class="flex justify-between items-center">
                  <span class="truncate font-medium"><%= entry.client_name %></span>
                  <span class="text-[#00a878] font-semibold"><%= entry.progress %>%</span>
                </div>
                <%= for err <- upload_errors(@uploads.assignment_file, entry) do %>
                  <p class="text-red-400 text-[11px] mt-0.5"><%= error_to_string(err) %></p>
                <% end %>
              </div>
            <% end %>

            <div class="flex justify-end gap-3 pt-2">
              <%= if @uploads.assignment_file.entries != [] do %>
                <button type="button" phx-click="cancel-upload" phx-value-ref={hd(@uploads.assignment_file.entries).ref} class="bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-bold px-4 py-2.5 rounded-lg border border-slate-700 transition-colors">
                  Cancel
                </button>
              <% end %>

              <button type="submit" class="bg-[#00a878] hover:bg-[#008f66] text-white text-xs font-bold px-5 py-2.5 rounded-lg transition-colors flex items-center gap-1 shadow-md">
                Submit File &rarr;
              </button>
            </div>
          </form>
        <% else %>
          <div class="p-4 bg-red-500/10 border border-red-500/30 rounded-lg text-red-400 text-xs font-medium flex items-center gap-2">
            <svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
            </svg>
            Maximum submission limit reached for this assignment.
          </div>
        <% end %>
      </div>


      <div class="bg-[#151c2e] rounded-xl p-6 border border-slate-800 shadow-xl space-y-4">
        <h2 class="text-base font-bold text-white">
          Submission History
        </h2>

        <%= if Enum.empty?(@submissions) do %>
          <div class="border border-dashed border-slate-800 rounded-lg p-10 text-center text-xs text-slate-400">
            No submissions recorded yet.
          </div>
        <% else %>
          <div class="divide-y divide-slate-800/80" id="submissions-list">
            <%= for sub <- @submissions do %>
              <div
                id={"submission-#{sub.id}"}
                class="py-3 flex justify-between items-center text-xs first:pt-0 last:pb-0"
              >
                <div class="space-y-0.5">
                  <p class="font-medium text-slate-200 flex items-center gap-2">
                    <svg class="w-4 h-4 text-[#00a878] shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                    </svg>
                    <%= sub.file_name %>
                  </p>

                  <p class="text-[11px] text-slate-400 pl-6">
                    <%= Float.round(sub.file_size / 1024, 2) %> KB
                  </p>
                </div>

                <div class="text-right space-y-1">
                  <span class="inline-flex items-center px-2.5 py-0.5 text-[10px] font-semibold rounded-full bg-[#00a878]/10 text-[#00a878] border border-[#00a878]/30">
                    Submitted
                  </span>

                  <p class="text-[11px] text-slate-400">
                    <%= Calendar.strftime(
                      sub.inserted_at,
                      "%Y-%m-%d %H:%M UTC"
                    ) %>
                  </p>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

    </div>
  </div>
  """
end

  defp error_to_string(:too_large), do: "File exceeds maximum size limit (10MB)."
  defp error_to_string(:not_accepted), do: "Invalid file type. Only .pdf and .docx are allowed."
  defp error_to_string(:too_many_files), do: "You can only upload one file at a time."
end
