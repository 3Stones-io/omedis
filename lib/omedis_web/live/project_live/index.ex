defmodule OmedisWeb.ProjectLive.Index do
  use OmedisWeb, :live_view

  alias Omedis.Accounts.Organisation
  alias Omedis.Accounts.Project
  alias OmedisWeb.PaginationComponent
  alias OmedisWeb.PaginationUtils

  on_mount {OmedisWeb.LiveHelpers, :assign_default_pagination_assigns}

  @impl true
  def render(assigns) do
    ~H"""
    <.side_and_topbar
      current_user={@current_user}
      current_organisation={@current_organisation}
      language={@language}
      organisations_count={@organisations_count}
    >
      <div class="px-4 lg:pl-80 lg:pr-8 py-10">
        <.breadcrumb
          items={[
            {pgettext("navigation", "Home"), ~p"/", false},
            {pgettext("navigation", "Organisations"), ~p"/organisations", false},
            {@organisation.name, ~p"/organisations/#{@organisation}", false},
            {pgettext("project_list", "Projects"), ~p"/organisations/#{@organisation}", true}
          ]}
          language={@language}
        />

        <.header>
          <%= with_locale(@language, fn -> %>
            <%= pgettext("project_page_title", "Listing Projects") %>
          <% end) %>
          <:actions>
            <.link
              :if={Ash.can?({Project, :create}, @current_user, tenant: @organisation)}
              patch={~p"/organisations/#{@organisation}/projects/new"}
            >
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= pgettext("navigation", "New Project") %>
                <% end) %>
              </.button>
            </.link>
          </:actions>
        </.header>

        <.table
          id="projects"
          rows={@streams.projects}
          row_click={
            fn {_id, project} ->
              JS.navigate(~p"/organisations/#{@organisation}/projects/#{project}")
            end
          }
        >
          <:col
            :let={{_id, project}}
            label={with_locale(@language, fn -> pgettext("project_table", "Name") end)}
          >
            <%= project.name %>
          </:col>

          <:col
            :let={{_id, project}}
            label={with_locale(@language, fn -> pgettext("project_table", "Position") end)}
          >
            <%= project.position %>
          </:col>

          <:action :let={{_id, project}}>
            <div class="sr-only">
              <.link navigate={~p"/organisations/#{@organisation}/projects/#{project}"}>
                <%= with_locale(@language, fn -> %>
                  <%= pgettext("navigation", "Show") %>
                <% end) %>
              </.link>
            </div>

            <.link
              :if={Ash.can?({project, :update}, @current_user, tenant: @organisation)}
              patch={~p"/organisations/#{@organisation}/projects/#{project}/edit"}
            >
              <%= with_locale(@language, fn -> %>
                <%= pgettext("navigation", "Edit") %>
              <% end) %>
            </.link>
          </:action>
        </.table>

        <.modal
          :if={@live_action in [:new, :edit]}
          id="project-modal"
          show
          on_cancel={JS.patch(~p"/organisations/#{@organisation}/projects")}
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
            patch={~p"/organisations/#{@organisation}/projects"}
          />
        </.modal>
        <PaginationComponent.pagination
          current_page={@current_page}
          language={@language}
          resource_path={~p"/organisations/#{@organisation}/projects"}
          total_pages={@total_pages}
        />
      </div>
    </.side_and_topbar>
    """
  end

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    actor = socket.assigns.current_user
    organisation = Organisation.by_slug!(slug, actor: actor)

    next_position =
      Project.get_max_position_by_organisation_id(organisation.id,
        actor: actor,
        tenant: organisation
      ) + 1

    {:ok,
     socket
     |> assign(:organisations, Ash.read!(Organisation, actor: actor))
     |> assign(:organisation, organisation)
     |> assign(:next_position, next_position)
     |> assign(:project, nil)
     |> stream(:projects, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    actor = socket.assigns.current_user
    organisation = Organisation.by_slug!(params["slug"], actor: actor)

    next_position =
      Project.get_max_position_by_organisation_id(organisation.id,
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

    project = Project.by_id(id, actor: actor, tenant: organisation)

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
      with_locale(socket.assigns.language, fn -> pgettext("project_list", "Projects") end)
    )
    |> assign(:project, nil)
    |> PaginationUtils.list_paginated(params, :projects, fn offset ->
      Project.list_paginated(
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
        with_locale(socket.assigns.language, fn ->
          pgettext("project_page_title", "New Project")
        end)
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
        with_locale(socket.assigns.language, fn ->
          pgettext("project_page_title", "Edit Project")
        end)
      )
      |> assign(:project, project)
      |> assign(:user_has_access_rights, true)
    else
      handle_unauthorized_access(socket)
    end
  end

  defp handle_unauthorized_access(socket) do
    organisation = socket.assigns.organisation

    socket
    |> assign(
      :page_title,
      with_locale(socket.assigns.language, fn -> pgettext("project_page_title", "Projects") end)
    )
    |> assign(:user_has_access_rights, false)
    |> push_patch(to: ~p"/organisations/#{organisation}/projects")
    |> put_flash(
      :error,
      with_locale(socket.assigns.language, fn ->
        pgettext("authorisation_error", "You are not authorized to access this page")
      end)
    )
  end

  @impl true
  def handle_info({OmedisWeb.ProjectLive.FormComponent, {:saved, project}}, socket) do
    {:noreply, stream_insert(socket, :projects, project)}
  end
end
