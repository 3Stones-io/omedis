defmodule OmedisWeb.GroupLive.Show do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Group
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
            {@organisation.name, ~p"/organisations/#{@organisation}", false},
            {pgettext("navigation", "Groups"), ~p"/organisations/#{@organisation}/groups", false},
            {@group.name, "", true}
          ]}
          language={@language}
        />

        <.header>
          <:actions>
            <.link
              patch={~p"/organisations/#{@organisation}/groups/#{@group}/activities"}
              phx-click={JS.push_focus()}
            >
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= pgettext("navigation", "Activities") %>
                <% end) %>
              </.button>
            </.link>
          </:actions>
        </.header>

        <.list>
          <:item title={with_locale(@language, fn -> pgettext("form", "Name") end)}>
            <%= @group.name %>
          </:item>
          <:item title={with_locale(@language, fn -> pgettext("form", "Slug") end)}>
            <%= @group.slug %>
          </:item>
        </.list>

        <.back navigate={~p"/organisations/#{@organisation}/groups"}>
          <%= with_locale(@language, fn -> %>
            <%= pgettext("navigation", "Back to groups") %>
          <% end) %>
        </.back>

        <.modal
          :if={@live_action == :edit}
          id="group-modal"
          show
          on_cancel={JS.patch(~p"/organisations/#{@organisation}/groups/#{@group}")}
        >
          <.live_component
            module={OmedisWeb.GroupLive.FormComponent}
            id={@group.id}
            title={@page_title}
            action={@live_action}
            organisation={@organisation}
            language={@language}
            group={@group}
            patch={~p"/organisations/#{@organisation}/groups/#{@group}"}
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
     |> assign(:language, language)
     |> assign(:page_title, page_title(socket.assigns.live_action, language))}
  end

  @impl true
  def handle_params(%{"slug" => slug, "group_slug" => group_slug}, _, socket) do
    organisation = Organisation.by_slug!(slug, actor: socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action, socket.assigns.language))
     |> assign(:organisation, organisation)
     |> assign(
       :group,
       Group.by_slug!(group_slug, actor: socket.assigns.current_user, tenant: organisation)
     )}
  end

  defp page_title(:show, language),
    do: with_locale(language, fn -> pgettext("page_title", "Show Organisation") end)

  defp page_title(:edit, language),
    do: with_locale(language, fn -> pgettext("page_title", "Edit Organisation") end)
end
