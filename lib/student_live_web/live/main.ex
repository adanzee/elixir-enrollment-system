defmodule StudentLiveWeb.Live.Main do
  use StudentLiveWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen flex-col items-center justify-center bg-slate-50 p-6 text-center">
      <h1 class="text-4xl font-extrabold tracking-tight text-slate-900 sm:text-5xl">
        Welcome to Student Portal
      </h1>
      <p class="mt-3 text-lg font-medium text-slate-600">
        Access your enrolled courses and view assignment progress.
      </p>

      <div class="mt-8 flex flex-col items-center justify-center gap-4 sm:flex-row">


        <.link
          navigate={~p"/courses"}
          class="w-full rounded-2xl border border-slate-200 bg-teal-800 px-8 py-3.5 text-sm font-bold text-white shadow-sm hover:bg-teal-400 hover:border-slate-300 transition-all sm:w-auto"
        >
          See list of available courses
        </.link>
      </div>
    </div>
    """
  end
end
