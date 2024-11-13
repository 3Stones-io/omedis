defmodule OmedisWeb.OrganisationLive.Show do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Organisation

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
            {@organisation.name, ~p"/organisations/#{@organisation}", true}
          ]}
          language={@language}
        />

        <.header>
          <%= @organisation.slug %>

          <:actions>
            <.link
              :if={Ash.can?({@organisation, :update}, @current_user)}
              patch={~p"/organisations/#{@organisation}/show/edit"}
              phx-click={JS.push_focus()}
            >
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= pgettext("action", "Edit organisation") %>
                <% end) %>
              </.button>
            </.link>
            <.link patch={~p"/organisations/#{@organisation}/invitations"} phx-click={JS.push_focus()}>
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= pgettext("action", "Invitations") %>
                <% end) %>
              </.button>
            </.link>
            <.link patch={~p"/organisations/#{@organisation}/projects"} phx-click={JS.push_focus()}>
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= pgettext("action", "Projects") %>
                <% end) %>
              </.button>
            </.link>
            <.link patch={~p"/organisations/#{@organisation}/groups"} phx-click={JS.push_focus()}>
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= pgettext("action", "Groups") %>
                <% end) %>
              </.button>
            </.link>

            <.link patch={~p"/organisations/#{@organisation}/today"} phx-click={JS.push_focus()}>
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= pgettext("action", "Today") %>
                <% end) %>
              </.button>
            </.link>
          </:actions>
        </.header>

        <.list>
          <:item title={with_locale(@language, fn -> pgettext("form", "Slug") end)}>
            <%= @organisation.slug %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Name") end)}>
            <%= @organisation.name %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Owner") end)}>
            <%= @organisation.owner.as_string %>
          </:item>
          <:item title={with_locale(@language, fn -> pgettext("form", "Timezone") end)}>
            <%= @organisation.timezone %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Additional info") end)}>
            <%= @organisation.additional_info %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Street") end)}>
            <%= @organisation.street %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Street2") end)}>
            <%= @organisation.street2 %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Po box") end)}>
            <%= @organisation.po_box %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Zip code") end)}>
            <%= @organisation.zip_code %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "City") end)}>
            <%= @organisation.city %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Canton") end)}>
            <%= @organisation.canton %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Country") end)}>
            <%= @organisation.country %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Description") end)}>
            <%= @organisation.description %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Phone") end)}>
            <%= @organisation.phone %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Fax") end)}>
            <%= @organisation.fax %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Email") end)}>
            <%= @organisation.email %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Website") end)}>
            <%= @organisation.website %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Zsr Number") end)}>
            <%= @organisation.zsr_number %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Ean gln") end)}>
            <%= @organisation.ean_gln %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Uid Bfs Number") end)}>
            <%= @organisation.uid_bfs_number %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Trade register no") end)}>
            <%= @organisation.trade_register_no %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Bur number") end)}>
            <%= @organisation.bur_number %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Account number") end)}>
            <%= @organisation.account_number %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Iban") end)}>
            <%= @organisation.iban %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Bic") end)}>
            <%= @organisation.bic %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Bank") end)}>
            <%= @organisation.bank %>
          </:item>

          <:item title={with_locale(@language, fn -> pgettext("form", "Account holder") end)}>
            <%= @organisation.account_holder %>
          </:item>
        </.list>

        <.back navigate={~p"/organisations"}>
          <%= with_locale(@language, fn -> %>
            <%= pgettext("navigation", "Back to organisations") %>
          <% end) %>
        </.back>

        <.modal
          :if={@live_action == :edit}
          id="organisation-modal"
          show
          on_cancel={JS.patch(~p"/organisations/#{@organisation}")}
        >
          <.live_component
            module={OmedisWeb.OrganisationLive.FormComponent}
            id={@organisation.id}
            title={@page_title}
            current_user={@current_user}
            action={@live_action}
            language={@language}
            organisation={@organisation}
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
  def handle_params(%{"slug" => slug}, _, socket) do
    organisation = Organisation.by_slug!(slug, actor: socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(:organisation, organisation)
     |> apply_action(socket.assigns.live_action)}
  end

  defp apply_action(socket, :show) do
    assign(socket, :page_title, page_title(:show, socket.assigns.language))
  end

  defp apply_action(socket, :edit) do
    if Ash.can?({socket.assigns.organisation, :update}, socket.assigns.current_user) do
      assign(socket, :page_title, page_title(:edit, socket.assigns.language))
    else
      socket
      |> put_flash(:error, pgettext("auth", "You are not authorized to access this page"))
      |> push_navigate(to: ~p"/organisations/#{socket.assigns.organisation}")
    end
  end

  defp page_title(:show, language) do
    with_locale(language, fn -> pgettext("page_title", "Show Organisation") end)
  end

  defp page_title(:edit, language) do
    with_locale(language, fn -> pgettext("page_title", "Edit Organisation") end)
  end
end
