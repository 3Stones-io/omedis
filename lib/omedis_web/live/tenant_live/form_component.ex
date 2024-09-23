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
        <div class="space-y-3">
          <.input field={@form[:slug]} type="text" label="Slug" />
          <.error :for={msg <- get_field_errors(f[:slug], :slug)}>
            <%= "Slug" <> " " <> msg %>
          </.error>
        </div>
        <div class="space-y-3">
          <.input field={@form[:name]} type="text" label="Name" /><.input
            field={@form[:street]}
            type="text"
            label="Street"
          />
          <.error :for={msg <- get_field_errors(f[:street], :street)}>
            <%= "Street" <> " " <> msg %>
          </.error>
        </div>
        <div class="space-y-3">
          <.input field={@form[:zip_code]} type="text" label="Zip code" /><.input
            field={@form[:city]}
            type="text"
            label="City"
          />
          <.error :for={msg <- get_field_errors(f[:city], :city)}>
            <%= "City" <> " " <> msg %>
          </.error>
        </div>
        <div class="space-y-3">
          <.input field={@form[:country]} type="text" label="Country" />
          <.error :for={msg <- get_field_errors(f[:country], :country)}>
            <%= "Country" <> " " <> msg %>
          </.error>
        </div>

        <input type="hidden" value={@current_user.id} name="tenant[owner_id]" />
        <div class="space-y-3">
          <.input field={@form[:daily_start_at]} type="time" label="Daily Start At" />
          <.error :for={msg <- get_field_errors(f[:daily_start_at], :daily_start_at)}>
            <%= "Daily Start At" <> " " <> msg %>
          </.error>
        </div>
        <div class="space-y-3">
          <.input field={@form[:daily_end_at]} type="time" label="Daily End At" />
          <.error :for={msg <- get_field_errors(f[:daily_end_at], :daily_end_at)}>
            <%= "Daily End At" <> " " <> msg %>
          </.error>
        </div>
        <div class="space-y-3">
          <.input field={@form[:additional_info]} type="text" label="Additional info" />
          <.error :for={msg <- get_field_errors(f[:additional_info], :additional_info)}>
            <%= "Additional Info" <> " " <> msg %>
          </.error>
        </div>
        <div class="space-y-3">
          <.input field={@form[:street2]} type="text" label="Street2" />

          <.error :for={msg <- get_field_errors(f[:street2], :street2)}>
            <%= "Street 2" <> " " <> msg %>
          </.error>
        </div>
        <div class="space-y-3">
          <.input field={@form[:po_box]} type="text" label="Po box" />
          <.error :for={msg <- get_field_errors(f[:po_box], :po_box)}>
            <%= "PO Box" <> " " <> msg %>
          </.error>
        </div>

        <div class="space-y-3">
          <.input field={@form[:canton]} type="text" label="Canton" />
          <.error :for={msg <- get_field_errors(f[:canton], :canton)}>
            <%= "Canton" <> " " <> msg %>
          </.error>
        </div>
        <div class="space-y-3">
          <.input field={@form[:phone]} type="text" label="Phone" />
          <.error :for={msg <- get_field_errors(f[:phone], :phone)}>
            <%= "Phone" <> " " <> msg %>
          </.error>
        </div>
        <div class="space-y-3">
          <.input field={@form[:fax]} type="text" label="Fax" />
          <.error :for={msg <- get_field_errors(f[:fax], :fax)}>
            <%= "Fax" <> " " <> msg %>
          </.error>
        </div>

        <div class="space-y-3">
          <.input field={@form[:email]} type="text" label="Email" />
          <.error :for={msg <- get_field_errors(f[:email], :email)}>
            <%= "Email" <> " " <> msg %>
          </.error>
        </div>

        <div class="space-y-3">
          <.input field={@form[:website]} type="text" label="Website" />
          <.error :for={msg <- get_field_errors(f[:website], :website)}>
            <%= "Website" <> " " <> msg %>
          </.error>
        </div>
        <div class="space-y-3">
          <.input field={@form[:zsr_number]} type="text" label="Zsr number" />
          <.error :for={msg <- get_field_errors(f[:zsr_number], :zsr_number)}>
            <%= "Zsr_number" <> " " <> msg %>
          </.error>
        </div>
        <div class="space-y-3">
          <.input field={@form[:ean_gln]} type="text" label="Ean gln" />
          <.error :for={msg <- get_field_errors(f[:ean_gln], :ean_gln)}>
            <%= "Ean gln" <> " " <> msg %>
          </.error>
        </div>

        <div class="space-y-3">
          <.input field={@form[:uid_bfs_number]} type="text" label="Uid bfs number" />
          <.error :for={msg <- get_field_errors(f[:uid_bfs_number], :uid_bfs_number)}>
            <%= "uid bfs number" <> " " <> msg %>
          </.error>
        </div>
        <div class="space-y-3">
          <.input field={@form[:trade_register_no]} type="text" label="Trade register no" />
          <.error :for={msg <- get_field_errors(f[:trade_register_no], :trade_register_no)}>
            <%= "Trade register no" <> " " <> msg %>
          </.error>
        </div>
        <div class="space-y-3">
          <.input field={@form[:bur_number]} type="text" label="Bur number" />
          <.error :for={msg <- get_field_errors(f[:bur_number], :bur_number)}>
            <%= "Bur Number" <> " " <> msg %>
          </.error>
        </div>
        <div class="space-y-3">
          <.input field={@form[:account_number]} type="text" label="Account number" />
          <.error :for={msg <- get_field_errors(f[:account_number], :account_number)}>
            <%= "Account Number" <> " " <> msg %>
          </.error>
        </div>

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
    tenant_params =
      if Map.has_key?(tenant_params, "slug") do
        Map.update!(tenant_params, "slug", &Slug.slugify/1)
      else
        tenant_params
      end

    case AshPhoenix.Form.submit(socket.assigns.form, params: tenant_params) do
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

  defp get_field_errors(field, _name) do
    Enum.map(field.errors, &translate_error(&1))
  end
end
