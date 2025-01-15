defmodule OmedisWeb.OrganisationLive.FormComponent do
  use OmedisWeb, :live_component

  alias AshPhoenix.Form

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        :let={f}
        for={@form}
        id="organisation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-3">
          <.input
            field={@form[:name]}
            type="text"
            label={
              Phoenix.HTML.raw(
                "#{dgettext("organisation", "Name")} <span class='text-red-600'>*</span>"
              )
            }
          />
        </div>

        <div class="space-y-3">
          <.input
            field={@form[:street]}
            type="text"
            label={
              Phoenix.HTML.raw(
                "#{dgettext("organisation", "Street")} <span class='text-red-600'>*</span>"
              )
            }
          />
        </div>

        <div class="space-y-3">
          <.input field={@form[:street2]} type="text" label={dgettext("organisation", "Street2")} />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:zip_code]}
            type="text"
            label={
              Phoenix.HTML.raw(
                "#{dgettext("organisation", "Zip Code")} <span class='text-red-600'>*</span>"
              )
            }
          />
          <.input field={@form[:city]} type="text" label={dgettext("organisation", "City")} />
        </div>
        <div class="space-y-3">
          <.input field={@form[:country]} type="text" label={dgettext("organisation", "Country")} />
        </div>

        <input type="hidden" value={@current_user.id} name="organisation[owner_id]" />
        <div class="space-y-3">
          <.input
            field={@form[:default_daily_start_at]}
            type="time"
            label={dgettext("organisation", "Daily Start At")}
            value={
              (@organisation && input_value(@form, :default_daily_start_at)) ||
                @current_user.daily_start_at
            }
          />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:default_daily_end_at]}
            type="time"
            label={dgettext("organisation", "Daily End At")}
            value={
              (@organisation && input_value(@form, :default_daily_end_at)) ||
                @current_user.daily_end_at
            }
          />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:additional_info]}
            type="text"
            label={dgettext("organisation", "Additional Info")}
          />
        </div>

        <div class="space-y-3">
          <.input field={@form[:po_box]} type="text" label={dgettext("organisation", "PO Box")} />
        </div>

        <div class="space-y-3">
          <.input field={@form[:canton]} type="text" label={dgettext("organisation", "Canton")} />
        </div>
        <div class="space-y-3">
          <.input field={@form[:phone]} type="text" label={dgettext("organisation", "Phone")} />
        </div>
        <div class="space-y-3">
          <.input field={@form[:fax]} type="text" label={dgettext("organisation", "Fax")} />
        </div>

        <div class="space-y-3">
          <.input field={@form[:email]} type="text" label={dgettext("organisation", "Email")} />
          <.error :for={msg <- get_field_errors(f[:email], :email)}>
            {"Email" <> " " <> msg}
          </.error>
        </div>

        <div class="space-y-3">
          <.input field={@form[:website]} type="text" label={dgettext("organisation", "Website")} />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:zsr_number]}
            type="text"
            label={dgettext("organisation", "ZSR Number")}
          />
          <.error :for={msg <- get_field_errors(f[:zsr_number], :zsr_number)}>
            {"Zsr_number" <> " " <> msg}
          </.error>
        </div>
        <div class="space-y-3">
          <.input field={@form[:ean_gln]} type="text" label={dgettext("organisation", "EAN/GLN")} />
        </div>

        <div class="space-y-3">
          <.input
            field={@form[:uid_bfs_number]}
            type="text"
            label={dgettext("organisation", "UID/BFS Number")}
          />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:trade_register_no]}
            type="text"
            label={dgettext("organisation", "Trade Register No")}
          />
        </div>
        <div class="space-y-3">
          <.input field={@form[:bank]} type="text" label={dgettext("organisation", "Bank")} />
        </div>
        <div class="space-y-3">
          <.input field={@form[:iban]} type="text" label={dgettext("organisation", "IBAN")} />
        </div>
        <div class="space-y-3">
          <.input field={@form[:bic]} type="text" label={dgettext("organisation", "BIC")} />
        </div>

        <div class="space-y-3">
          <.input
            field={@form[:account_number]}
            type="text"
            label={dgettext("organisation", "Account Number")}
          />
        </div>

        <:actions>
          <.button phx-disable-with={dgettext("organisation", "Saving...")}>
            {dgettext("organisation", "Save Organisation")}
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

  def handle_event("validate", %{"organisation" => organisation_params}, socket) do
    form = Form.validate(socket.assigns.form, organisation_params, errors: true)
    {:noreply, socket |> assign(form: form)}
  end

  def handle_event("save", %{"organisation" => organisation_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: organisation_params) do
      {:ok, organisation} ->
        notify_parent({:saved, organisation})

        socket =
          socket
          |> put_flash(
            :info,
            dgettext("organisation", "Organisation saved.")
          )
          |> push_navigate(to: path_for(socket.assigns.action, organisation))

        {:noreply, socket}

      {:error, form} ->
        {:noreply,
         socket
         |> assign(errors: Form.errors(form))
         |> assign(form: form)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{organisation: organisation}} = socket) do
    form =
      AshPhoenix.Form.for_update(organisation, :update,
        as: "organisation",
        actor: socket.assigns.current_user
      )

    assign(socket, form: to_form(form))
  end

  defp get_field_errors(field, _name) do
    Enum.map(field.errors, &translate_error(&1))
  end

  defp path_for(:edit, organisation), do: ~p"/organisations/#{organisation}"
end
