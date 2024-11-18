defmodule OmedisWeb.EventLive.Index do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Activity
  alias Omedis.Accounts.Event
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
            {dgettext("navigation", "Home"), ~p"/", false},
            {dgettext("navigation", "Organisations"), ~p"/organisations", false},
            {@organisation.name, ~p"/organisations/#{@organisation}", false},
            {dgettext("navigation", "Groups"), ~p"/organisations/#{@organisation}/groups", false},
            {@group.name, ~p"/organisations/#{@organisation}/groups/#{@group}", false},
            {dgettext("navigation", "Activities"),
             ~p"/organisations/#{@organisation}/groups/#{@group}/activities", false},
            {@activity.name,
             ~p"/organisations/#{@organisation}/groups/#{@group}/activities/#{@activity.id}", false},
            {dgettext("navigation", "Events"), "", true}
          ]}
          language={@language}
        />

        <.header>
          <span>
            <%= with_locale(@language, fn -> %>
              <%= dgettext("event", "Listing Events for") %>
            <% end) %>
          </span>
          <%= @activity.name %>
        </.header>

        <.table id="events" rows={@streams.events}>
          <:col
            :let={{_id, event}}
            label={with_locale(@language, fn -> dgettext("event", "Comment") end)}
          >
            <%= event.summary %>
          </:col>

          <:col
            :let={{_id, event}}
            label={with_locale(@language, fn -> dgettext("event", "Start at") end)}
          >
            <%= event.dtstart %>
          </:col>

          <:col
            :let={{_id, event}}
            label={with_locale(@language, fn -> dgettext("event", "End at") end)}
          >
            <%= event.dtend %>
          </:col>
        </.table>
        <PaginationComponent.pagination
          current_page={@current_page}
          language={@language}
          resource_path={~p"/organisations/#{@organisation}/activities/#{@activity.id}/events"}
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
     |> stream(:events, [])}
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
        dgettext("event", "Events")
      end)
    )
    |> assign(:event, nil)
    |> PaginationUtils.list_paginated(params, :events, fn offset ->
      Event.by_activity(%{activity_id: params["id"]},
        actor: socket.assigns.current_user,
        page: [count: true, offset: offset],
        tenant: socket.assigns.organisation
      )
    end)
  end
end
