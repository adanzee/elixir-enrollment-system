defmodule StudentLiveWeb.CourseLive.Index do
  use StudentLiveWeb, :live_view

  alias StudentLive.{Courses, Accounts}

 @impl true
  def mount(_params, session, socket) do

    current_student =
      socket.assigns[:current_student] ||
        (session["student_id"] && Accounts.get_student(session["student_id"]))

    courses =
      Courses.list_courses_with_capacity()
      |> Enum.map(fn course ->
        count = Courses.active_enrollment_count(course.id)
        status = Courses.get_course_status(course, count)
        remaining = max(0, course.maximum_capacity - count)

        %{
          struct: course,
          count: count,
          status: status,
          remaining: remaining
        }
      end)

    {:ok,
     socket
     |> assign(:current_student, current_student)
     |> assign(:courses, courses)}
  end

  @impl true
  def render(assigns) do
    ~H"""

    <div class="min-h-screen bg-white">
      <div class="mx-auto max-w-5xl px-4 py-8">

        <div class="mb-8 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h1 class="text-3xl font-extrabold tracking-tight text-slate-900">
              Available Courses
            </h1>
            <p class="text-sm font-medium text-slate-500">
              Explore current academic offerings and seat availability
            </p>
          </div>
        </div>

        <div class="space-y-4">
          <%= for item <- @courses do %>
            <div class="flex flex-col justify-between gap-6 rounded-2xl border border-slate-200 bg-slate-50/90 p-6 shadow-sm transition-all hover:border-slate-300 hover:bg-slate-50 md:flex-row md:items-center">


              <div class="space-y-3 md:max-w-xl">
                <div class="flex flex-wrap items-center gap-3">
                  <h2 class="text-xl font-bold text-slate-900">
                    {item.struct.title}
                  </h2>
                  <span class={status_badge_class(item.status)}>
                    {item.status}
                  </span>
                </div>

                <p class="text-sm leading-relaxed text-slate-600 line-clamp-2">
                  {item.struct.description}
                </p>


                <div class="flex flex-wrap items-center gap-4 text-xs font-semibold text-slate-500 pt-1">
                  <div class="flex items-center space-x-1.5">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                    <span>{item.struct.start_date} to {item.struct.end_date}</span>
                  </div>

                  <div class="flex items-center space-x-1.5">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                    <span>Capacity: {item.count} / {item.struct.maximum_capacity}</span>
                  </div>
                </div>
              </div>


              <div class="flex shrink-0 items-center justify-between gap-6 border-t border-slate-200/80 pt-4 md:flex-col md:items-end md:justify-center md:border-l md:border-t-0 md:pl-6 md:pt-0">
                <div class="text-left md:text-right">
                  <span class="block text-[10px] font-bold uppercase tracking-wider text-slate-400">
                    Remaining Seats
                  </span>
                  <span class="text-xl font-black text-slate-800">
                    {item.remaining}
                  </span>
                </div>

                <%= if @current_student do %>

                  <.link
                    navigate={~p"/courses/#{item.struct.id}"}
                    class="inline-flex items-center justify-center rounded-xl bg-indigo-600 px-5 py-2.5 text-sm font-bold text-white shadow-md hover:bg-indigo-700 transition-all"
                  >
                    View Course &rarr;
                  </.link>
                <% else %>

                  <.link
                    navigate={~p"/login"}
                    class="inline-flex items-center justify-center rounded-xl bg-indigo-600 px-5 py-2.5 text-sm font-bold text-white shadow-md hover:bg-indigo-700 transition-all"
                  >
                    Enroll &rarr;
                  </.link>
                <% end %>
              </div>

            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp status_badge_class("Open"),
    do: "bg-emerald-100/80 text-emerald-800 text-xs px-2.5 py-1 rounded-md font-bold"

  defp status_badge_class("Full"),
    do: "bg-amber-100/80 text-amber-800 text-xs px-2.5 py-1 rounded-md font-bold"

  defp status_badge_class("Started"),
    do: "bg-rose-100/80 text-rose-800 text-xs px-2.5 py-1 rounded-md font-bold"

  defp status_badge_class(_),
    do: "bg-slate-200/80 text-slate-700 text-xs px-2.5 py-1 rounded-md font-bold"
end
