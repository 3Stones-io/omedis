defmodule OmedisWeb.ProjectLive.Index do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Tenant
  alias Omedis.Accounts.Project

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Projects
      <:actions>
        <.link patch={~p"/tenants/#{@tenant.slug}/projects/new"}>
          <.button>New Project</.button>
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
      <:col :let={{_id, project}} label="Id"><%= project.id %></:col>

      <:col :let={{_id, project}} label="Name"><%= project.name %></:col>

      <:col :let={{_id, project}} label="Tenant"><%= project.tenant_id %></:col>

      <:col :let={{_id, project}} label="Position"><%= project.position %></:col>

      <:action :let={{_id, project}}>
        <div class="sr-only">
          <.link navigate={~p"/tenants/#{@tenant.slug}/projects/#{project}"}>Show</.link>
        </div>

        <.link patch={~p"/tenants/#{@tenant.slug}/projects/#{project}/edit"}>Edit</.link>
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
        action={@live_action}
        project={@project}
        patch={~p"/tenants/#{@tenant.slug}/projects"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    tenant = Tenant.by_slug!(slug)
    next_position = Project.get_max_position_by_tenant_id(tenant.id) + 1

    {:ok,
     socket
     |> stream(:projects, Ash.read!(Project))
     |> assign(:tenants, Ash.read!(Tenant))
     |> assign(:tenant, Tenant.by_id!(tenant.id))
     |> assign(:next_position, next_position)}
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
    |> assign(:page_title, "Edit Project")
    |> assign(:project, Omedis.Accounts.Project.by_id!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Project")
    |> assign(:project, nil)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Projects")
    |> assign(:project, nil)
  end

  @impl true
  def handle_info({OmedisWeb.ProjectLive.FormComponent, {:saved, project}}, socket) do
    {:noreply, stream_insert(socket, :projects, project)}
  end
end
