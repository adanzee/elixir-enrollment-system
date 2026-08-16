defmodule StudentLiveWeb.DashboardLive do
  use StudentLiveWeb, :live_view

  alias StudentLive.Accounts
  alias StudentLive.Courses

  def mount(_params, session, socket) do
    student = socket.assigns[:current_student] || Accounts.get_student(session["student_id"])

    socket =
      socket
      |> assign(:current_student, student)
      |> assign(:show_courses?, false)
      |> load_enrolled_courses()

    {:ok, socket}
  end

  def handle_event("toggle_courses", _params, socket) do
    {:noreply, update(socket, :show_courses?, &not/1)}
  end

def handle_event("unenroll", %{"course-id" => course_id}, socket) do
  student = socket.assigns.current_student
  course_id = String.to_integer(course_id)

  case Courses.deregister_student(
         student,
         course_id,
         student.email
       ) do
    {:ok, _result} ->
      {:noreply,
       socket
       |> put_flash(:info, "You have been unenrolled successfully.")
       |> load_enrolled_courses()}

    {:error, reason} ->
      {:noreply,
       put_flash(socket, :error, reason)}
  end
end

  defp load_enrolled_courses(socket) do
    student_id = socket.assigns.current_student.id

    enrolled_courses =
      case Courses.list_enrolled_courses_for_student(student_id) do
        %StudentLive.Schemas.Course{} = course -> [course]
        list when is_list(list) -> list
        _ -> []
      end

    today = Date.utc_today()

    processed_courses =
      Enum.map(enrolled_courses, fn course ->
        can_unenroll = Date.compare(course.start_date, today) == :gt
        %{struct: course, can_unenroll?: can_unenroll}
      end)

    socket
    |> assign(:enrolled_courses, processed_courses)
    |> assign(:enrolled_courses_count, length(processed_courses))
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#0d1322] text-slate-100 p-6 sm:p-12">
      <div class="mx-auto max-w-4xl space-y-6">

        <div class="flex flex-col gap-4 rounded-xl border border-slate-800 bg-[#151c2e] p-6 shadow-xl sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h1 class="text-2xl font-bold tracking-tight text-white">
              Student Overview
            </h1>
            <p class="text-xs text-slate-400 mt-1">
              Account status and active enrollment metrics
            </p>
          </div>

          <.link
            href={~p"/logout"}
            method="delete"
            class="inline-flex items-center justify-center rounded-lg bg-[#0d1322] border border-slate-700/80 px-4 py-2 text-xs font-semibold text-slate-300 hover:bg-red-500/10 hover:text-red-400 hover:border-red-500/30 transition-all active:scale-[0.98]"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
            </svg>
            Log Out
          </.link>
        </div>

        <div class="space-y-4">
          <div class="flex items-center justify-between rounded-xl border border-slate-800 bg-[#151c2e] p-5 shadow-xl transition-all hover:border-slate-700">
            <div class="flex items-center space-x-4">
              <div class="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-[#0d1322] text-[#00a878] border border-slate-800">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 012-2h2a2 2 0 012 2v1m-6 0h6" />
                </svg>
              </div>
              <div>
                <span class="block text-[11px] font-bold uppercase tracking-wider text-slate-400">
                  Student ID
                </span>
                <span class="text-xs text-slate-400">
                  Unique Account Reference
                </span>
              </div>
            </div>

            <div class="text-right">
              <span class="inline-flex items-center rounded-lg bg-[#0d1322] border border-slate-800 px-3.5 py-1.5 text-sm font-bold text-slate-200">
                {@current_student.id}
              </span>
            </div>
          </div>

          <div class="flex items-center justify-between rounded-xl border border-slate-800 bg-[#151c2e] p-5 shadow-xl transition-all hover:border-slate-700">
            <div class="flex items-center space-x-4">
              <div class="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-[#0d1322] text-[#00a878] border border-slate-800">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                </svg>
              </div>
              <div>
                <span class="block text-[11px] font-bold uppercase tracking-wider text-slate-400">
                  Student Name
                </span>
                <span class="text-xs text-slate-400">
                  {@current_student.email}
                </span>
              </div>
            </div>

            <div class="text-right">
              <p class="text-base font-bold text-white sm:text-lg">
                {@current_student.name}
              </p>
            </div>
          </div>

          <div class="overflow-hidden rounded-xl border border-slate-800 bg-[#151c2e] shadow-xl transition-all">
            <div
              phx-click="toggle_courses"
              class="flex cursor-pointer items-center justify-between p-5 transition-colors hover:bg-[#1a233a]"
            >
              <div class="flex items-center space-x-4">
                <div class="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-[#00a878] text-white shadow-md">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                  </svg>
                </div>
                <div>
                  <span class="block text-[11px] font-bold uppercase tracking-wider text-[#00a878]">
                    Enrolled Courses
                  </span>
                  <span class="text-xs text-slate-400">
                    Click to view details & manage registrations
                  </span>
                </div>
              </div>

              <div class="flex items-center space-x-3">
                <span class="inline-flex items-center justify-center rounded-lg bg-[#0d1322] border border-slate-800 px-3 py-1 text-sm font-bold text-[#00a878]">
                  {@enrolled_courses_count}
                </span>
                <svg xmlns="http://www.w3.org/2000/svg" class={"h-5 w-5 text-slate-400 transition-transform duration-200 #{if @show_courses?, do: "rotate-180 text-[#00a878]", else: ""}"} fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                </svg>
              </div>
            </div>

            <%= if @show_courses? do %>
              <div class="border-t border-slate-800 bg-[#0d1322]/60 p-4 space-y-3">
                <%= if Enum.empty?(@enrolled_courses) do %>
                  <p class="py-4 text-center text-xs font-medium text-slate-400 border border-dashed border-slate-800 rounded-lg">
                    You are not currently enrolled in any courses.
                  </p>
                <% else %>
                  <%= for item <- @enrolled_courses do %>
                    <div class="flex flex-col gap-3 rounded-lg border border-slate-800 bg-[#151c2e] p-4 shadow-sm sm:flex-row sm:items-center sm:justify-between">
                      <div>
                        <h4 class="text-sm font-bold text-white">
                          {item.struct.title}
                        </h4>
                        <p class="mt-0.5 text-xs text-slate-400">
                          Starts: {item.struct.start_date} | Ends: {item.struct.end_date}
                        </p>
                      </div>

                      <div class="flex items-center space-x-2">
                        <.link navigate={~p"/courses/#{item.struct.id}?email=#{@current_student.email}"} class="rounded-lg bg-[#0d1322] border border-slate-700/80 px-3 py-1.5 text-xs font-semibold text-slate-200 hover:text-white hover:border-slate-600 transition-colors">
                          View Details
                        </.link>

                        <%= if item.can_unenroll? do %>
                          <button phx-click="unenroll" phx-value-course-id={item.struct.id} data-confirm="Are you sure you want to unenroll from this course?" class="rounded-lg bg-red-500/10 border border-red-500/20 px-3 py-1.5 text-xs font-semibold text-red-400 hover:bg-red-500/20 transition-colors">
                            Unenroll
                          </button>
                        <% else %>
                          <span class="rounded-lg bg-[#0d1322] px-3 py-1.5 text-xs font-medium text-slate-500 border border-slate-800" title="Course has already started">
                            Course Started
                          </span>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                <% end %>
              </div>
            <% end %>
          </div>

        </div>

        <div class="flex justify-end pt-2">
          <.link
            navigate={~p"/courses"}
            class="inline-flex items-center gap-2 bg-[#00a878] hover:bg-[#008f66] text-white text-xs font-bold px-4 py-2.5 rounded-lg shadow-md transition-all"
          >
            Explore More Courses &rarr;
          </.link>
        </div>

        <div class="flex justify-end pt-2">
          <.link
            navigate={~p"/mailbox"}
            class="inline-flex items-center gap-2 bg-[#00a878] hover:bg-[#008f66] text-white text-xs font-bold px-4 py-2.5 rounded-lg shadow-md transition-all"
          >
            Check mailbox &rarr;
          </.link>
        </div>

      </div>
    </div>
    """
  end
end
