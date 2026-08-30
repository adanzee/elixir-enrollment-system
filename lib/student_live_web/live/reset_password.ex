defmodule StudentLiveWeb.ResetPassword do
  use StudentLiveWeb, :live_view

  alias StudentLive.Tokens

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       token: nil,
       form:
         to_form(%{
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

          {:error, :token_already_used} ->
            {:noreply,
             put_flash(socket, :error, "This password link has been already used.")}

          {:error, :token_expired} ->
            {:noreply, put_flash(socket, :error, "Reset link has expired")}

          {:error, :token_revoked} ->
            {:noreply, put_flash(socket, :error, "Reset link has been revoked")}

          {:error, :invalid_token} ->
            {:noreply, put_flash(socket, :error, "Link is invalid")}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen items-center justify-center bg-[#0d1322] text-slate-100 p-4">
    <.flash kind={:error} flash={@flash} />
    <.flash kind={:info} flash={@flash} />
      <div class="w-full max-w-md space-y-6 rounded-xl border border-slate-800 bg-[#151c2e] p-8 shadow-2xl">

        <div class="text-center">
          <h1 class="text-xl font-bold text-white">
            Reset Password
          </h1>

          <p class="text-xs text-slate-400 mt-2">
            Enter your new password below.
          </p>
        </div>

        <.form
          for={@form}
          id="reset-password-form"
          phx-submit="reset_password"
          class="space-y-4"
        >


          <div>
            <label class="block text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1.5">
              New Password
            </label>

            <div class="relative">
              <.input
                field={@form[:password]}
                type="password"
                id="reset-password"
                placeholder="••••••••"
                required
                autocomplete="new-password"
                class="w-full rounded-lg border border-slate-700/80 bg-[#0d1322] px-4 py-2.5 pr-16 text-xs text-white placeholder-slate-500 focus:border-[#00a878] focus:outline-none focus:ring-1 focus:ring-[#00a878] transition-colors"
              />

              <button
                type="button"
                phx-click={
                  JS.toggle_attribute(
                    {"type", "text", "password"},
                    to: "#reset-password"
                  )
                  |> JS.toggle(to: "#reset-password-show")
                  |> JS.toggle(to: "#reset-password-hide")
                }
                class="absolute right-3 top-1/2 -translate-y-1/2 text-[10px] font-semibold text-slate-400 hover:text-white"
              >
                <span id="reset-password-show">
                  Show
                </span>

                <span id="reset-password-hide" class="hidden">
                  Hide
                </span>
              </button>
            </div>
          </div>

          <div>
            <label class="block text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1.5">
              Confirm Password
            </label>

            <div class="relative">
              <.input
                field={@form[:confirm_password]}
                type="password"
                id="reset-confirm-password"
                placeholder="••••••••"
                required
                autocomplete="new-password"
                class="w-full rounded-lg border border-slate-700/80 bg-[#0d1322] px-4 py-2.5 pr-16 text-xs text-white placeholder-slate-500 focus:border-[#00a878] focus:outline-none focus:ring-1 focus:ring-[#00a878] transition-colors"
              />

              <button
                type="button"
                phx-click={
                  JS.toggle_attribute(
                    {"type", "text", "password"},
                    to: "#reset-confirm-password"
                  )
                  |> JS.toggle(to: "#reset-confirm-password-show")
                  |> JS.toggle(to: "#reset-confirm-password-hide")
                }
                class="absolute right-3 top-1/2 -translate-y-1/2 text-[10px] font-semibold text-slate-400 hover:text-white"
              >
                <span id="reset-confirm-password-show">
                  Show
                </span>

                <span id="reset-confirm-password-hide" class="hidden">
                  Hide
                </span>
              </button>
            </div>
          </div>

          <button
            type="submit"
            class="w-full rounded-lg bg-[#00a878] hover:bg-[#008f66] py-2.5 text-xs font-bold text-white shadow-md transition-all active:scale-[0.99]"
          >
            Reset Password
          </button>

        </.form>

      </div>
    </div>
    """
  end
end
