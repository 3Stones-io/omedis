defmodule OmedisWeb.ActivityLive.Show do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Activity
  alias Omedis.Accounts.Group
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
            {pgettext("navigation", "Home"), ~p"/", false},
            {pgettext("navigation", "Organisations"), ~p"/organisations", false},
            {@organisation.name, ~p"/organisations/#{@organisation}", false},
            {pgettext("navigation", "Groups"), ~p"/organisations/#{@organisation}/groups", false},
            {@group.name, ~p"/organisations/#{@organisation}/groups/#{@group}", false},
            {pgettext("navigation", "Activities"),
             ~p"/organisations/#{@organisation}/groups/#{@group}/activities", false},
            {@activity.name, "", true}
          ]}
          language={@language}
        />

        <.header>
          <%= with_locale(@language, fn -> %>
            <%= pgettext("page_title", "Activity") %>
          <% end) %>

          <:subtitle>
            <%= with_locale(@language, fn -> %>
              <%= pgettext("page_title", "This is an activity record from your database.") %>
            <% end) %>
          </:subtitle>

          <:actions>
            <.link
              patch={
                ~p"/organisations/#{@organisation}/groups/#{@group}/activities/#{@activity}/show/edit"
              }
              phx-click={JS.push_focus()}
            >
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= pgettext("actions", "Edit activity") %>
                <% end) %>
              </.button>
            </.link>

            <.link
              navigate={~p"/organisations/#{@organisation}/activities/#{@activity}/log_entries"}
              phx-click={JS.push_focus()}
            >
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= pgettext("actions", "View Log entries") %>
                <% end) %>
              </.button>
            </.link>
          </:actions>
        </.header>

        <.list>
          <:item title={with_locale(@language, fn -> pgettext("table_header", "Name") end)}>
            <%= @activity.name %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("table_header", "Color code") end)}>
            <%= @activity.color_code %>
          </:item>
          <:item title={with_locale(@language, fn -> pgettext("table_header", "Position") end)}>
            <%= @activity.position %>
          </:item>
        </.list>

        <.back navigate={~p"/organisations/#{@organisation}/groups/#{@group}/activities"}>
          <%= with_locale(@language, fn -> %>
            <%= pgettext("navigation", "Back to activities") %>
          <% end) %>
        </.back>

        <.modal
          :if={@live_action == :edit}
          id="activity-modal"
          show
          on_cancel={
            JS.patch(~p"/organisations/#{@organisation}/groups/#{@group}/activities/#{@activity}")
          }
        >
          <.live_component
            module={OmedisWeb.ActivityLive.FormComponent}
            id={@activity.id}
            current_user={@current_user}
            projects={@projects}
            title={@page_title}
            action={@live_action}
            organisation={@organisation}
            groups={@groups}
            color_code={@color_code}
            is_custom_color={@is_custom_color}
            organisations={@organisations}
            group={@group}
            next_position={@next_position}
            language={@language}
            activity={@activity}
            patch={~p"/organisations/#{@organisation}/groups/#{@group}/activities/#{@activity}"}
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
  def handle_params(%{"slug" => slug, "id" => id, "group_slug" => group_slug}, _, socket) do
    organisation = Organisation.by_slug!(slug, actor: socket.assigns.current_user)
    group = Group.by_slug!(group_slug, actor: socket.assigns.current_user, tenant: organisation)
    groups = Ash.read!(Group, actor: socket.assigns.current_user, tenant: organisation)
    activity = Activity.by_id!(id, actor: socket.assigns.current_user, tenant: organisation)

    next_position = activity.position

    projects =
      Project.by_organisation_id!(%{organisation_id: organisation.id},
        actor: socket.assigns.current_user,
        tenant: organisation
      )

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action, socket.assigns.language))
     |> assign(:activity, activity)
     |> assign(:organisations, Ash.read!(Organisation, actor: socket.assigns.current_user))
     |> assign(:projects, projects)
     |> assign(:group, group)
     |> assign(:groups, groups)
     |> assign(:organisation, organisation)
     |> assign(:is_custom_color, true)
     |> assign(:color_code, activity.color_code)
     |> assign(:next_position, next_position)
     |> apply_action(socket.assigns.live_action)}
  end

  defp page_title(:show, language),
    do: with_locale(language, fn -> pgettext("page_title", "Show Activity") end)

  defp page_title(:edit, language),
    do: with_locale(language, fn -> pgettext("page_title", "Edit Activity") end)

  defp apply_action(socket, :edit) do
    actor = socket.assigns.current_user
    organisation = socket.assigns.organisation
    activity = socket.assigns.activity

    if Ash.can?({activity, :update}, actor, tenant: organisation) do
      assign(socket, :page_title, page_title(:edit, socket.assigns.language))
    else
      socket
      |> put_flash(
        :error,
        pgettext("flash_message", "You are not authorized to access this page")
      )
      |> push_navigate(
        to:
          ~p"/organisations/#{organisation}/groups/#{socket.assigns.group}/activities/#{activity.id}"
      )
    end
  end

  defp apply_action(socket, _), do: socket
end
