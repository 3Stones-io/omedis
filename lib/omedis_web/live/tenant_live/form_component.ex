defmodule OmedisWeb.TenantLive.FormComponent do
  use OmedisWeb, :live_component
  alias AshPhoenix.Form
  alias Omedis.Accounts.Tenant

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        :let={f}
        for={@form}
        id="tenant-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-3">
          <.input
            field={@form[:name]}
            type="text"
            label={Phoenix.HTML.raw("Name <span class='text-red-600'>*</span>")}
          /><.input
            field={@form[:street]}
            type="text"
            label={Phoenix.HTML.raw("Street <span class='text-red-600'>*</span>")}
          />
        </div>

        <div class="space-y-3">
          <.input field={@form[:street2]} type="text" label="Street2" />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:zip_code]}
            type="text"
            label={Phoenix.HTML.raw("Zip Code <span class='text-red-600'>*</span>")}
          /><.input
            field={@form[:city]}
            type="text"
            label={Phoenix.HTML.raw("City <span class='text-red-600'>*</span>")}
          />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:country]}
            type="text"
            label={Phoenix.HTML.raw("Country <span class='text-red-600'>*</span>")}
          />
        </div>

        <input type="hidden" value={@current_user.id} name="tenant[owner_id]" />
        <div class="space-y-3">
          <.input field={@form[:daily_start_at]} type="time" label="Daily Start At" />
        </div>
        <div class="space-y-3">
          <.input field={@form[:daily_end_at]} type="time" label="Daily End At" />
        </div>
        <div class="space-y-3">
          <.input field={@form[:additional_info]} type="text" label="Additional info" />
        </div>

        <div class="space-y-3">
          <.input field={@form[:po_box]} type="text" label="Po box" />
        </div>

        <div class="space-y-3">
          <.input field={@form[:canton]} type="text" label="Canton" />
        </div>
        <div class="space-y-3">
          <.input field={@form[:phone]} type="text" label="Phone" />
        </div>
        <div class="space-y-3">
          <.input field={@form[:fax]} type="text" label="Fax" />
        </div>

        <div class="space-y-3">
          <.input field={@form[:email]} type="text" label="Email" />
          <.error :for={msg <- get_field_errors(f[:email], :email)}>
            <%= "Email" <> " " <> msg %>
          </.error>
        </div>

        <div class="space-y-3">
          <.input field={@form[:website]} type="text" label="Website" />
        </div>
        <div class="space-y-3">
          <.input field={@form[:zsr_number]} type="text" label="Zsr number" />
          <.error :for={msg <- get_field_errors(f[:zsr_number], :zsr_number)}>
            <%= "Zsr_number" <> " " <> msg %>
          </.error>
        </div>
        <div class="space-y-3">
          <.input field={@form[:ean_gln]} type="text" label="Ean gln" />
        </div>

        <div class="space-y-3">
          <.input field={@form[:uid_bfs_number]} type="text" label="Uid bfs number" />
        </div>
        <div class="space-y-3">
          <.input field={@form[:trade_register_no]} type="text" label="Trade register no" />
        </div>
        <div class="space-y-3">
          <.input field={@form[:bank]} type="text" label="Bank" />
        </div>
        <div class="space-y-3">
          <.input field={@form[:iban]} type="text" label="Iban" />
        </div>
        <div class="space-y-3">
          <.input field={@form[:bic]} type="text" label="Bic" />
        </div>

        <div class="space-y-3">
          <.input field={@form[:account_number]} type="text" label="Account number" />
        </div>

        <:actions>
          <.button phx-disable-with="Saving...">
            Save Tenant
          </.button>
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
     |> assign(:errors, [])
     |> assign_form()}
  end

  @impl true
  def handle_event("validate", %{"tenant" => tenant_params}, socket) do
    form = Form.validate(socket.assigns.form, tenant_params, errors: true)
    {:noreply, socket |> assign(form: form)}
  end

  def handle_event("save", %{"tenant" => tenant_params}, socket) do
    new_tenant_params =
      tenant_params
      |> Map.put("slug", Slug.slugify(update_slug(tenant_params["name"])))

    case AshPhoenix.Form.submit(socket.assigns.form, params: new_tenant_params) do
      {:ok, tenant} ->
        notify_parent({:saved, tenant})

        socket =
          socket
          |> put_flash(:info, "Tenant #{socket.assigns.form.source.type}d successfully")
          |> push_patch(to: socket.assigns.patch)

        {:noreply, socket}

      {:error, form} ->
        {:noreply,
         socket
         |> assign(errors: Form.errors(form))
         |> assign(form: form)}
    end
  end

  defp generate_unique_slug(base_slug) do
    new_slug = "#{base_slug}#{:rand.uniform(99)}"

    case Tenant.slug_exists?(new_slug) do
      true -> generate_unique_slug(base_slug)
      false -> new_slug
    end
  end

  defp update_slug(slug) do
    case Tenant.slug_exists?(slug) do
      true -> generate_unique_slug(slug)
      false -> slug
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
