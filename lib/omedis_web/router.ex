defmodule OmedisWeb.Router do
  use OmedisWeb, :router
  use AshAuthentication.Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {OmedisWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
    plug OmedisWeb.Plugs.Locale
    plug OmedisWeb.Plugs.CurrentOrganisation
    plug OmedisWeb.Plugs.OrganisationsCount
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
  end

  scope "/", OmedisWeb do
    pipe_through :browser

    get "/", PageController, :home

    post "/change_language", LanguageController, :update

    live "/login", LoginLive, :index
    live "/register", RegisterLive, :index

    sign_out_route(AuthController, "/auth/user/sign-out")
    auth_routes_for(Omedis.Accounts.User, to: AuthController)

    reset_route([])

    ash_authentication_live_session :authentication_required,
      on_mount: [
        {OmedisWeb.LiveUserAuth, :live_user_required},
        {OmedisWeb.LiveOrganisation, :assign_current_organisation},
        {OmedisWeb.LiveOrganisation, :assign_organisations_count},
        {OmedisWeb.LiveHelpers, :assign_locale}
      ] do
      live "/edit_profile", EditProfileLive, :index
      live "/organisations", OrganisationLive.Index, :index
      live "/organisations/new", OrganisationLive.Index, :new
      live "/organisations/:slug/edit", OrganisationLive.Index, :edit

      live "/organisations/:slug/today", OrganisationLive.Today, :index

      live "/organisations/:slug/groups/:group_slug/activities", ActivityLive.Index, :index
      live "/organisations/:slug/groups/:group_slug/activities/new", ActivityLive.Index, :new
      live "/organisations/:slug/groups/:group_slug/activities/:id", ActivityLive.Show, :show

      live "/organisations/:slug/groups/:group_slug/activities/:id/edit",
           ActivityLive.Index,
           :edit

      live "/organisations/:slug/groups/:group_slug/activities/:id/show/edit",
           ActivityLive.Show,
           :edit

      live "/organisations/:slug/projects", ProjectLive.Index, :index
      live "/organisations/:slug/projects/new", ProjectLive.Index, :new
      live "/organisations/:slug/projects/:id", ProjectLive.Show, :show
      live "/organisations/:slug/projects/:id/edit", ProjectLive.Index, :edit
      live "/organisations/:slug/projects/:id/show/edit", ProjectLive.Show, :edit

      live "/organisations/:slug/groups", GroupLive.Index, :index
      live "/organisations/:slug/groups/new", GroupLive.Index, :new
      live "/organisations/:slug/groups/:group_slug/show/edit", GroupLive.Show, :edit
      live "/organisations/:slug/groups/:group_slug", GroupLive.Show, :show
      live "/organisations/:slug/groups/:group_slug/edit", GroupLive.Index, :edit

      live "/organisations/:slug", OrganisationLive.Show, :show
      live "/organisations/:slug/show/edit", OrganisationLive.Show, :edit

      live "/organisations/:slug/activities/:id/log_entries", LogEntryLive.Index, :index

      live "/organisations/:slug/invitations/new", InvitationLive.Index, :new
      live "/organisations/:slug/invitations/:id", InvitationLive.Show, :show
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", OmedisWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:omedis, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: OmedisWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
