defmodule StudentLiveWeb.AuthLive.LoginLive do
  use StudentLiveWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{"email" => "", "password" => ""}))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen items-center justify-center bg-[#0d1322] text-slate-100 p-4">
      <div class="w-full max-w-md space-y-6 rounded-xl border border-slate-800 bg-[#151c2e] p-8 shadow-2xl">

        <div class="flex flex-col items-center justify-center space-y-2 text-center">
          <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-[#00a878] text-white shadow-md">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clip-rule="evenodd" />
            </svg>
          </div>
          <h1 class="text-xl font-bold tracking-tight text-white">Welcome back</h1>
          <p class="text-xs text-slate-400">Sign in to access your dashboard</p>
        </div>
        <.form for={@form} id="login-form" action={~p"/login"} class="space-y-4" >
          <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />

          <div>
            <label class="block text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1.5">
              Email Address
            </label>
            <.input field={@form[:email]} type="email" placeholder="you@example.com" required autocomplete="email"
              class="w-full rounded-lg border border-slate-700/80 bg-[#0d1322] px-4 py-2.5 text-xs text-white placeholder-slate-500 focus:border-[#00a878] focus:outline-none focus:ring-1 focus:ring-[#00a878] transition-colors" />
          </div>

          <div>
            <label class="block text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1.5">
              Password
            </label>
            <.input field={@form[:password]} type="password" placeholder="••••••••" required autocomplete="current-password"
              class="w-full rounded-lg border border-slate-700/80 bg-[#0d1322] px-4 py-2.5 text-xs text-white placeholder-slate-500 focus:border-[#00a878] focus:outline-none focus:ring-1 focus:ring-[#00a878] transition-colors"/>
          </div>

          <div class="flex justify-end mt-2">
            <.link
              navigate={~p"/forgot-password"}
              class="text-xs font-semibold text-[#00a878] hover:underline"
            >
              Forgot password?
            </.link>
          </div>

          <div class="pt-2">
            <button type="submit" class="w-full rounded-lg bg-[#00a878] hover:bg-[#008f66] py-2.5 text-xs font-bold text-white shadow-md transition-all active:scale-[0.99]">
              Sign In
            </button>
          </div>
        </.form>

        <div class="pt-2 text-center text-xs text-slate-400">
          Don't have an account?
          <.link navigate={~p"/register"} class="font-semibold text-[#00a878] hover:underline transition-colors ml-1">
            Create an account
          </.link>
        </div>

      </div>
    </div>
    """
  end
end
