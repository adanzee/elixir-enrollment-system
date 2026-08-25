defmodule StudentLiveWeb.ResetPassword do
  use StudentLiveWeb, :live_view

  alias StudentLive.Tokens

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
    assign(socket,
      token: nil,
      form: to_form(%{
        "password" => "",
        "confirm_password" => ""
      })
    )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    IO.inspect(params, label: "RESET PARAMS")

    {:noreply,
    assign(socket, :token, params["token"])}
  end

  @impl true
  def handle_event("reset_password", params, socket) do
    password = params["password"]
    confirm_password = params["confirm_password"]

    cond do
      password != confirm_password ->
        {:noreply,
         put_flash(socket, :error, "Passwords do not match.")}

      true ->
        case Tokens.reset_password(socket.assigns.token, password) do
          {:ok, :password_reset} ->
            {:noreply,
             socket
             |> put_flash(:info, "Password reset successfully. Please log in.")
             |> push_navigate(to: ~p"/login")}

          {:error, _reason} ->
            {:noreply,
             put_flash(socket, :error, "Reset link is invalid or expired.")}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen items-center justify-center bg-[#0d1322] text-slate-100 p-4">
      <div class="w-full max-w-md space-y-6 rounded-xl border border-slate-800 bg-[#151c2e] p-8 shadow-2xl">

        <div class="text-center">
          <h1 class="text-xl font-bold text-white">Reset Password</h1>
          <p class="text-xs text-slate-400 mt-2">
            Enter your new password below.
          </p>
        </div>

        <.form for={@form} id="reset-password-form" phx-submit="reset_password" class="space-y-4">

          <div>
            <label class="block text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1.5">
              New Password
            </label>

            <.input field={@form[:password]} type="password" required autocomplete="new-password" class="w-full rounded-lg border border-slate-700/80 bg-[#0d1322] px-4 py-2.5 text-xs text-white"/>
          </div>

          <div>
            <label class="block text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1.5">
              Confirm Password
            </label>

            <.input field={@form[:confirm_password]} type="password" required autocomplete="new-password" class="w-full rounded-lg border border-slate-700/80 bg-[#0d1322] px-4 py-2.5 text-xs text-white"/>
          </div>

          <button type="submit" class="w-full rounded-lg bg-[#00a878] py-2.5 text-xs font-bold text-white">
            Reset Password</button>

        </.form>

      </div>
    </div>
    """
  end
end
