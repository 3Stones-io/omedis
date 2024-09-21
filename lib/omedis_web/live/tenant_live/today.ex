defmodule OmedisWeb.TenantLive.Today do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.LogCategory
  alias Omedis.Accounts.Tenant

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.dashboard_component
        categories={@categories}
        starts_at={~T[08:00:00]}
        ends_at={~T[17:00:00]}
        current_time={@current_time}
      />
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _, socket) do
    tenant = Tenant.by_slug!(slug)

    {:noreply,
     socket
     |> assign(:page_title, "Today")
     |> assign(:tenant, tenant)
     |> assign(:current_time, Time.utc_now())
     |> assign(:categories, categories(tenant.id))}
  end

  defp categories(tenant_id) do
    case LogCategory.by_tenant_id(%{tenant_id: tenant_id}) do
      {:ok, categories} ->
        categories

      _ ->
        []
    end
  end
end
