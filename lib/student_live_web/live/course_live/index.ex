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
  def handle_event("course_started", _params, socket) do
    {:noreply,
    put_flash(socket, :error, "This course has already started.")}
  end

  @impl true
  def render(assigns) do
    ~H"""
        <div class="min-h-screen bg-slate-900 text-slate-100 p-6">
        <div class="mx-auto max-w-5xl space-y-6">


        <header class="flex flex-col sm:flex-row justify-between items-start sm:items-center pb-4 border-b border-slate-800 gap-4">
          <div class="mb-8 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <h1 class="text-3xl font-extrabold tracking-tight text-white">
                Available Courses
              </h1>
              <p class="text-sm font-medium text-slate-400 mt-1">
                Explore current academic offerings and seat availability
              </p>
            </div>

            <.link
              navigate={~p"/dashboard"}
              class="bg-[#00a878] hover:bg-[#008f66] text-white ml-140 text-xs font-bold px-4 py-2.5 rounded-lg shadow-md transition-colors whitespace-nowrap self-start sm:self-auto"
            >
              Go to Dashboard
            </.link>
          </div>
        </header>

        <div class="space-y-4">
          <%= for item <- @courses do %>
            <div class="flex flex-col justify-between gap-6 rounded-xl border border-slate-800 bg-slate-800/60 p-6 shadow-xl transition-all hover:border-slate-700 hover:bg-slate-800/90 md:flex-row md:items-center">


              <div class="space-y-3 md:max-w-xl">
                <div class="flex flex-wrap items-center gap-3">
                  <h2 class="text-xl font-bold text-slate-100">
                    {item.struct.title}
                  </h2>
                  <span class={status_badge_class(item.status)}>
                    {item.status}
                  </span>
                </div>

                <p class="text-xs leading-relaxed text-slate-400 line-clamp-2">
                  {item.struct.description}
                </p>

                <div class="flex flex-wrap items-center gap-4 text-xs font-semibold text-slate-400 pt-1">
                  <div class="flex items-center space-x-1.5">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                    <span>{item.struct.start_date} to {item.struct.end_date}</span>
                  </div>

                  <div class="flex items-center space-x-1.5">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                    <span>Capacity: {item.count} / {item.struct.maximum_capacity}</span>
                  </div>
                </div>
              </div>

              <div class="flex shrink-0 items-center justify-between gap-6 border-t border-slate-700/60 pt-4 md:flex-col md:items-end md:justify-center md:border-l md:border-t-0 md:pl-6 md:pt-0">
                <div class="text-left md:text-right">
                  <span class="block text-[10px] font-bold uppercase tracking-wider text-slate-400">
                    Remaining Seats
                  </span>
                  <span class="text-xl font-black text-slate-100">
                    {item.remaining}
                  </span>
                </div>

                <%= if @current_student do %>
                  <%= if item.status == "Started" do %>
                    <button type="button" phx-click="course_started" class="inline-flex items-center justify-center px-4 py-2 text-xs font-semibold rounded-lg bg-slate-500 text-white shadow-sm">
                      Course Started
                    </button>
                  <% else %>
                    <.link
                      navigate={~p"/course/register/#{item.struct.id}"}
                      class="inline-flex items-center justify-center px-4 py-2 text-xs font-semibold rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white shadow-sm transition-all focus:ring-2 focus:ring-emerald-500 focus:outline-none"
                    >
                      Enroll Course &rarr;
                    </.link>
                  <% end %>
                <% else %>
                  <.link
                    navigate={~p"/login"}
                    class="inline-flex items-center justify-center px-4 py-2 text-xs font-semibold rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white shadow-sm transition-all"
                  >
                    Register &rarr;
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
