defmodule OmedisWeb.TenantLive.FormComponent do
  use OmedisWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage tenant records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="tenant-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" /><.input
          field={@form[:street]}
          type="text"
          label="Street"
        /><.input field={@form[:zip_code]} type="text" label="Zip code" /><.input
          field={@form[:city]}
          type="text"
          label="City"
        /><.input field={@form[:country]} type="text" label="Country" /><.input
          field={@form[:owner_id]}
          type="text"
          label="Owner"
        /><.input field={@form[:additional_info]} type="text" label="Additional info" /><.input
          field={@form[:street2]}
          type="text"
          label="Street2"
        /><.input field={@form[:po_box]} type="text" label="Po box" /><.input
          field={@form[:canton]}
          type="text"
          label="Canton"
        /><.input field={@form[:phone]} type="text" label="Phone" /><.input
          field={@form[:fax]}
          type="text"
          label="Fax"
        /><.input field={@form[:email]} type="text" label="Email" /><.input
          field={@form[:website]}
          type="text"
          label="Website"
        /><.input field={@form[:zsr_number]} type="text" label="Zsr number" /><.input
          field={@form[:ean_gln]}
          type="text"
          label="Ean gln"
        /><.input field={@form[:uid_bfs_number]} type="text" label="Uid bfs number" /><.input
          field={@form[:trade_register_no]}
          type="text"
          label="Trade register no"
        /><.input field={@form[:bur_number]} type="text" label="Bur number" /><.input
          field={@form[:account_number]}
          type="text"
          label="Account number"
        />

        <:actions>
          <.button phx-disable-with="Saving...">Save Tenant</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_form()}
  end

  @impl true
  def handle_event("validate", %{"tenant" => tenant_params}, socket) do
    {:noreply, assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, tenant_params))}
  end

  def handle_event("save", %{"tenant" => tenant_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: tenant_params) |> IO.inspect() do
      {:ok, tenant} ->
        notify_parent({:saved, tenant})

        socket =
          socket
          |> put_flash(:info, "Tenant #{socket.assigns.form.source.type}d successfully")
          |> push_patch(to: socket.assigns.patch)

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{tenant: tenant}} = socket) do
    form =
      if tenant do
        AshPhoenix.Form.for_update(tenant, :update, as: "tenant")
      else
        AshPhoenix.Form.for_create(Omedis.Accounts.Tenant, :create, as: "tenant")
      end

    assign(socket, form: to_form(form))
  end
end
