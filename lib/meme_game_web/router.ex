defmodule MemeGameWeb.Router do
  use MemeGameWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :template do
    plug :put_root_layout, html: {MemeGameWeb.Layouts, :root}
  end

  pipeline :game do
    plug MemeGameWeb.Accounts.SetPlayer
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MemeGameWeb do
    pipe_through [:browser, :template]

    get "/", PageController, :home
    post "/", PageController, :start_session

    live "/game/:game_id/inspect", Game.InspectLive
  end

  scope "/game", MemeGameWeb do
    pipe_through [:browser, :template, :game]

    live_session :game_session do
      live "/", GameLive
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", MemeGameWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:meme_game, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MemeGameWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
