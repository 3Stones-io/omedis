defmodule OmedisWeb.TenantLive.Show do
  use OmedisWeb, :live_view
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
          {"Home", ~p"/", false},
          {"Tenants", ~p"/tenants", false},
          {@tenant.name, ~p"/tenants/#{@tenant.slug}", true}
        ]} />

        <.header>
          <%= @tenant.slug %>

          <:actions>
            <.link patch={~p"/tenants/#{@tenant.slug}/show/edit"} phx-click={JS.push_focus()}>
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Edit tenant") %>
                <% end) %>
              </.button>
            </.link>

            <.link patch={~p"/tenants/#{@tenant.slug}/projects"} phx-click={JS.push_focus()}>
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Projects") %>
                <% end) %>
              </.button>
            </.link>
            <.link patch={~p"/tenants/#{@tenant.slug}/groups"} phx-click={JS.push_focus()}>
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Groups") %>
                <% end) %>
              </.button>
            </.link>
          </:actions>
        </.header>

        <.list>
          <:item title={with_locale(@language, fn -> gettext("Slug") end)}><%= @tenant.slug %></:item>

          <:item title={with_locale(@language, fn -> gettext("Name") end)}><%= @tenant.name %></:item>

          <:item title={with_locale(@language, fn -> gettext("Owner") end)}>
            <%= @tenant.owner.as_string %>
          </:item>
          <:item title={with_locale(@language, fn -> gettext("Timezone") end)}>
            <%= @tenant.timezone %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Additional info") end)}>
            <%= @tenant.additional_info %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Street") end)}>
            <%= @tenant.street %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Street2") end)}>
            <%= @tenant.street2 %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Po box") end)}>
            <%= @tenant.po_box %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Zip code") end)}>
            <%= @tenant.zip_code %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("City") end)}><%= @tenant.city %></:item>

          <:item title={with_locale(@language, fn -> gettext("Canton") end)}>
            <%= @tenant.canton %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Country") end)}>
            <%= @tenant.country %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Description") end)}>
            <%= @tenant.description %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Phone") end)}>
            <%= @tenant.phone %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Fax") end)}>
            <%= @tenant.fax %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Email") end)}>
            <%= @tenant.email %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Website") end)}>
            <%= @tenant.website %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Zsr Number") end)}>
            <%= @tenant.zsr_number %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Ean gln") end)}>
            <%= @tenant.ean_gln %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Uid Bfs Number") end)}>
            <%= @tenant.uid_bfs_number %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Trade register no") end)}>
            <%= @tenant.trade_register_no %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Bur number") end)}>
            <%= @tenant.bur_number %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Account number") end)}>
            <%= @tenant.account_number %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Iban") end)}>
            <%= @tenant.iban %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Bic") end)}>
            <%= @tenant.bic %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Bank") end)}><%= @tenant.bank %></:item>

          <:item title={with_locale(@language, fn -> gettext("Account holder") end)}>
            <%= @tenant.account_holder %>
          </:item>
        </.list>

        <.back navigate={~p"/tenants"}>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Back to tenants") %>
          <% end) %>
        </.back>

        <.modal
          :if={@live_action == :edit}
          id="tenant-modal"
          show
          on_cancel={JS.patch(~p"/tenants/#{@tenant.slug}")}
        >
          <.live_component
            module={OmedisWeb.TenantLive.FormComponent}
            id={@tenant.id}
            title={@page_title}
            current_user={@current_user}
            action={@live_action}
            language={@language}
            tenant={@tenant}
            patch={~p"/tenants/#{@tenant.slug}"}
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
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action, socket.assigns.language))
     |> assign(:tenant, Tenant.by_slug!(slug))}
  end

  defp page_title(:show, language), do: with_locale(language, fn -> gettext("Show Tenant") end)
  defp page_title(:edit, language), do: with_locale(language, fn -> gettext("Edit Tenant") end)
end
