defmodule OmedisWeb.ActivityLive.Show do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Activity
  alias Omedis.Accounts.Group
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
            {@tenant.name, ~p"/tenants/#{@tenant}", false},
            {gettext("Groups"), ~p"/tenants/#{@tenant}/groups", false},
            {@group.name, ~p"/tenants/#{@tenant}/groups/#{@group}", false},
            {gettext("Activities"), ~p"/tenants/#{@tenant}/groups/#{@group}/activities", false},
            {@activity.name, "", true}
          ]}
          language={@language}
        />

        <.header>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Activity") %>
          <% end) %>

          <:subtitle>
            <%= with_locale(@language, fn -> %>
              <%= gettext("This is an activity record from your database.") %>
            <% end) %>
          </:subtitle>

          <:actions>
            <.link
              patch={~p"/tenants/#{@tenant}/groups/#{@group}/activities/#{@activity}/show/edit"}
              phx-click={JS.push_focus()}
            >
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Edit activity") %>
                <% end) %>
              </.button>
            </.link>

            <.link
              navigate={~p"/tenants/#{@tenant}/activities/#{@activity}/log_entries"}
              phx-click={JS.push_focus()}
            >
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= gettext("View Log entries") %>
                <% end) %>
              </.button>
            </.link>
          </:actions>
        </.header>

        <.list>
          <:item title={with_locale(@language, fn -> gettext("Name") end)}>
            <%= @activity.name %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Color code") end)}>
            <%= @activity.color_code %>
          </:item>
          <:item title={with_locale(@language, fn -> gettext("Position") end)}>
            <%= @activity.position %>
          </:item>
        </.list>

        <.back navigate={~p"/tenants/#{@tenant}/groups/#{@group}/activities"}>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Back to activities") %>
          <% end) %>
        </.back>

        <.modal
          :if={@live_action == :edit}
          id="activity-modal"
          show
          on_cancel={JS.patch(~p"/tenants/#{@tenant}/groups/#{@group}/activities/#{@activity}")}
        >
          <.live_component
            module={OmedisWeb.ActivityLive.FormComponent}
            id={@activity.id}
            current_user={@current_user}
            projects={@projects}
            title={@page_title}
            action={@live_action}
            tenant={@tenant}
            groups={@groups}
            color_code={@color_code}
            is_custom_color={@is_custom_color}
            tenants={@tenants}
            group={@group}
            next_position={@next_position}
            language={@language}
            activity={@activity}
            patch={~p"/tenants/#{@tenant}/groups/#{@group}/activities/#{@activity}"}
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
    tenant = Tenant.by_slug!(slug, actor: socket.assigns.current_user)
    group = Group.by_slug!(group_slug, actor: socket.assigns.current_user, tenant: tenant)
    groups = Ash.read!(Group, actor: socket.assigns.current_user, tenant: tenant)
    activity = Activity.by_id!(id, actor: socket.assigns.current_user, tenant: tenant)
    next_position = activity.position

    projects =
      Project.by_tenant_id!(%{tenant_id: tenant.id},
        actor: socket.assigns.current_user,
        tenant: tenant
      )

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action, socket.assigns.language))
     |> assign(:activity, activity)
     |> assign(:tenants, Ash.read!(Tenant, actor: socket.assigns.current_user))
     |> assign(:projects, projects)
     |> assign(:group, group)
     |> assign(:groups, groups)
     |> assign(:tenant, tenant)
     |> assign(:is_custom_color, true)
     |> assign(:color_code, activity.color_code)
     |> assign(:next_position, next_position)
     |> apply_action(socket.assigns.live_action)}
  end

  defp page_title(:show, language),
    do: with_locale(language, fn -> gettext("Show Activity") end)

  defp page_title(:edit, language),
    do: with_locale(language, fn -> gettext("Edit Activity") end)

  defp apply_action(socket, :edit) do
    actor = socket.assigns.current_user
    tenant = socket.assigns.tenant
    activity = socket.assigns.activity

    if Ash.can?({activity, :update}, actor, tenant: tenant) do
      assign(socket, :page_title, page_title(:edit, socket.assigns.language))
    else
      socket
      |> put_flash(:error, gettext("You are not authorized to access this page"))
      |> push_navigate(
        to: ~p"/tenants/#{tenant}/groups/#{socket.assigns.group}/activities/#{activity.id}"
      )
    end
  end

  defp apply_action(socket, _), do: socket
end
