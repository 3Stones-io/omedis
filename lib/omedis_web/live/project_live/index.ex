defmodule OmedisWeb.ProjectLive.Index do
  use OmedisWeb, :live_view

  alias Omedis.Accounts.Project
  alias Omedis.Accounts.Tenant
  alias Omedis.PaginationUtils
  alias OmedisWeb.PaginationComponent

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
        <.breadcrumb items={[
          {"Home", ~p"/", false},
          {"Tenants", ~p"/tenants", false},
          {@tenant.name, ~p"/tenants/#{@tenant.slug}", false},
          {"Projects", ~p"/tenants/#{@tenant.slug}", true}
        ]} />

        <.header>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Listing Projects") %>
          <% end) %>

          <:actions>
            <.link patch={~p"/tenants/#{@tenant.slug}/projects/new"}>
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

            <.link patch={~p"/tenants/#{@tenant.slug}/projects/#{project}/edit"}>
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
          limit={@limit}
          page_start={@page_start}
          total_count={@total_count}
          total_pages={@total_pages}
        />
      </div>
    </.side_and_topbar>
    """
  end

  @impl true
  def mount(%{"slug" => slug} = params, %{"language" => language} = _session, socket) do
    tenant = Tenant.by_slug!(slug)
    next_position = Project.get_max_position_by_tenant_id(tenant.id) + 1

    {:ok,
     socket
     |> assign(:tenants, Ash.read!(Tenant))
     |> assign(:language, language)
     |> assign(:tenant, Tenant.by_id!(tenant.id))
     |> assign(:next_position, next_position)
     |> list_paginated_projects(params)}
  end

  defp list_paginated_projects(socket, params, opts \\ [reset_stream: false]) do
    limit = PaginationUtils.maybe_parse_value(:limit, params["limit"])
    page = PaginationUtils.maybe_parse_value(:page, params["page"])

    case list_paginated_projects(params) do
      {:ok, %{count: total_count, results: tenants}} ->
        reset_stream = opts[:reset_stream]
        total_pages = ceil(total_count / limit)

        socket
        |> assign(:current_page, page)
        |> assign(:limit, limit)
        |> assign(:page_start, page)
        |> assign(:total_count, total_count)
        |> assign(:total_pages, total_pages)
        |> stream(:projects, tenants, reset: reset_stream)

      {:error, _error} ->
        socket
        |> assign(:current_page, 1)
        |> assign(:limit, limit)
        |> assign(:page_start, page)
        |> assign(:total_count, 0)
        |> assign(:total_pages, 0)
        |> stream(:projects, [])
    end
  end

  defp list_paginated_projects(params) do
    case params do
      %{"limit" => limit, "page" => offset} when not is_nil(limit) and not is_nil(offset) ->
        limit_value = PaginationUtils.maybe_parse_value(:limit, limit)
        offset_value = PaginationUtils.maybe_parse_value(:page, offset)

        Project.list_paginated(page: [count: true, limit: limit_value, offset: offset_value])

      %{"limit" => limit} when not is_nil(limit) ->
        limit_value = PaginationUtils.maybe_parse_value(:limit, limit)

        Project.list_paginated(page: [count: true, limit: limit_value])

      %{"page" => offset} when not is_nil(offset) ->
        offset_value = PaginationUtils.maybe_parse_value(:page, offset)

        Project.list_paginated(page: [count: true, offset: offset_value])

      _other ->
        Project.list_paginated(page: [count: true])
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    tenant = Tenant.by_slug!(params["slug"])
    next_position = Project.get_max_position_by_tenant_id(tenant.id) + 1

    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)
     |> assign(:next_position, next_position)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(
      :page_title,
      with_locale(socket.assigns.language, fn -> gettext("Edit Project") end)
    )
    |> assign(:project, Project.by_id!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, with_locale(socket.assigns.language, fn -> gettext("New Project") end))
    |> assign(:project, nil)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, with_locale(socket.assigns.language, fn -> gettext("Projects") end))
    |> assign(:project, nil)
  end

  @impl true
  def handle_event("change_page", %{"limit" => limit, "page" => page} = params, socket) do
    {:noreply,
     socket
     |> list_paginated_projects(params, reset_stream: true)
     |> push_patch(
       to: ~p"/tenants/#{socket.assigns.tenant.slug}/projects?page=#{page}&limit=#{limit}"
     )}
  end

  @impl true
  def handle_info({OmedisWeb.ProjectLive.FormComponent, {:saved, project}}, socket) do
    {:noreply, stream_insert(socket, :projects, project)}
  end
end
