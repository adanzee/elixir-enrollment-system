defmodule StudentLiveWeb.CourseLive.Show do
  use StudentLiveWeb, :live_view
  alias StudentLive.{Courses, Accounts}


 @impl true
def mount(%{"id" => id}, session, socket) do
  course_id = String.to_integer(id)
  IO.inspect(id, label: "URL ID")
  IO.inspect(course_id, label: "Course ID")
  course = Courses.get_course_with_assignments(course_id)
  count = Courses.active_enrollment_count(course_id)

  if connected?(socket) do
    Phoenix.PubSub.subscribe(
      StudentLive.PubSub,
      "course:#{course_id}"
    )
  end

  current_student =
    socket.assigns[:current_student] ||
      Accounts.get_student(session["student_id"])

  is_enrolled =
  if current_student do
    Courses.enrolled?(current_student.id, course_id)
  else
    false
  end

  socket =
  socket
  |> assign(:course, course)
  |> assign(:active_enrollment_count, count)
  |> assign(:course_status, Courses.get_course_status(course, count))
  |> assign(:pdf_url, static_pdf_path(course.outline_pdf_path))
  |> assign(:student, current_student)
  |> assign(:current_student, current_student)
  |> assign(:is_enrolled, is_enrolled)


    {:ok, socket}
end

  @impl true
  def handle_info({:student_promoted, student_id}, socket) do
    course_id = socket.assigns.course.id
    student = Accounts.get_student(student_id)

    socket =
      socket
      |> refresh_course(course_id)
      |> put_flash(:info, "#{student.email} has been promoted from the waitlist.")

    {:noreply, socket}
  end

  defp refresh_course(socket, course_id) do
    course = Courses.get_course_with_assignments(course_id)
    count = Courses.active_enrollment_count(course_id)

    socket
    |> assign(:course, course)
    |> assign(:active_enrollment_count, count)
    |> assign(:course_status, Courses.get_course_status(course, count))
  end



  defp static_pdf_path(nil), do: nil

  defp static_pdf_path("/" <> _ = path), do: path

  defp static_pdf_path(path) do
    filename = Path.basename(path)
    "/uploads/#{filename}"
  end

@impl true
def render(assigns) do
  ~H"""
    <div class="min-h-screen bg-slate-900 text-slate-100 p-6 space-y-6">
        <.link navigate={~p"/courses"} class="text-white-600 hover:underline text-sm mb-4 inline-block font-medium">
          &larr; Back to Course Details
        </.link>
      <header class="flex flex-col sm:flex-row justify-between items-start sm:items-center pb-4 border-b border-slate-800 gap-4">
        <div>
          <div class="flex items-center gap-3">
            <h1 class="text-2xl font-bold text-white tracking-tight">
              <%= @course.title || "CS 402: Web Architecture & Systems Engineering" %>
            </h1>
            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
              <%= @course_status || "Active" %>
            </span>
          </div>
          <p class="text-sm text-slate-400 mt-1">Course Outline & Assignment Portal</p>
        </div>

        <div class="flex items-center gap-3">
          <a href={@pdf_url} download class="inline-flex items-center gap-2 px-3 py-1.5 text-xs font-medium rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 transition-colors">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/></svg>
            Download Syllabus
          </a>
        </div>
      </header>


      <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">

        <section class="lg:col-span-7 xl:col-span-8 bg-slate-800/60 rounded-xl border border-slate-800 overflow-hidden shadow-xl">
          <div class="flex items-center justify-between px-4 py-3 bg-slate-800 border-b border-slate-700/60">
            <div class="flex items-center gap-2 text-sm font-semibold text-slate-200">
              <svg class="w-4 h-4 text-red-400" fill="currentColor" viewBox="0 0 20 20"><path d="M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4z"/></svg>
              Course Syllabus PDF
            </div>
            <span class="text-xs text-slate-400">Scroll to view all pages</span>
          </div>

          <div class="relative w-full bg-slate-950 aspect-[4/3] lg:h-[700px]">
            <iframe
              src={@pdf_url || "/path/to/syllabus.pdf"}
              class="w-full h-full border-0"
              title="Course Syllabus PDF">
            </iframe>
          </div>
        </section>
        <aside class="lg:col-span-5 xl:col-span-4 space-y-4">
          <div class="flex items-center justify-between px-1">
            <h2 class="text-lg font-semibold text-white flex items-center gap-2">
              <svg class="w-5 h-5 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"/></svg>
              Assignments
            </h2>
            <span class="text-xs font-medium px-2 py-1 rounded bg-slate-800 text-slate-400">
              <%= length(@course.assignments) %> Total
            </span>
          </div>
          <div class="space-y-3 max-h-[700px] overflow-y-auto pr-1">
            <%= for assignment <- @course.assignments do %>
              <div class="bg-slate-800/80 hover:bg-slate-800 rounded-xl p-5 border border-slate-700/60 transition-all shadow-md group">
                <div class="flex items-start justify-between gap-2 mb-2">
                  <h3 class="font-semibold text-slate-100 group-hover:text-emerald-400 transition-colors">
                    <%= assignment.title %>
                  </h3>
                </div>

                <p class="text-xs text-slate-400 leading-relaxed mb-4">
                  <%= assignment.description %>
                </p>

                <div class="flex items-center justify-between pt-3 border-t border-slate-700/40">


                  <.link
                    navigate={~p"/assignments/#{assignment.id}"}
                    class="px-3 py-1.5 text-xs font-semibold rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white shadow-sm transition-all focus:ring-2 focus:ring-emerald-500 focus:outline-none inline-block">
                    Submit Assignment
                  </.link>
                </div>
              </div>
            <% end %>
            <%= if Enum.empty?(@course.assignments) do %>
              <div class="bg-slate-800/40 rounded-xl p-8 text-center border border-dashed border-slate-700 text-slate-400 text-sm">
                No assignments published yet.
              </div>
            <% end %>
          </div>
        </aside>

      </div>
    </div>
  """
end
end
