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
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
  end

  scope "/", OmedisWeb do
    pipe_through :browser

    sign_in_route(
      path: "/login",
      reset_path: "/password-reset",
      live_view: OmedisWeb.LoginLive,
      on_mount: [{OmedisWeb.LiveHelpers, :redirect_if_user_is_authenticated}]
    )

    reset_route(
      live_view: OmedisWeb.ResetPasswordLive,
      on_mount: [{OmedisWeb.LiveHelpers, :redirect_if_user_is_authenticated}]
    )

    sign_out_route(AuthController, "/auth/user/sign-out")
    auth_routes_for(Omedis.Accounts.User, to: AuthController)

    ash_authentication_live_session :redirect_if_user_is_authenticated,
      on_mount: [
        {OmedisWeb.LiveHelpers, :redirect_if_user_is_authenticated}
      ] do
      live "/register", RegisterLive, :index
    end
  end

  scope "/", OmedisWeb do
    pipe_through :browser

    get "/", PageController, :home

    post "/change_language", LanguageController, :update

    ash_authentication_live_session :authentication_required,
      on_mount: [
        {OmedisWeb.LiveUserAuth, :live_user_required},
        {OmedisWeb.LiveOrganisation, :assign_current_organisation},
        {OmedisWeb.LiveHelpers, :assign_locale},
        {OmedisWeb.LiveHelpers, :assign_pubsub_topics_unique_id}
      ],
      session: {OmedisWeb.LiveHelpers, :add_pubsub_topics_unique_id_to_session, []} do
      live "/edit_profile", EditProfileLive, :index

      live "/invitations", InvitationLive.Index, :index

      live "/today", OrganisationLive.Today, :index

      live "/groups/:group_slug/activities", ActivityLive.Index, :index
      live "/groups/:group_slug/activities/new", ActivityLive.Index, :new
      live "/groups/:group_slug/activities/:id", ActivityLive.Show, :show

      live "/groups/:group_slug/activities/:id/edit",
           ActivityLive.Index,
           :edit

      live "/groups/:group_slug/activities/:id/show/edit",
           ActivityLive.Show,
           :edit

      live "/projects", ProjectLive.Index, :index
      live "/projects/new", ProjectLive.Index, :new
      live "/projects/:id", ProjectLive.Show, :show
      live "/projects/:id/edit", ProjectLive.Index, :edit
      live "/projects/:id/show/edit", ProjectLive.Show, :edit

      live "/groups", GroupLive.Index, :index
      live "/groups/new", GroupLive.Index, :new
      live "/groups/:group_slug/show/edit", GroupLive.Show, :edit
      live "/groups/:group_slug", GroupLive.Show, :show
      live "/groups/:group_slug/edit", GroupLive.Index, :edit

      live "/organisations/:slug", OrganisationLive.Show, :show
      live "/show/edit", OrganisationLive.Show, :edit

      live "/activities/:id/events", EventLive.Index, :index

      live "/invitations/new", InvitationLive.Index, :new
    end

    live "/invitations/:id", InvitationLive.Show, :show
  end

  scope "/playground", OmedisWeb.PlaygroundLive do
    pipe_through :browser

    live_session :playground do
      live "/", Index, :index
      live "/client-doctor-forms", ClientDoctorForms, :client_info
      live "/client-doctor-forms/billing", ClientDoctorForms, :billing
      live "/client-doctor-forms/doctor", ClientDoctorForms, :doctor
      live "/time-tracking", TimeTracking
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
