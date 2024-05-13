defmodule SonixWeb.Router do
  use SonixWeb, :router

  import SonixWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SonixWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  scope "/", SonixWeb do
    pipe_through :browser

    get "/callback", AuthController, :callback
  end

  scope "/", SonixWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{SonixWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/log_in", UserLoginLive, :new
    end
  end

  scope "/", SonixWeb do
    pipe_through [:browser, :require_authenticated_user]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{SonixWeb.UserAuth, :mount_current_user}] do
      live "/", SonixLive
    end
  end
end
