defmodule OmedisWeb.LogEntryLive.Index do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Activity
  alias Omedis.Accounts.LogEntry
  alias Omedis.Accounts.Organisation
  alias OmedisWeb.PaginationComponent
  alias OmedisWeb.PaginationUtils

  on_mount {OmedisWeb.LiveHelpers, :assign_default_pagination_assigns}

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
            {@activity.name,
             ~p"/organisations/#{@organisation}/groups/#{@group}/activities/#{@activity.id}", false},
            {pgettext("navigation", "Log Entries"), "", true}
          ]}
          language={@language}
        />

        <.header>
          <span>
            <%= with_locale(@language, fn -> %>
              <%= pgettext("page_title", "Listing Log entries for") %>
            <% end) %>
          </span>
          <%= @activity.name %>
        </.header>

        <.table id="log_entries" rows={@streams.log_entries}>
          <:col
            :let={{_id, log_entry}}
            label={with_locale(@language, fn -> pgettext("table", "Comment") end)}
          >
            <%= log_entry.comment %>
          </:col>

          <:col
            :let={{_id, log_entry}}
            label={with_locale(@language, fn -> pgettext("table", "Start at") end)}
          >
            <%= log_entry.start_at %>
          </:col>

          <:col
            :let={{_id, log_entry}}
            label={with_locale(@language, fn -> pgettext("table", "End at") end)}
          >
            <%= log_entry.end_at %>
          </:col>
        </.table>
        <PaginationComponent.pagination
          current_page={@current_page}
          language={@language}
          resource_path={~p"/organisations/#{@organisation}/activities/#{@activity.id}/log_entries"}
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
    organisation = Organisation.by_slug!(slug, actor: socket.assigns.current_user)

    {:ok, activity} =
      id
      |> Activity.by_id!(actor: socket.assigns.current_user, tenant: organisation)
      |> Ash.load(:group, authorize?: false)

    {:noreply,
     socket
     |> assign(:activity, activity)
     |> assign(:group, activity.group)
     |> assign(:organisation, organisation)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(
      :page_title,
      with_locale(socket.assigns.language, fn ->
        pgettext("page_title", "Log entries")
      end)
    )
    |> assign(:log_entry, nil)
    |> PaginationUtils.list_paginated(params, :log_entries, fn offset ->
      LogEntry.by_activity(%{activity_id: params["id"]},
        actor: socket.assigns.current_user,
        page: [count: true, offset: offset],
        tenant: socket.assigns.organisation
      )
    end)
  end
end
