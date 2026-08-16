defmodule StudentLiveWeb.Mail.MailBox do
  use StudentLiveWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    current_student = socket.assigns.current_student

    if connected?(socket) do
      # Subscribe exclusively to this student's ID
      Phoenix.PubSub.subscribe(StudentLive.PubSub, "mailbox:#{current_student.id}")
    end

    emails = load_student_emails(current_student.email)
    {:ok, assign(socket, emails: emails, selected_email: List.first(emails))}
  end

  @impl true
  def handle_info({:new_email, _email}, socket) do
    current_student = socket.assigns.current_student
    emails = load_student_emails(current_student.email)

    # Retain current selected email if still present, else default to first
    selected =
      if socket.assigns.selected_email do
        Enum.find(emails, &(email_id(&1) == email_id(socket.assigns.selected_email))) || List.first(emails)
      else
        List.first(emails)
      end

    {:noreply, assign(socket, emails: emails, selected_email: selected)}
  end

  @impl true
  def handle_event("select_email", %{"id" => id}, socket) do
    email = Enum.find(socket.assigns.emails, &(email_id(&1) == id))
    {:noreply, assign(socket, selected_email: email)}
  end

  @impl true
  def handle_event("clear_emails", _params, socket) do
    current_student = socket.assigns.current_student

    # Only purge emails belonging to this student from memory
    remaining_emails =
      Swoosh.Adapters.Local.Storage.Memory.all()
      |> Enum.reject(&sent_to_student?(&1, current_student.email))

    Swoosh.Adapters.Local.Storage.Memory.delete_all()
    Enum.each(remaining_emails, &Swoosh.Adapters.Local.Storage.Memory.push/1)

    {:noreply, assign(socket, emails: [], selected_email: nil)}
  end

  # Filter emails strictly by recipient address
  defp load_student_emails(student_email) do
    Swoosh.Adapters.Local.Storage.Memory.all()
    |> Enum.filter(&sent_to_student?(&1, student_email))
  rescue
    _ -> []
  end

  defp sent_to_student?(%Swoosh.Email{to: recipients}, student_email) do
    target = String.downcase(to_string(student_email))

    Enum.any?(recipients, fn
      {_name, address} -> String.downcase(to_string(address)) == target
      address when is_binary(address) -> String.downcase(address) == target
      _ -> false
    end)
  end

  defp email_id(%Swoosh.Email{} = email) do
    email.headers["Message-ID"] || email.private[:sent_at] || to_string(:erlang.phash2(email))
  end


  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen bg-[#0d1322] text-slate-100 font-sans antialiased overflow-hidden">
      <!-- Left sidebar: Email list -->
      <div class="w-1/3 min-w-[320px] max-w-[420px] border-r border-slate-800 bg-[#151c2e] flex flex-col">
        <!-- Sidebar Header -->
        <div class="p-4 border-b border-slate-800 flex justify-between items-center bg-[#101726]">
          <div class="flex items-center gap-2">
            <h1 class="font-bold text-sm tracking-wide text-white">Live Mailbox</h1>
            <span class="px-2 py-0.5 text-[10px] font-semibold rounded-full bg-[#00a878]/10 text-[#00a878] border border-[#00a878]/30">
              <%= length(@emails) %>
            </span>
          </div>
          <button
            phx-click="clear_emails"
            class="px-2.5 py-1 text-xs font-semibold bg-red-500/10 hover:bg-red-500/20 text-red-400 border border-red-500/30 rounded-lg transition-colors"
          >
            Clear
          </button>
        </div>

        <!-- Email Items List -->
        <div class="overflow-y-auto flex-1 divide-y divide-slate-800/60">
          <%= if Enum.empty?(@emails) do %>
            <div class="p-8 text-center text-xs text-slate-500">
              No emails in mailbox yet.
            </div>
          <% else %>
            <%= for email <- @emails do %>
              <% id = email_id(email) %>
              <div
                phx-click="select_email"
                phx-value-id={id}
                class={"p-4 cursor-pointer transition-colors border-l-2 #{if @selected_email && email_id(@selected_email) == id, do: "bg-[#0d1322] border-[#00a878]", else: "hover:bg-[#1a233a] border-transparent"}"}
              >
                <div class="flex items-center justify-between gap-2 mb-1">
                  <span class="font-semibold text-xs text-slate-200 truncate">
                    <%= email.subject %>
                  </span>
                </div>
                <div class="text-[11px] text-slate-400 truncate">
                  To: <%= inspect(email.to) %>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>

      <!-- Right pane: Email view -->
      <div class="flex-1 p-6 sm:p-8 overflow-y-auto bg-[#0d1322]">
        <%= if @selected_email do %>
          <div class="max-w-3xl mx-auto space-y-4">
            <!-- Email Metadata Card -->
            <div class="bg-[#151c2e] rounded-xl p-5 border border-slate-800 shadow-xl space-y-3">
              <div class="flex items-start justify-between gap-4">
                <h2 class="text-lg font-bold text-white tracking-tight">
                  <%= @selected_email.subject %>
                </h2>
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-semibold bg-[#00a878]/10 text-[#00a878] border border-[#00a878]/30 whitespace-nowrap">
                  Delivered
                </span>
              </div>

              <div class="grid grid-cols-1 sm:grid-cols-2 gap-2 pt-2 border-t border-slate-800/80 text-xs">
                <div>
                  <span class="text-slate-500">From:</span>
                  <span class="text-slate-300 ml-1"><%= inspect(@selected_email.from) %></span>
                </div>
                <div>
                  <span class="text-slate-500">To:</span>
                  <span class="text-slate-300 ml-1"><%= inspect(@selected_email.to) %></span>
                </div>
              </div>
            </div>

            <!-- Email Body Content -->
            <div class="bg-[#151c2e] rounded-xl p-6 border border-slate-800 shadow-xl">
              <%= if @selected_email.html_body do %>
                <div class="rounded-lg overflow-hidden">
                  <%= Phoenix.HTML.raw(@selected_email.html_body) %>
                </div>
              <% else %>
                <div class="whitespace-pre-wrap font-sans text-xs text-slate-300 leading-relaxed">
                  <%= @selected_email.text_body %>
                </div>
              <% end %>
            </div>
          </div>
        <% else %>
          <div class="h-full flex flex-col items-center justify-center text-slate-500 space-y-2">
            <svg class="w-10 h-10 text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
            </svg>
            <p class="text-xs">Select an email from the left sidebar to read</p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
