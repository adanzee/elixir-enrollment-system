defmodule StudentLiveWeb.AuthLive.RegisterLive do
  use StudentLiveWeb, :live_view

  alias StudentLive.Accounts
  alias StudentLive.Schemas.Student

  @impl true
  def mount(_params, _session, socket) do
    changeset = Student.changeset(%Student{}, %{})

    {:ok,
     assign(socket,
       form: to_form(changeset),
       changeset: changeset
     )}
  end

  @impl true
  def handle_event("validate", %{"student" => student_params}, socket) do
    changeset =
      %Student{}
      |> Student.changeset(student_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset), changeset: changeset)}
  end

  @impl true
  def handle_event("register", %{"student" => student_params}, socket) do
    case Accounts.create_student(student_params) do
      {:ok, _student} ->
        {:noreply,
         socket
         |> put_flash(:info, "Registration successful. Please log in.")
         |> push_navigate(to: ~p"/login")}

      {:error, changeset} ->
        {:noreply,
         assign(socket,
           form: to_form(changeset),
           changeset: changeset
         )}
    end
  end

  @impl true
def render(assigns) do
    ~H"""
    <div class="flex min-h-screen items-center justify-center bg-[#0d1322] text-slate-100 p-4">
      <div class="w-full max-w-md space-y-6 rounded-xl border border-slate-800 bg-[#151c2e] p-8 shadow-2xl">

        <div class="flex flex-col items-center justify-center space-y-2 text-center">
          <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-[#00a878] text-white shadow-md">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd" />
            </svg>
          </div>
          <h1 class="text-xl font-bold tracking-tight text-white">Create an account</h1>
          <p class="text-xs text-slate-400">Sign up to get started with your account</p>
        </div>

        <.form for={@form} id="registration-form" action={~p"/register"} class="space-y-4"
        >
          <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />

          <div>
            <label class="block text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1.5">
              Full Name
            </label>
            <.input field={@form[:name]} type="text" placeholder="John Doe" required autocomplete="name" class="w-full rounded-lg border border-slate-700/80 bg-[#0d1322] px-4 py-2.5 text-xs text-white placeholder-slate-500 focus:border-[#00a878] focus:outline-none focus:ring-1 focus:ring-[#00a878] transition-colors" />
          </div>

          <div>
            <label class="block text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1.5">
              Email Address
            </label>
            <.input field={@form[:email]} type="email" placeholder="you@example.com" required autocomplete="email" class="w-full rounded-lg border border-slate-700/80 bg-[#0d1322] px-4 py-2.5 text-xs text-white placeholder-slate-500 focus:border-[#00a878] focus:outline-none focus:ring-1 focus:ring-[#00a878] transition-colors"/>
          </div>

          <div>
            <label class="block text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1.5">
              Password
            </label>
            <.input field={@form[:password]} type="password" placeholder="••••••••" required autocomplete="new-password" class="w-full rounded-lg border border-slate-700/80 bg-[#0d1322] px-4 py-2.5 text-xs text-white placeholder-slate-500 focus:border-[#00a878] focus:outline-none focus:ring-1 focus:ring-[#00a878] transition-colors" />
          </div>

          <div>
            <label class="block text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1.5">
              Confirm Password
            </label>
            <.input field={@form[:confirm_password]} type="password" placeholder="••••••••" required autocomplete="new-password" class="w-full rounded-lg border border-slate-700/80 bg-[#0d1322] px-4 py-2.5 text-xs text-white placeholder-slate-500 focus:border-[#00a878] focus:outline-none focus:ring-1 focus:ring-[#00a878] transition-colors"
            />
          </div>

          <div class="pt-2">
            <button type="submit" class="w-full rounded-lg bg-[#00a878] hover:bg-[#008f66] py-2.5 text-xs font-bold text-white shadow-md transition-all active:scale-[0.99]">
              Create Account
            </button>
          </div>
        </.form>


        <div class="pt-2 text-center text-xs text-slate-400">
          Already have an account?
          <.link
            navigate={~p"/login"}
            class="font-semibold text-[#00a878] hover:underline transition-colors ml-1"
          >
            Login
          </.link>
        </div>

      </div>
    </div>
    """
  end
end
