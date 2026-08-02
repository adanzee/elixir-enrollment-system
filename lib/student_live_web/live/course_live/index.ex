defmodule StudentLiveWeb.CourseLive.Index do
  use StudentLiveWeb, :live_view
  alias StudentLive.Courses

  @impl true
  def mount(_params, _session, socket) do
    courses = Courses.list_courses()
    {:ok, assign(socket, courses: courses)}

  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto py-8 px-4">
      <h1 class="text-3xl font-bold mb-6 text-white-900">Available Courses</h1>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <%= for course <- @courses do %>
          <% status = Courses.get_course_status(course) %>
          <% remaining = course.maximum_capacity - course.current_enrollment_count %>
          <div class="border rounded-lg p-6 bg-white shadow-sm flex flex-col justify-between">
            <div>
              <div class="flex justify-between items-center mb-2">
                <h2 class="text-xl font-semibold text-gray-800"><%= course.title %></h2>
                <span class={status_badge_class(status)}><%= status %></span>
              </div>
              <p class="text-gray-600 text-sm mb-4"><%= course.description %></p>

              <div class="text-sm text-gray-500 space-y-1 mb-4">
                <p><strong>Schedule:</strong> <%= course.start_date %> to <%= course.end_date %></p>
                <p><strong>Capacity:</strong> <%= course.current_enrollment_count %> / <%= course.maximum_capacity %></p>
                <p><strong>Remaining Seats:</strong> <%= remaining %></p>
              </div>
            </div>

            <div class="pt-4 border-t">
              <.link navigate={~p"/courses/#{course.id}"} class="w-full text-center block bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded transition">
                View & Enroll
              </.link>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp status_badge_class("Open"), do: "bg-green-100 text-green-800 text-xs px-2.5 py-0.5 rounded font-medium"
  defp status_badge_class("Full"), do: "bg-yellow-100 text-yellow-800 text-xs px-2.5 py-0.5 rounded font-medium"
  defp status_badge_class("Started"), do: "bg-red-100 text-red-800 text-xs px-2.5 py-0.5 rounded font-medium"
  defp status_badge_class(_), do: "bg-gray-100 text-gray-800 text-xs px-2.5 py-0.5 rounded font-medium"
end
