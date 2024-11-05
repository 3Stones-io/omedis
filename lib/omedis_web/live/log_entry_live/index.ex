defmodule OmedisWeb.LogEntryLive.Index do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Activity
  alias Omedis.Accounts.LogEntry
  alias Omedis.Accounts.Tenant
  alias OmedisWeb.PaginationComponent
  alias OmedisWeb.PaginationUtils

  on_mount {OmedisWeb.LiveHelpers, :assign_default_pagination_assigns}

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
            {gettext("Groups"), ~p"/tenants/#{@tenant.slug}/groups", false},
            {@group.name, ~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}", false},
            {gettext("Activities"), ~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}/activities",
             false},
            {@activity.name,
             ~p"/tenants/#{@tenant.slug}/groups/#{@group.slug}/activities/#{@activity.id}", false},
            {"Log Entries", "", true}
          ]}
          language={@language}
        />

        <.header>
          <span>
            <%= with_locale(@language, fn -> %>
              <%= gettext("Listing Log entries for") %>
            <% end) %>
          </span>
          <%= @activity.name %>
        </.header>

        <.table id="log_entries" rows={@streams.log_entries}>
          <:col :let={{_id, log_entry}} label={with_locale(@language, fn -> gettext("Comment") end)}>
            <%= log_entry.comment %>
          </:col>

          <:col :let={{_id, log_entry}} label={with_locale(@language, fn -> gettext("Start at") end)}>
            <%= log_entry.start_at %>
          </:col>

          <:col :let={{_id, log_entry}} label={with_locale(@language, fn -> gettext("End at") end)}>
            <%= log_entry.end_at %>
          </:col>
        </.table>
        <PaginationComponent.pagination
          current_page={@current_page}
          language={@language}
          resource_path={~p"/tenants/#{@tenant.slug}/activities/#{@activity.id}/log_entries"}
          total_pages={@total_pages}
        />
      </div>
    </.side_and_topbar>
    """
  end

  @impl true
  def mount(_params, %{"language" => language} = _session, socket) do
    {:ok,
     socket
     |> assign(:language, language)
     |> stream(:log_entries, [])}
  end

  @impl true
  def handle_params(%{"slug" => slug, "id" => id} = params, _url, socket) do
    tenant = Tenant.by_slug!(slug, actor: socket.assigns.current_user)

    {:ok, activity} =
      id
      |> Activity.by_id!(actor: socket.assigns.current_user, tenant: tenant)
      |> Ash.load(:group, authorize?: false)

    {:noreply,
     socket
     |> assign(:group, activity.group)
     |> assign(:activity, activity)
     |> assign(:tenant, tenant)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(:page_title, with_locale(socket.assigns.language, fn -> gettext("Log entries") end))
    |> assign(:log_entry, nil)
    |> PaginationUtils.list_paginated(params, :log_entries, fn offset ->
      LogEntry.by_activity(%{activity_id: params["id"]},
        actor: socket.assigns.current_user,
        page: [count: true, offset: offset],
        tenant: socket.assigns.tenant
      )
    end)
  end
end
