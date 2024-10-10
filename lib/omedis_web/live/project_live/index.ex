defmodule OmedisWeb.ProjectLive.Index do
  use OmedisWeb, :live_view

  alias Omedis.Accounts.Project
  alias Omedis.Accounts.Tenant
  alias Omedis.PaginationUtils
  alias OmedisWeb.PaginationComponent

  on_mount {OmedisWeb.LiveHelpers, :assign_default_pagination_assigns}

  @number_of_records_per_page 10

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
          total_pages={@total_pages}
        />
      </div>
    </.side_and_topbar>
    """
  end

  @impl true
  def mount(%{"slug" => slug} = _params, %{"language" => language} = _session, socket) do
    tenant = Tenant.by_slug!(slug)
    next_position = Project.get_max_position_by_tenant_id(tenant.id) + 1

    {:ok,
     socket
     |> assign(:tenants, Ash.read!(Tenant))
     |> assign(:language, language)
     |> assign(:tenant, Tenant.by_id!(tenant.id))
     |> assign(:next_position, next_position)
     |> stream(:projects, [])}
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

  defp apply_action(socket, :index, params) do
    socket
    |> assign(:page_title, with_locale(socket.assigns.language, fn -> gettext("Projects") end))
    |> assign(:project, nil)
    |> list_paginated_projects(params)
  end

  defp list_paginated_projects(socket, params) do
    page = PaginationUtils.maybe_convert_page_to_integer(params["page"])

    case list_paginated_projects(params) do
      {:ok, %{count: total_count, results: tenants}} ->
        total_pages = max(1, ceil(total_count / @number_of_records_per_page))
        current_page = min(page, total_pages)

        socket
        |> assign(:current_page, current_page)
        |> assign(:total_pages, total_pages)
        |> stream(:projects, tenants, reset: true)

      {:error, _error} ->
        socket
    end
  end

  defp list_paginated_projects(params) do
    case params do
      %{"page" => page} when not is_nil(page) ->
        page_value = max(1, PaginationUtils.maybe_convert_page_to_integer(page))
        offset_value = (page_value - 1) * 10

        Project.list_paginated(page: [count: true, offset: offset_value])

      _other ->
        Project.list_paginated(page: [count: true])
    end
  end

  @impl true
  def handle_info({OmedisWeb.ProjectLive.FormComponent, {:saved, project}}, socket) do
    {:noreply, stream_insert(socket, :projects, project)}
  end
end
