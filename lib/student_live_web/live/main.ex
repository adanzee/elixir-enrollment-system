defmodule StudentLiveWeb.Live.Main do
  use StudentLiveWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen flex-col items-center justify-center bg-[#0d1322] text-slate-100 p-6">
      <div class="w-full max-w-xl text-center space-y-6">
        <div class="space-y-3">
          <h1 class="text-3xl sm:text-4xl font-extrabold tracking-tight text-white">
            Welcome to Student Portal
          </h1>
          <p class="text-sm text-slate-400 font-medium">
            Access your enrolled courses and view assignment progress.
          </p>
        </div>

        <div>
          <.link
            navigate={~p"/courses"}
            class="inline-flex items-center justify-center rounded-lg bg-[#00a878] hover:bg-[#008f66] px-5 py-2.5 text-xs font-bold text-white shadow-md transition-all active:scale-[0.98]"
          >
            See list of available courses
          </.link>
        </div>

      </div>
    </div>
    """
  end
end
