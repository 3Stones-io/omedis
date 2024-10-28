defmodule OmedisWeb.ActivityLive.Show do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Activity
  alias Omedis.Accounts.Group
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
        <.breadcrumb items={[
          {"Home", ~p"/tenants/#{@tenant.slug}", false},
          {"Groups", ~p"/tenants/#{@tenant.slug}/groups", false},
          {@group.name, ~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}", false},
          {"Activities", ~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}/activities", false},
          {@activity.name, "", true}
        ]} />

        <.header>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Activity") %>
          <% end) %>

          <:subtitle>
            <%= with_locale(@language, fn -> %>
              <%= gettext("This is a activity record from your database.") %>
            <% end) %>
          </:subtitle>

          <:actions>
            <.link
              patch={
                ~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}/activities/#{@activity}/show/edit"
              }
              phx-click={JS.push_focus()}
            >
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Edit activity") %>
                <% end) %>
              </.button>
            </.link>

            <.link
              navigate={~p"/tenants/#{@tenant.slug}/activities/#{@activity}/log_entries"}
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

        <.back navigate={~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}/activities"}>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Back to activities") %>
          <% end) %>
        </.back>

        <.modal
          :if={@live_action == :edit}
          id="activity-modal"
          show
          on_cancel={
            JS.patch(~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}/activities/#{@activity}")
          }
        >
          <.live_component
            module={OmedisWeb.ActivityLive.FormComponent}
            id={@activity.id}
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
            patch={~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}/activities/#{@activity}"}
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
    group = Group.by_slug!(group_slug)
    groups = Ash.read!(Group)
    activity = Activity.by_id!(id)
    next_position = activity.position

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action, socket.assigns.language))
     |> assign(:activity, activity)
     |> assign(:tenants, Ash.read!(Tenant))
     |> assign(:group, group)
     |> assign(:groups, groups)
     |> assign(:tenant, tenant)
     |> assign(:is_custom_color, true)
     |> assign(:color_code, activity.color_code)
     |> assign(:next_position, next_position)}
  end

  defp page_title(:show, language),
    do: with_locale(language, fn -> gettext("Show Activity") end)

  defp page_title(:edit, language),
    do: with_locale(language, fn -> gettext("Edit Activity") end)
end
