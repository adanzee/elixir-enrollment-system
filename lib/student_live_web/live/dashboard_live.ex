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

  # Toggle the course list section
  def handle_event("toggle_courses", _params, socket) do
    {:noreply, update(socket, :show_courses?, &not/1)}
  end

  # Handle unenrollment action
  def handle_event("unenroll", %{"course-id" => course_id}, socket) do
    student_id = socket.assigns.current_student.id
    course_id = String.to_integer(course_id)

    case Courses.deregister_student(student_id, course_id) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "Successfully unenrolled from the course.")
          |> load_enrolled_courses()

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to unenroll: #{reason}")}
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
    <div class="min-h-screen bg-slate-50/60 p-4 sm:p-8">
      <div class="mx-auto max-w-3xl space-y-6">


        <div class="flex flex-col gap-4 rounded-3xl border border-slate-100 bg-white p-6 shadow-sm sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h1 class="text-2xl font-black tracking-tight text-slate-900">
              Student Overview
            </h1>
            <p class="text-xs font-medium text-slate-500">
              Account status and active enrollment metrics
            </p>
          </div>


          <.link
            href={~p"/logout"}
            method="delete"
            class="inline-flex items-center justify-center rounded-xl bg-slate-100 px-4 py-2.5 text-xs font-bold text-slate-700 hover:bg-red-50 hover:text-red-600 transition-colors active:scale-[0.98]"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
            </svg>
            Log Out
          </.link>
        </div>

        <div class="space-y-3">
          <div class="flex items-center justify-between rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm transition-all hover:border-slate-300">
            <div class="flex items-center space-x-4">
              <div class="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-slate-100 text-slate-600">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 012-2h2a2 2 0 012 2v1m-6 0h6" />
                </svg>
              </div>
              <div>
                <span class="block text-xs font-bold uppercase tracking-wider text-slate-400">
                  Student ID
                </span>
                <span class="text-sm font-semibold text-slate-500">
                  Unique Account Reference
                </span>
              </div>
            </div>

            <div class="text-right">
              <span class="inline-flex items-center rounded-lg bg-slate-100 px-3 py-1 text-base font-black text-slate-800">
                {@current_student.id}
              </span>
            </div>
          </div>


          <div class="flex items-center justify-between rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm transition-all hover:border-slate-300">
            <div class="flex items-center space-x-4">
              <div class="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-indigo-50 text-indigo-600">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                </svg>
              </div>
              <div>
                <span class="block text-xs font-bold uppercase tracking-wider text-slate-400">
                  Student Name
                </span>
                <span class="text-sm font-semibold text-slate-500">
                  {@current_student.email}
                </span>
              </div>
            </div>

            <div class="text-right">
              <p class="text-base font-extrabold text-slate-900 sm:text-lg">
                {@current_student.name}
              </p>
            </div>
          </div>


          <div class="overflow-hidden rounded-2xl border border-indigo-100 bg-white shadow-sm transition-all">
            <div
              phx-click="toggle_courses"
              class="flex cursor-pointer items-center justify-between bg-gradient-to-r from-indigo-50/50 to-white p-5 transition-colors hover:from-indigo-50/80"
            >
              <div class="flex items-center space-x-4">
                <div class="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-indigo-600 text-white shadow-md shadow-indigo-200">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                  </svg>
                </div>
                <div>
                  <span class="block text-xs font-bold uppercase tracking-wider text-indigo-600">
                    Enrolled Courses
                  </span>
                  <span class="text-sm font-semibold text-slate-500">
                    Click to view details & manage registrations
                  </span>
                </div>
              </div>

              <div class="flex items-center space-x-3">
                <span class="inline-flex items-center justify-center rounded-xl bg-indigo-600 px-4 py-1.5 text-lg font-black text-white shadow-sm">
                  {@enrolled_courses_count}
                </span>
                <svg xmlns="http://www.w3.org/2000/svg" class={"h-5 w-5 text-indigo-600 transition-transform duration-200 #{if @show_courses?, do: "rotate-180", else: ""}"} fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                </svg>
              </div>
            </div>

            <%= if @show_courses? do %>
              <div class="border-t border-indigo-100 bg-slate-50/50 p-4 space-y-3">
                <%= if Enum.empty?(@enrolled_courses) do %>
                  <p class="py-2 text-center text-xs font-medium text-slate-500">
                    You are not currently enrolled in any courses.
                  </p>
                <% else %>
                  <%= for item <- @enrolled_courses do %>
                    <div class="flex flex-col gap-3 rounded-xl border border-slate-200/80 bg-white p-4 shadow-sm sm:flex-row sm:items-center sm:justify-between">
                      <div>
                        <h4 class="text-sm font-bold text-slate-900">
                          {item.struct.title}
                        </h4>
                        <p class="mt-0.5 text-xs font-medium text-slate-500">
                          Starts: {item.struct.start_date} | Ends: {item.struct.end_date}
                        </p>
                      </div>

                      <div class="flex items-center space-x-2">

                          <.link
                            navigate={~p"/courses/#{item.struct.id}?email=#{@current_student.email}"}
                            class="rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-bold text-slate-700 hover:bg-slate-50 transition-colors"
                          >
                            View Details
                          </.link>

                        <%= if item.can_unenroll? do %>
                          <button
                            phx-click="unenroll"
                            phx-value-course-id={item.struct.id}
                            data-confirm="Are you sure you want to unenroll from this course?"
                            class="rounded-lg bg-rose-50 px-3 py-1.5 text-xs font-bold text-rose-600 hover:bg-rose-100 hover:text-rose-700 transition-colors"
                          >
                            Unenroll
                          </button>
                        <% else %>
                          <span class="rounded-lg bg-slate-100 px-3 py-1.5 text-xs font-medium text-slate-400" title="Course has already started">
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
          <div class="flex justify-end">
        <.link navigate={ ~p"/courses"} class="inline-block mb-4 bg-teal-600 text-white px-4 py-2 rounded">
        Explore more Courses</.link>
      </div>

      </div>
    </div>
    """
  end
end
