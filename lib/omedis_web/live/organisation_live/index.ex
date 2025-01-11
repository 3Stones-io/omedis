defmodule OmedisWeb.OrganisationLive.Index do
  use OmedisWeb, :live_view

  alias Omedis.Accounts
  alias OmedisWeb.PaginationComponent
  alias OmedisWeb.PaginationUtils

  on_mount {OmedisWeb.LiveHelpers, :assign_and_broadcast_current_organisation}
  on_mount {OmedisWeb.LiveHelpers, :assign_default_pagination_assigns}

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
            {dgettext("navigation", "Organisations"), ~p"/organisations", true}
          ]}
          language={@language}
        />

        <.header>
          {dgettext("organisation", "Listing Organisations")}
        </.header>

        <div class="overflow-x-auto">
          <.table
            id="organisations"
            rows={@streams.organisations}
            row_click={fn {_id, organisation} -> JS.navigate(~p"/organisations/#{organisation}") end}
          >
            <:col :let={{_id, organisation}} label={dgettext("organisation", "Name")}>
              {organisation.name}
              <%= if not is_nil(organisation.additional_info) and organisation.additional_info != "" do %>
                <br />
                {organisation.additional_info}
              <% end %>
            </:col>
            <:col :let={{_id, organisation}} label={dgettext("organisation", "Street")}>
              {organisation.street}
              <%= if not is_nil(organisation.street2) do %>
                <br />
                {organisation.street2}
              <% end %>

              <%= if not is_nil(organisation.po_box) do %>
                <br />
                {organisation.po_box}
              <% end %>
            </:col>
            <:col :let={{_id, organisation}} label={dgettext("organisation", "Zip Code")}>
              {organisation.zip_code}
            </:col>
            <:col :let={{_id, organisation}} label={dgettext("organisation", "City")}>
              {organisation.city}
            </:col>
            <:col :let={{_id, organisation}} label={dgettext("organisation", "Canton")}>
              {organisation.canton}
            </:col>
            <:col :let={{_id, organisation}} label={dgettext("organisation", "Country")}>
              {organisation.country}
            </:col>
            <:action :let={{_id, organisation}}>
              <div class="sr-only">
                <.link navigate={~p"/organisations/#{organisation}"}>
                  {dgettext("organisation", "Show")}
                </.link>
              </div>
              <.link patch={~p"/organisations/#{organisation}/edit"}>
                {dgettext("organisation", "Edit")}
              </.link>
            </:action>
          </.table>
        </div>

        <.modal
          :if={@live_action == :edit}
          id="organisation-modal"
          show
          on_cancel={JS.patch(~p"/organisations")}
        >
          <.live_component
            module={OmedisWeb.OrganisationLive.FormComponent}
            id={@organisation && @organisation.slug}
            title={@page_title}
            action={@live_action}
            organisation={@organisation}
            current_user={@current_user}
            language={@language}
          />
        </.modal>
        <PaginationComponent.pagination
          current_page={@current_page}
          language={@language}
          resource_path={~p"/organisations"}
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
     |> stream(:organisations, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, _params) do
    organisation = socket.assigns.organisation

    if Ash.can?({organisation, :update}, socket.assigns.current_user) do
      assign(
        socket,
        :page_title,
        dgettext("organisation", "Edit Organisation")
      )
    else
      socket
      |> put_flash(
        :error,
        dgettext(
          "organisation",
          "You are not authorized to access this page"
        )
      )
      |> push_navigate(to: ~p"/organisations")
    end
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(
      :page_title,
      dgettext("organisation", "Listing Organisations")
    )
    |> assign(:organisation, nil)
    |> PaginationUtils.list_paginated(params, :organisations, fn offset ->
      Accounts.list_paginated_organisations(
        page: [count: true, offset: offset],
        actor: socket.assigns.current_user
      )
    end)
  end

  @impl true
  def handle_info({OmedisWeb.OrganisationLive.FormComponent, {:saved, organisation}}, socket) do
    {:noreply,
     socket
     |> assign(:organisations_count, socket.assigns.organisations_count + 1)
     |> stream_insert(:organisations, organisation)}
  end
end
