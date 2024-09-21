defmodule OmedisWeb.TenantLive.Today do
  use OmedisWeb, :live_view
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
    {:ok,
     socket
     |> assign(:categories, categories())
     |> assign(:current_time, ~T[10:00:00])}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Today")
     |> assign(:tenant, Tenant.by_slug!(slug))}
  end

  defp categories do
    [
      %{
        color_code: "#3F88C5",
        name: "Category 1",
        entries: [
          %{
            starts_at: ~T[08:00:00],
            ends_at: ~T[08:10:00]
          },
          %{
            starts_at: ~T[09:01:00],
            ends_at: ~T[09:55:00]
          }
        ]
      },
      %{
        color_code: "#D58936",
        name: "Category 2",
        entries: [
          %{
            starts_at: ~T[08:11:00],
            ends_at: ~T[09:00:00]
          }
        ]
      },
      %{
        color_code: "#881D36",
        name: "Category 3",
        entries: [
          %{
            starts_at: ~T[09:56:00],
            ends_at: ~T[11:15:00]
          }
        ]
      },
      %{
        color_code: "#82AA60",
        name: "Category 4",
        entries: []
      },
      %{
        color_code: "#FF9960",
        name: "Category 5",
        entries: []
      }
    ]
  end
end
