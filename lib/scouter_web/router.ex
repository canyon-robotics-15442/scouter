defmodule ScouterWeb.Router do
  use ScouterWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ScouterWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug :require_authenticated_user
  end

  def fetch_current_user(conn, _opts) do
    user = Plug.Conn.get_session(conn, :current_user)
    Plug.Conn.assign(conn, :current_user, user)
  end

  def user_session(conn) do
    %{"current_user" => conn.assigns[:current_user]}
  end

  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> Phoenix.Controller.put_flash(:error, "You must log in first.")
      |> Phoenix.Controller.redirect(to: "/")
      |> halt()
    end
  end

  scope "/", ScouterWeb do
    pipe_through :browser
    get "/", PageController, :home
  end

  scope "/", ScouterWeb do
    pipe_through [:browser, :authenticated]

    live "/events", EventsLive
    live "/events/:vex_id", EventLive
    live "/skills", SkillsLive
    live "/leaderboard", LeaderboardLive
    live "/teams/search", TeamSearchLive

    live_session :team, session: {__MODULE__, :user_session, []} do
      live "/teams/:number", TeamLive
    end
  end

  scope "/auth", ScouterWeb do
    pipe_through :browser

    get "/logout", AuthController, :logout
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  # Other scopes may use custom stacks.
  # scope "/api", ScouterWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:scouter, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ScouterWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
