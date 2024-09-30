defmodule OmedisWeb.GroupLive.Show do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Group
  alias Omedis.Accounts.Tenant

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <:actions>
        <.link
          patch={~p"/tenants/#{@tenant.slug}/groups/#{@group.id}/log_categories"}
          phx-click={JS.push_focus()}
        >
          <.button>
            <%= with_locale(@language, fn -> %>
              <%= gettext("Log categories") %>
            <% end) %>
          </.button>
        </.link>
        <.link
          patch={~p"/tenants/#{@tenant.slug}/groups/#{@group.id}/show/edit"}
          phx-click={JS.push_focus()}
        >
          <.button>
            <%= with_locale(@language, fn -> %>
              <%= gettext("Edit Group") %>
            <% end) %>
          </.button>
        </.link>

        <%!-- <.link navigate={~p"/tenants/#{@tenant.slug}/today"} phx-click={JS.push_focus()}>
          <.button>
            <%= with_locale(@language, fn -> %>
              <%= gettext("Today") %>
            <% end) %>
          </.button>
        </.link> --%>
      </:actions>
    </.header>

    <.list>
      <:item title={with_locale(@language, fn -> gettext("Name") end)}><%= @group.name %></:item>
      <:item title={with_locale(@language, fn -> gettext("Slug") end)}><%= @group.slug %></:item>
    </.list>

    <%!-- <.back navigate={~p"/tenants"}>
      <%= with_locale(@language, fn -> %>
        <%= gettext("Back to tenants") %>
      <% end) %>
    </.back> --%>

    <.modal
      :if={@live_action == :edit}
      id="group-modal"
      show
      on_cancel={JS.patch(~p"/tenants/#{@tenant.slug}/groups/#{@group}")}
    >
      <.live_component
        module={OmedisWeb.GroupLive.FormComponent}
        id={@group.id}
        title={@page_title}
        action={@live_action}
        tenant={@tenant}
        language={@language}
        group={@group}
        patch={~p"/tenants/#{@tenant.slug}/groups/#{@group}"}
      />
    </.modal>
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
  def handle_params(%{"slug" => slug, "group_id" => group_id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action, socket.assigns.language))
     |> assign(:tenant, Tenant.by_slug!(slug))
     |> assign(:group, Group.by_id!(group_id))}
  end

  defp page_title(:show, language), do: with_locale(language, fn -> gettext("Show Tenant") end)
  defp page_title(:edit, language), do: with_locale(language, fn -> gettext("Edit Tenant") end)
end
