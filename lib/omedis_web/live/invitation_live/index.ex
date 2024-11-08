defmodule OmedisWeb.InvitationLive.Index do
  use OmedisWeb, :live_view

  alias Omedis.Accounts.Invitation
  alias Omedis.Accounts.Organisation

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    organisation = Organisation.by_slug!(slug, actor: socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:organisation, organisation)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    if Ash.can?({Invitation, :create}, socket.assigns.current_user,
         tenant: socket.assigns.organisation
       ) do
      socket
      |> assign(
        :page_title,
        with_locale(
          socket.assigns.language,
          fn -> gettext("New Invitation") end
        )
      )
      |> assign(:invitation, nil)
    else
      # FIX: Redirect to the invitations index page
      push_navigate(socket, to: ~p"/organisations/#{socket.assigns.organisation}")
    end
  end

  defp apply_action(socket, _, _params) do
    socket
    |> push_navigate(to: ~p"/organisations/#{socket.assigns.organisation}/invitations/new")
  end

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
            {gettext("Organisations"), ~p"/organisations", false},
            {@organisation.name, ~p"/organisations/#{@organisation}", false},
            {gettext("Invitations"), "", true}
          ]}
          language={@language}
        />

        <.header>
          <%= @page_title %>
        </.header>

        <.modal
          :if={@live_action in [:new]}
          id="invitation-modal"
          show
          on_cancel={JS.patch(~p"/organisations/#{@organisation}")}
        >
          <.live_component
            module={OmedisWeb.InvitationLive.FormComponent}
            id={:new}
            title={@page_title}
            action={@live_action}
            organisation={@organisation}
            language={@language}
            current_user={@current_user}
            patch={~p"/organisations/#{@organisation}"}
          />
        </.modal>
      </div>
    </.side_and_topbar>
    """
  end
end
