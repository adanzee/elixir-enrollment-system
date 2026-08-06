defmodule StudentLiveWeb.AuthLive.RegisterLive do
  use StudentLiveWeb, :live_view

  alias StudentLive.Accounts
  alias StudentLive.Schemas.Student

  def mount(_params, _session, socket) do
    changeset = Student.changeset(%Student{}, %{})

    {:ok,
     assign(socket,
       form: to_form(changeset),
       changeset: changeset
     )}
  end

  def handle_event("validate", %{"student" => student_params}, socket) do
    changeset =
      %Student{}
      |> Student.changeset(student_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset), changeset: changeset)}
  end

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

  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen items-center justify-center bg-slate-50/50 p-4">
      <div class="w-full max-w-md space-y-6 rounded-3xl border border-slate-100 bg-white p-8 shadow-2xl shadow-indigo-100/50">

        <div class="flex flex-col items-center justify-center space-y-3 text-center">
          <div class="flex h-14 w-14 items-center justify-center rounded-2xl bg-indigo-600 text-white shadow-lg shadow-indigo-200">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd" />
            </svg>
          </div>
          <h1 class="text-2xl font-extrabold tracking-tight text-slate-900">
            Create an account
          </h1>
          <p class="text-sm font-medium text-slate-500">
            Sign up to get started with your account
          </p>
        </div>

        <.form for={@form} id="registration-form" action={~p"/register"} phx-change="validate" class="space-y-4"
        >

          <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />

         <div class="space-y-4 [&_label]:font-bold [&_label]:text-gray-600">
          <.input field={@form[:name]} type="text" label="Full Name" required
            class="w-full rounded-xl text-gray-800 border border-slate-200 px-4 py-2.5 text-sm placeholder-gray-400 focus:border-blue-600 focus:outline-none focus:ring-1 focus:ring-blue-600"/>

          <.input field={@form[:email]} type="email" label="Email Address" required
            class="w-full rounded-xl text-gray-800 border border-slate-200 px-4 py-2.5 text-sm placeholder-gray-400 focus:border-blue-600 focus:outline-none focus:ring-1 focus:ring-blue-600"/>

          <.input field={@form[:password]} type="password" label="Password" required
            class="w-full rounded-xl text-gray-800 border border-slate-200 px-4 py-2.5 text-sm placeholder-gray-400 focus:border-blue-600 focus:outline-none focus:ring-1 focus:ring-blue-600"/>

          <.input field={@form[:confirm_password]} type="password" label="Confirm Password" required
            class="w-full rounded-xl text-gray-800 border border-slate-200 px-4 py-2.5 text-sm placeholder-gray-400 focus:border-blue-600 focus:outline-none focus:ring-1 focus:ring-blue-600"/>
        </div>
          <div class="pt-2">
            <button type="submit"
              class="w-full rounded-xl bg-indigo-600 py-3 text-sm font-semibold text-white shadow-md shadow-blue-200 hover:bg-blue-700 transition-all">
              Create Account
            </button>
          </div>
        </.form>

        <div class="pt-2 text-center text-xs font-medium text-slate-500">
          Already have an account?
          <.link
            navigate={~p"/login"}
            class="font-semibold text-indigo-600 hover:text-indigo-700 hover:underline transition-colors ml-1"
          >
            Login
          </.link>
        </div>

      </div>
    </div>
    """
  end
end
