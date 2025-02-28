defmodule OmedisWeb.ProjectLive.Index do
  use OmedisWeb, :live_view

  alias Omedis.Accounts.Organisation
  alias Omedis.Projects
  alias Omedis.Projects.Project
  alias OmedisWeb.PaginationComponent
  alias OmedisWeb.PaginationUtils

  on_mount {OmedisWeb.LiveHelpers, :assign_and_broadcast_current_organisation}
  on_mount {OmedisWeb.LiveHelpers, :assign_default_pagination_assigns}

  @impl true
  def render(assigns) do
    ~H"""
    <.side_and_topbar current_user={@current_user} organisation={@organisation} language={@language}>
      <div class="px-4 lg:pl-80 lg:pr-8 py-10">
        <.breadcrumb
          items={[
            {dgettext("navigation", "Home"), ~p"/", false},
            {@organisation.name, ~p"/organisations/#{@organisation}", false},
            {dgettext("navigation", "Projects"), ~p"/organisations/#{@organisation}", true}
          ]}
          language={@language}
        />

        <.header>
          {dgettext("project", "Listing Projects")}
          <:actions>
            <.link
              :if={Ash.can?({Project, :create}, @current_user, tenant: @organisation)}
              patch={~p"/projects/new"}
            >
              <.button>
                {dgettext("navigation", "New Project")}
              </.button>
            </.link>
          </:actions>
        </.header>

        <.table
          id="projects"
          rows={@streams.projects}
          row_click={
            fn {_id, project} ->
              JS.navigate(~p"/projects/#{project}")
            end
          }
        >
          <:col :let={{_id, project}} label={dgettext("project", "Name")}>
            {project.name}
          </:col>

          <:col :let={{_id, project}} label={dgettext("project", "Position")}>
            {project.position}
          </:col>

          <:action :let={{_id, project}}>
            <div class="sr-only">
              <.link navigate={~p"/projects/#{project}"}>
                {dgettext("project", "Show")}
              </.link>
            </div>

            <.link
              :if={Ash.can?({project, :update}, @current_user, tenant: @organisation)}
              patch={~p"/projects/#{project}/edit"}
            >
              {dgettext("project", "Edit")}
            </.link>
          </:action>
        </.table>

        <.modal
          :if={@live_action in [:new, :edit]}
          id="project-modal"
          show
          on_cancel={JS.patch(~p"/projects")}
        >
          <.live_component
            module={OmedisWeb.ProjectLive.FormComponent}
            id={(@project && @project.id) || :new}
            current_user={@current_user}
            title={@page_title}
            organisations={@organisations}
            organisation={@organisation}
            next_position={@next_position}
            language={@language}
            action={@live_action}
            project={@project}
            patch={~p"/projects"}
          />
        </.modal>
        <PaginationComponent.pagination
          current_page={@current_page}
          language={@language}
          resource_path={~p"/projects"}
          total_pages={@total_pages}
        />
      </div>
    </.side_and_topbar>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    actor = socket.assigns.current_user

    if connected?(socket) do
      :ok = OmedisWeb.Endpoint.subscribe("#{socket.assigns.organisation.id}:projects")
    end

    {:ok,
     socket
     |> assign(:organisations, Ash.read!(Organisation, actor: actor))
     |> assign(:project, nil)
     |> stream(:projects, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    actor = socket.assigns.current_user
    organisation = socket.assigns.organisation

    next_position =
      Projects.get_max_position_by_organisation_id(organisation.id,
        actor: actor,
        tenant: organisation
      ) + 1

    {:noreply,
     socket
     |> assign(:next_position, next_position)
     |> maybe_enforce_access_rights_and_apply_action(socket.assigns.live_action, params)}
  end

  defp maybe_enforce_access_rights_and_apply_action(socket, :edit, %{"id" => id}) do
    actor = socket.assigns.current_user
    organisation = socket.assigns.organisation

    project = Projects.get_project_by_id(id, actor: actor, tenant: organisation)

    case project do
      {:ok, project} ->
        enforce_access_rights(socket, project, actor: actor, tenant: organisation)

      _ ->
        handle_unauthorized_access(socket)
    end
  end

  defp maybe_enforce_access_rights_and_apply_action(socket, :index, params) do
    socket
    |> assign(
      :page_title,
      dgettext("project", "Projects")
    )
    |> assign(:project, nil)
    |> PaginationUtils.list_paginated(params, :projects, fn offset ->
      Projects.list_paginated_projects(
        actor: socket.assigns.current_user,
        page: [count: true, offset: offset],
        tenant: socket.assigns.organisation
      )
    end)
  end

  defp maybe_enforce_access_rights_and_apply_action(socket, :new, _) do
    actor = socket.assigns.current_user
    organisation = socket.assigns.organisation
    enforce_access_rights(socket, nil, actor: actor, tenant: organisation)
  end

  defp enforce_access_rights(socket, nil, opts) do
    user_has_access_rights =
      Ash.can?({Project, :create}, opts[:actor], tenant: opts[:tenant])

    if user_has_access_rights do
      socket
      |> assign(
        :page_title,
        dgettext("project", "New Project")
      )
      |> assign(:user_has_access_rights, true)
    else
      handle_unauthorized_access(socket)
    end
  end

  defp enforce_access_rights(socket, project, opts) do
    user_has_access_rights =
      Ash.can?({project, :update}, opts[:actor], tenant: opts[:tenant])

    if user_has_access_rights do
      socket
      |> assign(
        :page_title,
        dgettext("project", "Edit Project")
      )
      |> assign(:project, project)
      |> assign(:user_has_access_rights, true)
    else
      handle_unauthorized_access(socket)
    end
  end

  defp handle_unauthorized_access(socket) do
    socket
    |> assign(
      :page_title,
      dgettext("project", "Projects")
    )
    |> assign(:user_has_access_rights, false)
    |> push_patch(to: ~p"/projects")
    |> put_flash(
      :error,
      dgettext("project", "You are not authorized to access this page")
    )
  end

  @impl true
  def handle_info({OmedisWeb.ProjectLive.FormComponent, {:saved, project}}, socket) do
    {:noreply, stream_insert(socket, :projects, project)}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "create"} = broadcast, socket) do
    created_project = Map.get(broadcast.payload, :data)
    {:noreply, stream_insert(socket, :projects, created_project)}
  end
end
