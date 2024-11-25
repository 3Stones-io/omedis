defmodule OmedisWeb.OrganisationLive.Show do
  use OmedisWeb, :live_view

  on_mount {OmedisWeb.LiveHelpers, :maybe_assign_organisation}

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
                <%= dgettext("organisation", "Edit organisation") %>
              </.button>
            </.link>
            <.link patch={~p"/organisations/#{@organisation}/invitations"} phx-click={JS.push_focus()}>
              <.button>
                <%= dgettext("organisation", "Invitations") %>
              </.button>
            </.link>
            <.link patch={~p"/organisations/#{@organisation}/projects"} phx-click={JS.push_focus()}>
              <.button>
                <%= dgettext("organisation", "Projects") %>
              </.button>
            </.link>
            <.link patch={~p"/organisations/#{@organisation}/groups"} phx-click={JS.push_focus()}>
              <.button>
                <%= dgettext("organisation", "Groups") %>
              </.button>
            </.link>

            <.link patch={~p"/organisations/#{@organisation}/today"} phx-click={JS.push_focus()}>
              <.button>
                <%= dgettext("organisation", "Today") %>
              </.button>
            </.link>
          </:actions>
        </.header>

        <.list>
          <:item title={dgettext("organisation", "Slug")}>
            <%= @organisation.slug %>
          </:item>

          <:item title={dgettext("organisation", "Name")}>
            <%= @organisation.name %>
          </:item>

          <:item title={dgettext("organisation", "Owner")}>
            <%= @organisation.owner.as_string %>
          </:item>

          <:item title={dgettext("organisation", "Timezone")}>
            <%= @organisation.timezone %>
          </:item>

          <:item title={dgettext("organisation", "Additional Info")}>
            <%= @organisation.additional_info %>
          </:item>

          <:item title={dgettext("organisation", "Street")}>
            <%= @organisation.street %>
          </:item>

          <:item title={dgettext("organisation", "Street2")}>
            <%= @organisation.street2 %>
          </:item>

          <:item title={dgettext("organisation", "PO Box")}>
            <%= @organisation.po_box %>
          </:item>

          <:item title={dgettext("organisation", "Zip Code")}>
            <%= @organisation.zip_code %>
          </:item>

          <:item title={dgettext("organisation", "City")}>
            <%= @organisation.city %>
          </:item>

          <:item title={dgettext("organisation", "Canton")}>
            <%= @organisation.canton %>
          </:item>

          <:item title={dgettext("organisation", "Country")}>
            <%= @organisation.country %>
          </:item>

          <:item title={dgettext("organisation", "Description")}>
            <%= @organisation.description %>
          </:item>

          <:item title={dgettext("organisation", "Phone")}>
            <%= @organisation.phone %>
          </:item>

          <:item title={dgettext("organisation", "Fax")}>
            <%= @organisation.fax %>
          </:item>

          <:item title={dgettext("organisation", "Email")}>
            <%= @organisation.email %>
          </:item>

          <:item title={dgettext("organisation", "Website")}>
            <%= @organisation.website %>
          </:item>

          <:item title={dgettext("organisation", "ZSR Number")}>
            <%= @organisation.zsr_number %>
          </:item>

          <:item title={dgettext("organisation", "EAN/GLN")}>
            <%= @organisation.ean_gln %>
          </:item>

          <:item title={dgettext("organisation", "UID/BFS Number")}>
            <%= @organisation.uid_bfs_number %>
          </:item>

          <:item title={dgettext("organisation", "Trade Register No")}>
            <%= @organisation.trade_register_no %>
          </:item>

          <:item title={dgettext("organisation", "BUR Number")}>
            <%= @organisation.bur_number %>
          </:item>

          <:item title={dgettext("organisation", "Account Number")}>
            <%= @organisation.account_number %>
          </:item>

          <:item title={dgettext("organisation", "IBAN")}>
            <%= @organisation.iban %>
          </:item>

          <:item title={dgettext("organisation", "BIC")}>
            <%= @organisation.bic %>
          </:item>

          <:item title={dgettext("organisation", "Bank")}>
            <%= @organisation.bank %>
          </:item>

          <:item title={dgettext("organisation", "Account Holder")}>
            <%= @organisation.account_holder %>
          </:item>
        </.list>

        <.back navigate={~p"/organisations"}>
          <%= dgettext("organisation", "Back to organisations") %>
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
  def handle_params(_params, _, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action)}
  end

  defp apply_action(socket, :show) do
    assign(socket, :page_title, page_title(:show))
  end

  defp apply_action(socket, :edit) do
    if Ash.can?({socket.assigns.organisation, :update}, socket.assigns.current_user) do
      assign(socket, :page_title, page_title(:edit))
    else
      socket
      |> put_flash(
        :error,
        dgettext(
          "organisation",
          "You are not authorized to access this page"
        )
      )
      |> push_navigate(to: ~p"/organisations/#{socket.assigns.organisation}")
    end
  end

  defp page_title(:show), do: dgettext("organisation", "Show Organisation")

  defp page_title(:edit), do: dgettext("organisation", "Edit Organisation")
end
