defmodule OmedisWeb.ProjectLive.Index do
  use OmedisWeb, :live_view

  alias Omedis.Accounts.Project
  alias Omedis.Accounts.Tenant
  alias Omedis.PaginationUtils
  alias OmedisWeb.PaginationComponent

  on_mount {OmedisWeb.LiveHelpers, :assign_default_pagination_assigns}

  @impl true
  def render(assigns) do
    ~H"""
    <.side_and_topbar
      current_user={@current_user}
      current_tenant={@current_tenant}
      language={@language}
      tenants_count={@tenants_count}
    >
      <div class="px-4 lg:pl-80 lg:pr-8 py-10">
        <.breadcrumb
          items={[
            {gettext("Home"), ~p"/", false},
            {gettext("Tenants"), ~p"/tenants", false},
            {@tenant.name, ~p"/tenants/#{@tenant.slug}", false},
            {gettext("Projects"), ~p"/tenants/#{@tenant.slug}", true}
          ]}
          language={@language}
        />

        <.header>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Listing Projects") %>
          <% end) %>
          <:actions>
            <.link
              :if={Ash.can?({Project, :create}, @current_user, tenant: @tenant)}
              patch={~p"/tenants/#{@tenant.slug}/projects/new"}
            >
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= gettext("New Project") %>
                <% end) %>
              </.button>
            </.link>
          </:actions>
        </.header>

        <.table
          id="projects"
          rows={@streams.projects}
          row_click={
            fn {_id, project} -> JS.navigate(~p"/tenants/#{@tenant.slug}/projects/#{project}") end
          }
        >
          <:col :let={{_id, project}} label={with_locale(@language, fn -> gettext("Name") end)}>
            <%= project.name %>
          </:col>

          <:col :let={{_id, project}} label={with_locale(@language, fn -> gettext("Position") end)}>
            <%= project.position %>
          </:col>

          <:action :let={{_id, project}}>
            <div class="sr-only">
              <.link navigate={~p"/tenants/#{@tenant.slug}/projects/#{project}"}>
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Show") %>
                <% end) %>
              </.link>
            </div>

            <.link
              :if={Ash.can?({project, :update}, @current_user, tenant: @tenant)}
              patch={~p"/tenants/#{@tenant.slug}/projects/#{project}/edit"}
            >
              <%= with_locale(@language, fn -> %>
                <%= gettext("Edit") %>
              <% end) %>
            </.link>
          </:action>
        </.table>

        <.modal
          :if={@live_action in [:new, :edit]}
          id="project-modal"
          show
          on_cancel={JS.patch(~p"/tenants/#{@tenant.slug}/projects")}
        >
          <.live_component
            module={OmedisWeb.ProjectLive.FormComponent}
            id={(@project && @project.id) || :new}
            current_user={@current_user}
            title={@page_title}
            tenants={@tenants}
            tenant={@tenant}
            next_position={@next_position}
            language={@language}
            action={@live_action}
            project={@project}
            patch={~p"/tenants/#{@tenant.slug}/projects"}
          />
        </.modal>
        <PaginationComponent.pagination
          current_page={@current_page}
          language={@language}
          resource_path={~p"/tenants/#{@tenant.slug}/projects"}
          total_pages={@total_pages}
        />
      </div>
    </.side_and_topbar>
    """
  end

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    actor = socket.assigns.current_user
    tenant = Tenant.by_slug!(slug, actor: actor)

    next_position =
      Project.get_max_position_by_tenant_id(tenant.id, actor: actor, tenant: tenant) + 1

    {:ok,
     socket
     |> assign(:tenants, Ash.read!(Tenant, actor: actor))
     |> assign(:tenant, tenant)
     |> assign(:next_position, next_position)
     |> assign(:project, nil)
     |> stream(:projects, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    actor = socket.assigns.current_user
    tenant = Tenant.by_slug!(params["slug"], actor: actor)

    next_position =
      Project.get_max_position_by_tenant_id(tenant.id, actor: actor, tenant: tenant) + 1

    {:noreply,
     socket
     |> assign(:next_position, next_position)
     |> maybe_enforce_access_rights_and_apply_action(socket.assigns.live_action, params)}
  end

  defp maybe_enforce_access_rights_and_apply_action(socket, :edit, %{"id" => id}) do
    actor = socket.assigns.current_user
    tenant = socket.assigns.tenant

    project = Project.by_id(id, actor: actor, tenant: tenant)

    case project do
      {:ok, project} ->
        enforce_access_rights(socket, project, actor: actor, tenant: tenant)

      _ ->
        handle_unauthorized_access(socket)
    end
  end

  defp maybe_enforce_access_rights_and_apply_action(socket, :index, params) do
    socket
    |> assign(
      :page_title,
      with_locale(socket.assigns.language, fn -> gettext("Projects") end)
    )
    |> assign(:project, nil)
    |> list_paginated_projects(params)
  end

  defp maybe_enforce_access_rights_and_apply_action(socket, :new, _) do
    actor = socket.assigns.current_user
    tenant = socket.assigns.tenant
    enforce_access_rights(socket, nil, actor: actor, tenant: tenant)
  end

  defp enforce_access_rights(socket, nil, opts) do
    user_has_access_rights = Ash.can?({Project, :create}, opts[:actor], tenant: opts[:tenant])

    if user_has_access_rights do
      socket
      |> assign(
        :page_title,
        with_locale(socket.assigns.language, fn -> gettext("New Project") end)
      )
      |> assign(:user_has_access_rights, true)
    else
      handle_unauthorized_access(socket)
    end
  end

  defp enforce_access_rights(socket, project, opts) do
    user_has_access_rights = Ash.can?({project, :update}, opts[:actor], tenant: opts[:tenant])

    if user_has_access_rights do
      socket
      |> assign(
        :page_title,
        with_locale(socket.assigns.language, fn -> gettext("Edit Project") end)
      )
      |> assign(:project, project)
      |> assign(:user_has_access_rights, true)
    else
      handle_unauthorized_access(socket)
    end
  end

  defp handle_unauthorized_access(socket) do
    tenant = socket.assigns.tenant

    socket
    |> assign(:page_title, with_locale(socket.assigns.language, fn -> gettext("Projects") end))
    |> assign(:user_has_access_rights, false)
    |> push_patch(to: ~p"/tenants/#{tenant.slug}/projects")
    |> put_flash(
      :error,
      with_locale(socket.assigns.language, fn ->
        gettext("You are not authorized to access this page")
      end)
    )
  end

  defp list_paginated_projects(%Phoenix.LiveView.Socket{} = socket, params) do
    page = PaginationUtils.maybe_convert_page_to_integer(params["page"])
    opts = [actor: socket.assigns.current_user, tenant: socket.assigns.tenant]

    case list_paginated_projects(params, opts) do
      {:ok, %{count: total_count, results: projects}} ->
        total_pages = max(1, ceil(total_count / socket.assigns.number_of_records_per_page))
        current_page = min(page, total_pages)

        socket
        |> assign(:current_page, current_page)
        |> assign(:total_pages, total_pages)
        |> stream(:projects, projects, reset: true)

      {:error, _error} ->
        socket
    end
  end

  defp list_paginated_projects(params, opts) do
    case params do
      %{"page" => page} when not is_nil(page) ->
        page_value = max(1, PaginationUtils.maybe_convert_page_to_integer(page))
        offset_value = (page_value - 1) * 10

        Project.list_paginated(opts ++ [page: [count: true, offset: offset_value]])

      _ ->
        Project.list_paginated(opts ++ [page: [count: true]])
    end
  end

  @impl true
  def handle_info({OmedisWeb.ProjectLive.FormComponent, {:saved, project}}, socket) do
    {:noreply, stream_insert(socket, :projects, project)}
  end
end
