defmodule StudentLiveWeb.ForgotLive do
  use StudentLiveWeb, :live_view

  alias StudentLive.Tokens

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       email: "",
       message: nil
     )}
  end

  @impl true
  def handle_event("request_reset", %{"email" => email}, socket) do
    case Tokens.request_password_reset(email) do
      {:ok, _token} ->
        {:noreply,
         socket
         |> put_flash(:info, "If that email exists, reset link has been sent.")
         |> assign(message: :sent)}

      {:error, :student_not_found} ->
        {:noreply,
         socket
         |> put_flash(:info, "If that email exists, reset link has been sent.")
         |> assign(message: :sent)}

      {:error, _reason} ->
        {:noreply,
         put_flash(socket, :error, "Something went wrong. Please try again.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen items-center justify-center bg-[#0d1322] text-slate-100 p-4">
      <div class="w-full max-w-md space-y-6 rounded-xl border border-slate-800 bg-[#151c2e] p-8 shadow-2xl">

        <div class="text-center">
          <h1 class="text-xl font-bold text-white">
            Forgot Password?
          </h1>

          <p class="text-xs text-slate-400 mt-2">
            Enter your email and we'll send you a password reset link.
          </p>
        </div>

        <%= if @message == :sent do %>
          <div class="rounded-lg border border-[#00a878]/30 bg-[#00a878]/10 p-4 text-center">
            <p class="text-xs text-slate-300">
              If an account exists with that email, a password reset link
              has been sent.
            </p>
          </div>
        <% else %>
          <.form
            for={%{}}
            id="forgot-password-form"
            phx-submit="request_reset"
            class="space-y-4"
          >

            <div>
              <label class="block text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1.5">
                Email Address
              </label>

              <input
                type="email"
                name="email"
                placeholder="you@example.com"
                required
                autocomplete="email"
                class="w-full rounded-lg border border-slate-700/80 bg-[#0d1322] px-4 py-2.5 text-xs text-white placeholder-slate-500 focus:border-[#00a878] focus:outline-none focus:ring-1 focus:ring-[#00a878]"
              />
            </div>

            <button
              type="submit"
              class="w-full rounded-lg bg-[#00a878] hover:bg-[#008f66] py-2.5 text-xs font-bold text-white"
            >
              Send Reset Link
            </button>

          </.form>
        <% end %>

        <div class="text-center text-xs text-slate-400">
          <.link
            navigate={~p"/login"}
            class="font-semibold text-[#00a878] hover:underline"
          >
            Back to Login
          </.link>
        </div>

      </div>
    </div>
    """
  end
end
