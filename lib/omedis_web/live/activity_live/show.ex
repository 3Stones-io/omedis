defmodule OmedisWeb.ActivityLive.Show do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Activity
  alias Omedis.Accounts.Group
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
      organisations_count={@organisations_count}
    >
      <div class="px-4 lg:pl-80 lg:pr-8 py-10">
        <.breadcrumb
          items={[
            {dgettext("navigation", "Home"), ~p"/", false},
            {dgettext("navigation", "Organisations"), ~p"/organisations", false},
            {@organisation.name, ~p"/organisations/#{@organisation}", false},
            {dgettext("navigation", "Groups"), ~p"/organisations/#{@organisation}/groups", false},
            {@group.name, ~p"/organisations/#{@organisation}/groups/#{@group}", false},
            {dgettext("navigation", "Activities"),
             ~p"/organisations/#{@organisation}/groups/#{@group}/activities", false},
            {@activity.name, "", true}
          ]}
          language={@language}
        />

        <.header>
          <%= with_locale(@language, fn -> %>
            <%= dgettext("activity", "Activity") %>
          <% end) %>

          <:subtitle>
            <%= with_locale(@language, fn -> %>
              <%= dgettext(
                "activity",
                "This is an activity record from your database."
              ) %>
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
                  <%= dgettext("activity", "Edit Activity") %>
                <% end) %>
              </.button>
            </.link>

            <.link
              navigate={~p"/organisations/#{@organisation}/activities/#{@activity}/events"}
              phx-click={JS.push_focus()}
            >
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= dgettext("activity", "View Events") %>
                <% end) %>
              </.button>
            </.link>
          </:actions>
        </.header>

        <.list>
          <:item title={with_locale(@language, fn -> dgettext("activity", "Name") end)}>
            <%= @activity.name %>
          </:item>

          <:item title={with_locale(@language, fn -> dgettext("activity", "Color Code") end)}>
            <%= @activity.color_code %>
          </:item>

          <:item title={with_locale(@language, fn -> dgettext("activity", "Position") end)}>
            <%= @activity.position %>
          </:item>
        </.list>

        <.back navigate={~p"/organisations/#{@organisation}/groups/#{@group}/activities"}>
          <%= with_locale(@language, fn -> %>
            <%= dgettext("activity", "Back to activities") %>
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
  def handle_params(%{"id" => id, "group_slug" => group_slug}, _, socket) do
    organisation = socket.assigns.organisation
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
     |> assign(:is_custom_color, true)
     |> assign(:color_code, activity.color_code)
     |> assign(:next_position, next_position)
     |> apply_action(socket.assigns.live_action)}
  end

  defp page_title(:show, language),
    do:
      with_locale(language, fn ->
        dgettext("activity", "Show Activity")
      end)

  defp page_title(:edit, language),
    do:
      with_locale(language, fn ->
        dgettext("activity", "Edit Activity")
      end)

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
        dgettext("activity", "You are not authorized to access this page")
      )
      |> push_navigate(
        to:
          ~p"/organisations/#{organisation}/groups/#{socket.assigns.group}/activities/#{activity.id}"
      )
    end
  end

  defp apply_action(socket, _), do: socket
end
