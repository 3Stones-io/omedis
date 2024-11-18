defmodule OmedisWeb.ProjectLive.Show do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Organisation
  alias Omedis.Accounts.Project

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
            {dgettext("navigation", "Home"), ~p"/", false},
            {dgettext("navigation", "Organisations"), ~p"/organisations", false},
            {@organisation.name, ~p"/organisations/#{@organisation}", false},
            {dgettext("navigation", "Projects"), ~p"/organisations/#{@organisation}/projects", false},
            {@project.name, "", true}
          ]}
          language={@language}
        />

        <.header>
          <%= with_locale(@language, fn -> dgettext("project", "Project") end) %>
          <:subtitle>
            <%= with_locale(@language, fn ->
              dgettext(
                "project",
                "This is a project record from your database."
              )
            end) %>
          </:subtitle>

          <:actions>
            <.link
              patch={~p"/organisations/#{@organisation}/projects/#{@project}/show/edit"}
              phx-click={JS.push_focus()}
            >
              <.button :if={Ash.can?({@project, :update}, @current_user, tenant: @organisation)}>
                <%= with_locale(@language, fn ->
                  dgettext("navigation", "Edit project")
                end) %>
              </.button>
            </.link>
          </:actions>
        </.header>

        <.list>
          <:item title={with_locale(@language, fn -> dgettext("project", "Name") end)}>
            <%= @project.name %>
          </:item>

          <:item title={with_locale(@language, fn -> dgettext("project", "Position") end)}>
            <%= @project.position %>
          </:item>
        </.list>

        <.back navigate={~p"/organisations/#{@organisation}/projects"}>
          <%= with_locale(@language, fn -> dgettext("project", "Back to projects") end) %>
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
  def handle_params(%{"slug" => slug, "id" => id}, _, socket) do
    actor = socket.assigns.current_user
    organisation = Organisation.by_slug!(slug, actor: actor)
    project = Project.by_id!(id, actor: actor, tenant: organisation)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action, socket.assigns.language))
     |> assign(:project, project)
     |> assign(:next_position, project.position)
     |> assign(:organisations, Ash.read!(Organisation, actor: actor))
     |> assign(:organisation, organisation)
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
        with_locale(socket.assigns.language, fn ->
          dgettext(
            "project",
            "You are not authorized to access this page"
          )
        end)
      )
    end
  end

  defp maybe_check_and_enforce_edit_access(socket, _), do: socket

  defp page_title(:show, language),
    do: with_locale(language, fn -> dgettext("project", "Project") end)

  defp page_title(:edit, language),
    do: with_locale(language, fn -> dgettext("project", "Edit Project") end)
end
