defmodule OmedisWeb.OrganisationLive.Index do
  use OmedisWeb, :live_view
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
            {gettext("Home"), ~p"/", false},
            {gettext("Organisations"), ~p"/organisations", true}
          ]}
          language={@language}
        />

        <.header>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Listing Organisations") %>
          <% end) %>
          <:actions>
            <.link
              :if={Ash.can?({Organisation, :create}, @current_user)}
              patch={~p"/organisations/new"}
            >
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= gettext("New Organisation") %>
                <% end) %>
              </.button>
            </.link>
          </:actions>
        </.header>

        <div class="overflow-x-auto">
          <.table
            id="organisations"
            rows={@streams.organisations}
            row_click={fn {_id, organisation} -> JS.navigate(~p"/organisations/#{organisation}") end}
          >
            <:col :let={{_id, organisation}} label={with_locale(@language, fn -> gettext("Name") end)}>
              <%= organisation.name %>
              <%= if not is_nil(organisation.additional_info) and organisation.additional_info != "" do %>
                <br />
                <%= organisation.additional_info %>
              <% end %>
            </:col>
            <:col
              :let={{_id, organisation}}
              label={with_locale(@language, fn -> gettext("Street") end)}
            >
              <%= organisation.street %>
              <%= if not is_nil(organisation.street2) do %>
                <br />
                <%= organisation.street2 %>
              <% end %>

              <%= if not is_nil(organisation.po_box) do %>
                <br />
                <%= organisation.po_box %>
              <% end %>
            </:col>
            <:col
              :let={{_id, organisation}}
              label={with_locale(@language, fn -> gettext("Zip Code") end)}
            >
              <%= organisation.zip_code %>
            </:col>
            <:col :let={{_id, organisation}} label={with_locale(@language, fn -> gettext("City") end)}>
              <%= organisation.city %>
            </:col>
            <:col
              :let={{_id, organisation}}
              label={with_locale(@language, fn -> gettext("Canton") end)}
            >
              <%= organisation.canton %>
            </:col>
            <:col
              :let={{_id, organisation}}
              label={with_locale(@language, fn -> gettext("Country") end)}
            >
              <%= organisation.country %>
            </:col>
            <:action :let={{_id, organisation}}>
              <div class="sr-only">
                <.link navigate={~p"/organisations/#{organisation}"}>
                  <%= with_locale(@language, fn -> %>
                    <%= gettext("Show") %>
                  <% end) %>
                </.link>
              </div>
              <.link patch={~p"/organisations/#{organisation}/edit"}>
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Edit") %>
                <% end) %>
              </.link>
            </:action>
          </.table>
        </div>

        <.modal
          :if={@live_action in [:new, :edit]}
          id="organisation-modal"
          show
          on_cancel={JS.patch(~p"/organisations")}
        >
          <.live_component
            module={OmedisWeb.OrganisationLive.FormComponent}
            id={(@organisation && @organisation.slug) || :new}
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

  defp apply_action(socket, :edit, %{"slug" => slug}) do
    organisation = Organisation.by_slug!(slug, actor: socket.assigns.current_user)

    if Ash.can?({organisation, :update}, socket.assigns.current_user) do
      socket
      |> assign(
        :page_title,
        with_locale(socket.assigns.language, fn -> gettext("Edit Organisation") end)
      )
      |> assign(:organisation, organisation)
    else
      socket
      |> put_flash(:error, gettext("You are not authorized to access this page"))
      |> push_navigate(to: ~p"/organisations")
    end
  end

  defp apply_action(socket, :new, _params) do
    if Ash.can?({Organisation, :create}, socket.assigns.current_user) do
      socket
      |> assign(
        :page_title,
        with_locale(socket.assigns.language, fn -> gettext("New Organisation") end)
      )
      |> assign(:organisation, nil)
    else
      socket
      |> put_flash(:error, gettext("You are not authorized to access this page"))
      |> push_navigate(to: ~p"/organisations")
    end
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(
      :page_title,
      with_locale(socket.assigns.language, fn -> gettext("Listing Organisations") end)
    )
    |> assign(:organisation, nil)
    |> PaginationUtils.list_paginated(params, :organisations, fn offset ->
      Organisation.list_paginated(
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
