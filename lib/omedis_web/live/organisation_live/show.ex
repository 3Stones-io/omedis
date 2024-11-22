defmodule OmedisWeb.OrganisationLive.Show do
  use OmedisWeb, :live_view

  on_mount {OmedisWeb.LiveHelpers, :assign_and_broadcast_current_organisation}

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
            {with_locale(@language, fn -> dgettext("navigation", "Home") end), ~p"/", false},
            {with_locale(@language, fn -> dgettext("navigation", "Organisations") end),
             ~p"/organisations", false},
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
                  <%= dgettext("organisation", "Edit organisation") %>
                <% end) %>
              </.button>
            </.link>
            <.link patch={~p"/organisations/#{@organisation}/invitations"} phx-click={JS.push_focus()}>
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= dgettext("organisation", "Invitations") %>
                <% end) %>
              </.button>
            </.link>
            <.link patch={~p"/organisations/#{@organisation}/projects"} phx-click={JS.push_focus()}>
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= dgettext("organisation", "Projects") %>
                <% end) %>
              </.button>
            </.link>
            <.link patch={~p"/organisations/#{@organisation}/groups"} phx-click={JS.push_focus()}>
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= dgettext("organisation", "Groups") %>
                <% end) %>
              </.button>
            </.link>

            <.link patch={~p"/organisations/#{@organisation}/today"} phx-click={JS.push_focus()}>
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= dgettext("organisation", "Today") %>
                <% end) %>
              </.button>
            </.link>
          </:actions>
        </.header>

        <.list>
          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "Slug")
            end)
          }>
            <%= @organisation.slug %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "Name")
            end)
          }>
            <%= @organisation.name %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "Owner")
            end)
          }>
            <%= @organisation.owner.as_string %>
          </:item>
          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "Timezone")
            end)
          }>
            <%= @organisation.timezone %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "Additional Info")
            end)
          }>
            <%= @organisation.additional_info %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "Street")
            end)
          }>
            <%= @organisation.street %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "Street2")
            end)
          }>
            <%= @organisation.street2 %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "PO Box")
            end)
          }>
            <%= @organisation.po_box %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "Zip Code")
            end)
          }>
            <%= @organisation.zip_code %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "City")
            end)
          }>
            <%= @organisation.city %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "Canton")
            end)
          }>
            <%= @organisation.canton %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "Country")
            end)
          }>
            <%= @organisation.country %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "Description")
            end)
          }>
            <%= @organisation.description %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "Phone")
            end)
          }>
            <%= @organisation.phone %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "Fax")
            end)
          }>
            <%= @organisation.fax %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "Email")
            end)
          }>
            <%= @organisation.email %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "Website")
            end)
          }>
            <%= @organisation.website %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "ZSR Number")
            end)
          }>
            <%= @organisation.zsr_number %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "EAN/GLN")
            end)
          }>
            <%= @organisation.ean_gln %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "UID/BFS Number")
            end)
          }>
            <%= @organisation.uid_bfs_number %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "Trade Register No")
            end)
          }>
            <%= @organisation.trade_register_no %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "BUR Number")
            end)
          }>
            <%= @organisation.bur_number %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "Account Number")
            end)
          }>
            <%= @organisation.account_number %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "IBAN")
            end)
          }>
            <%= @organisation.iban %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "BIC")
            end)
          }>
            <%= @organisation.bic %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "Bank")
            end)
          }>
            <%= @organisation.bank %>
          </:item>

          <:item title={
            with_locale(@language, fn ->
              dgettext("organisation", "Account Holder")
            end)
          }>
            <%= @organisation.account_holder %>
          </:item>
        </.list>

        <.back navigate={~p"/organisations"}>
          <%= with_locale(@language, fn -> %>
            <%= dgettext("organisation", "Back to organisations") %>
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
  def handle_params(_params, _, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action)}
  end

  defp apply_action(socket, :show) do
    assign(socket, :page_title, page_title(:show, socket.assigns.language))
  end

  defp apply_action(socket, :edit) do
    if Ash.can?({socket.assigns.organisation, :update}, socket.assigns.current_user) do
      assign(socket, :page_title, page_title(:edit, socket.assigns.language))
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

  defp page_title(:show, language) do
    with_locale(language, fn ->
      dgettext("organisation", "Show Organisation")
    end)
  end

  defp page_title(:edit, language) do
    with_locale(language, fn ->
      dgettext("organisation", "Edit Organisation")
    end)
  end
end
