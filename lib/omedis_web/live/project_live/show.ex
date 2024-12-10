defmodule OmedisWeb.ProjectLive.Show do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Organisation
  alias Omedis.Accounts.Project

  on_mount {OmedisWeb.LiveHelpers, :assign_and_broadcast_current_organisation}

  @impl true
  def render(assigns) do
    ~H"""
    <.side_and_topbar
      current_user={@current_user}
      current_organisation={@current_organisation}
      language={@language}
    >
      <div class="px-4 lg:pl-80 lg:pr-8 py-10">
        <.breadcrumb
          items={[
            {dgettext("navigation", "Home"), ~p"/", false},
            {dgettext("navigation", "Organisations"), ~p"/organisations", false},
            {@organisation.name, ~p"/organisations/#{@organisation}", false},
            {dgettext("navigation", "Projects"), ~p"/organisations/#{@organisation}/projects", false},
            {@project.name, "", true}
          ]}
          language={@language}
        />

        <.header>
          <%= dgettext("project", "Project") %>
          <:subtitle>
            <%= dgettext("project", "This is a project record from your database.") %>
          </:subtitle>

          <:actions>
            <.link
              patch={~p"/organisations/#{@organisation}/projects/#{@project}/show/edit"}
              phx-click={JS.push_focus()}
            >
              <.button :if={Ash.can?({@project, :update}, @current_user, tenant: @organisation)}>
                <%= dgettext("navigation", "Edit Project") %>
              </.button>
            </.link>
          </:actions>
        </.header>

        <.list>
          <:item title={dgettext("project", "Name")}>
            <%= @project.name %>
          </:item>

          <:item title={dgettext("project", "Position")}>
            <%= @project.position %>
          </:item>
        </.list>

        <.back navigate={~p"/organisations/#{@organisation}/projects"}>
          <%= dgettext("project", "Back to projects") %>
        </.back>

        <.modal
          :if={
            @live_action == :edit and
              Ash.can?({@project, :update}, @current_user, tenant: @organisation)
          }
          id="project-modal"
          show
          on_cancel={JS.patch(~p"/organisations/#{@organisation}/projects/#{@project}")}
        >
          <.live_component
            module={OmedisWeb.ProjectLive.FormComponent}
            id={@project.id}
            current_user={@current_user}
            title={@page_title}
            organisation={@organisation}
            organisations={@organisations}
            next_position={@next_position}
            action={@live_action}
            language={@language}
            project={@project}
            patch={~p"/organisations/#{@organisation}/projects/#{@project}"}
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
  def handle_params(%{"id" => id}, _, socket) do
    actor = socket.assigns.current_user
    project = Project.by_id!(id, actor: actor, tenant: socket.assigns.organisation)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:project, project)
     |> assign(:next_position, project.position)
     |> assign(:organisations, Ash.read!(Organisation, actor: actor))
     |> maybe_check_and_enforce_edit_access(socket.assigns.live_action)}
  end

  defp maybe_check_and_enforce_edit_access(socket, :edit) do
    actor = socket.assigns.current_user
    organisation = socket.assigns.organisation
    project = socket.assigns.project

    user_has_access_rights = Ash.can?({project, :update}, actor, tenant: organisation)

    if user_has_access_rights do
      socket
    else
      socket
      |> push_patch(to: ~p"/organisations/#{organisation}/projects/#{socket.assigns.project.id}")
      |> put_flash(
        :error,
        dgettext("project", "You are not authorized to access this page")
      )
    end
  end

  defp maybe_check_and_enforce_edit_access(socket, _), do: socket

  defp page_title(:show), do: dgettext("project", "Project")

  defp page_title(:edit), do: dgettext("project", "Edit Project")
end
