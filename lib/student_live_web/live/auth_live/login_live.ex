defmodule StudentLiveWeb.AuthLive.LoginLive do
  use StudentLiveWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{"email" => "", "password" => ""}))}
  end

  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen items-center justify-center bg-slate-50/50 p-4">
      <div class="w-full max-w-md space-y-6 rounded-3xl border border-slate-100 bg-white p-8 shadow-2xl shadow-indigo-100/50">

        <div class="flex flex-col items-center justify-center space-y-3 text-center">
          <div class="flex h-14 w-14 items-center justify-center rounded-2xl bg-indigo-600 text-white shadow-lg shadow-indigo-200">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clip-rule="evenodd" />
            </svg>
          </div>
          <h1 class="text-2xl font-extrabold tracking-tight text-slate-900">Welcome back</h1>
          <p class="text-sm font-medium text-slate-500">Sign in to access your dashboard</p>
        </div>


        <.form
          for={@form}
          id="login-form"
          action={~p"/login"}
          class="space-y-4"
        >
          <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />

          <div>
            <label class="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5">
              Email Address
            </label>
            <.input field={@form[:email]} type="email" placeholder="you@example.com" required autocomplete="email"
              class="w-full rounded-xl border border-slate-200 px-4 py-2.5 text-sm text-slate-800 placeholder-slate-400 focus:border-indigo-600 focus:outline-none focus:ring-1 focus:ring-indigo-600"
            />
          </div>

          <div>
            <label class="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5">
              Password
            </label>
            <.input field={@form[:password]} type="password" placeholder="••••••••" required autocomplete="current-password"
              class="w-full rounded-xl border border-slate-200 px-4 py-2.5 text-sm text-slate-800 placeholder-slate-400 focus:border-indigo-600 focus:outline-none focus:ring-1 focus:ring-indigo-600"
            />
          </div>

          <div class="pt-2">
            <button type="submit" class="w-full rounded-xl bg-indigo-600 py-3 text-sm font-semibold text-white shadow-md shadow-indigo-200 hover:bg-indigo-700 transition-all active:scale-[0.99]"
            >
              Sign In
            </button>
          </div>
        </.form>

        <div class="pt-2 text-center text-xs font-medium text-slate-500">
          Don't have an account?
          <.link navigate={~p"/register"} class="font-semibold text-indigo-600 hover:text-indigo-700 hover:underline transition-colors ml-1">
            Create an account
          </.link>
        </div>

      </div>
    </div>
    """
  end
end
