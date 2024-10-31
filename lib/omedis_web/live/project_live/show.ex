defmodule OmedisWeb.ProjectLive.Show do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Project
  alias Omedis.Accounts.Tenant

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
            {gettext("Projects"), ~p"/tenants/#{@tenant.slug}/projects", false},
            {@project.name, "", true}
          ]}
          language={@language}
        />

        <.header>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Project") %>
          <% end) %>
          <:subtitle>
            <%= with_locale(@language, fn -> %>
              <%= gettext("This is a project record from your database.") %>
            <% end) %>
          </:subtitle>

          <:actions>
            <.link
              patch={~p"/tenants/#{@tenant.slug}/projects/#{@project}/show/edit"}
              phx-click={JS.push_focus()}
            >
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Edit project") %>
                <% end) %>
              </.button>
            </.link>
          </:actions>
        </.header>

        <.list>
          <:item title={with_locale(@language, fn -> gettext("Name") end)}>
            <%= @project.name %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Postion") end)}>
            <%= @project.position %>
          </:item>
        </.list>

        <.back navigate={~p"/tenants/#{@tenant.slug}/projects"}>
          <%= with_locale(@language, fn -> gettext("Back to projects") end) %>
        </.back>

        <.modal
          :if={@live_action == :edit}
          id="project-modal"
          show
          on_cancel={JS.patch(~p"/tenants/#{@tenant.slug}/projects/#{@project}")}
        >
          <.live_component
            module={OmedisWeb.ProjectLive.FormComponent}
            id={@project.id}
            title={@page_title}
            tenant={@tenant}
            tenants={@tenants}
            next_position={@next_position}
            action={@live_action}
            language={@language}
            project={@project}
            patch={~p"/tenants/#{@tenant.slug}/projects/#{@project}"}
          />
        </.modal>
      </div>
    </.side_and_topbar>
    """
  end

  @impl true
  def mount(_params, %{"language" => language} = _session, socket) do
    {:ok,
     socket
     |> assign(:language, language)}
  end

  @impl true
  def handle_params(%{"slug" => slug, "id" => id}, _, socket) do
    project = Project.by_id!(id)
    tenant = Tenant.by_slug!(slug, actor: socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action, socket.assigns.language))
     |> assign(:project, project)
     |> assign(:next_position, project.position)
     |> assign(:tenants, Ash.read!(Tenant))
     |> assign(:tenant, tenant)}
  end

  defp page_title(:show, language), do: with_locale(language, fn -> gettext("Project") end)
  defp page_title(:edit, language), do: with_locale(language, fn -> gettext("Edit Project") end)
end
