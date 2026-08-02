defmodule StudentLiveWeb.Router do
  use StudentLiveWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {StudentLiveWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end


  scope "/", StudentLiveWeb do
    pipe_through :browser

    live "/", CourseLive.Index, :index
    live "/courses/:id", CourseLive.Show, :show
    live "/assignments/:id", AssignmentLive.Show, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", StudentLiveWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:student_live, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    # lib/student_live_web/router.ex

  # lib/student_live_web/router.ex

  if Application.compile_env(:student_live, :dev_routes) do
  scope "/dev" do
    pipe_through :browser

    live_dashboard "/dashboard",
      metrics: StudentLiveWeb.Telemetry,
      additional_pages: [
        oban: Oban.LiveDashboard # Works once oban_live_dashboard is installed
      ]

    forward "/mailbox", Plug.Swoosh.MailboxPreview
  end
  end
  end
end
