defmodule OmedisWeb.OrganisationLive.FormComponent do
  use OmedisWeb, :live_component
  alias AshPhoenix.Form
  alias Omedis.Accounts.Organisation

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
                "#{with_locale(@language, fn -> gettext("Name") end)} <span class='text-red-600'>*</span>"
              )
            }
          />
        </div>

        <div class="space-y-3">
          <.input
            field={@form[:slug]}
            type="text"
            label={
              Phoenix.HTML.raw(
                "#{with_locale(@language, fn -> gettext("Slug") end)} <span class='text-red-600'>*</span>"
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
                "#{with_locale(@language, fn -> gettext("Street") end)} <span class='text-red-600'>*</span>"
              )
            }
          />
        </div>

        <div class="space-y-3">
          <.input
            field={@form[:street2]}
            type="text"
            label={with_locale(@language, fn -> gettext("Street2") end)}
          />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:zip_code]}
            type="text"
            label={
              Phoenix.HTML.raw(
                "#{with_locale(@language, fn -> gettext("Zip code") end)} <span class='text-red-600'>*</span>"
              )
            }
          /><.input
            field={@form[:city]}
            type="text"
            label={
              Phoenix.HTML.raw(
                "#{with_locale(@language, fn -> gettext("City") end)} <span class='text-red-600'>*</span>"
              )
            }
          />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:country]}
            type="text"
            label={
              Phoenix.HTML.raw(
                "#{with_locale(@language, fn -> gettext("Country") end)} <span class='text-red-600'>*</span>"
              )
            }
          />
        </div>

        <input type="hidden" value={@current_user.id} name="organisation[owner_id]" />
        <div class="space-y-3">
          <.input
            field={@form[:default_daily_start_at]}
            type="time"
            label={with_locale(@language, fn -> gettext("Daily Start At") end)}
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
            label={with_locale(@language, fn -> gettext("Daily End At") end)}
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
            label={with_locale(@language, fn -> gettext("Additional Info") end)}
          />
        </div>

        <div class="space-y-3">
          <.input
            field={@form[:po_box]}
            type="text"
            label={with_locale(@language, fn -> gettext("Po Box") end)}
          />
        </div>

        <div class="space-y-3">
          <.input
            field={@form[:canton]}
            type="text"
            label={with_locale(@language, fn -> gettext("Canton") end)}
          />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:phone]}
            type="text"
            label={with_locale(@language, fn -> gettext("Phone") end)}
          />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:fax]}
            type="text"
            label={with_locale(@language, fn -> gettext("Fax") end)}
          />
        </div>

        <div class="space-y-3">
          <.input
            field={@form[:email]}
            type="text"
            label={with_locale(@language, fn -> gettext("Email") end)}
          />
          <.error :for={msg <- get_field_errors(f[:email], :email)}>
            <%= "Email" <> " " <> msg %>
          </.error>
        </div>

        <div class="space-y-3">
          <.input
            field={@form[:website]}
            type="text"
            label={with_locale(@language, fn -> gettext("Website") end)}
          />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:zsr_number]}
            type="text"
            label={with_locale(@language, fn -> gettext("Zsr Number") end)}
          />
          <.error :for={msg <- get_field_errors(f[:zsr_number], :zsr_number)}>
            <%= "Zsr_number" <> " " <> msg %>
          </.error>
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:ean_gln]}
            type="text"
            label={with_locale(@language, fn -> gettext("Ean Gln") end)}
          />
        </div>

        <div class="space-y-3">
          <.input
            field={@form[:uid_bfs_number]}
            type="text"
            label={with_locale(@language, fn -> gettext("Uid Bfs Number") end)}
          />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:trade_register_no]}
            type="text"
            label={with_locale(@language, fn -> gettext("Trade Register No") end)}
          />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:bank]}
            type="text"
            label={with_locale(@language, fn -> gettext("Bank") end)}
          />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:iban]}
            type="text"
            label={with_locale(@language, fn -> gettext("Iban") end)}
          />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:bic]}
            type="text"
            label={with_locale(@language, fn -> gettext("Bic") end)}
          />
        </div>

        <div class="space-y-3">
          <.input
            field={@form[:account_number]}
            type="text"
            label={with_locale(@language, fn -> gettext("Account Number") end)}
          />
        </div>

        <:actions>
          <.button phx-disable-with={with_locale(@language, fn -> gettext("Saving...") end)}>
            <%= with_locale(@language, fn -> %>
              <%= gettext("Save Organisation") %>
            <% end) %>
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
    current_name = socket.assigns.form.source.params["name"]
    new_name = organisation_params["name"]

    new_organisation_params =
      if current_name != new_name do
        if new_name == "" || new_name == nil do
          organisation_params
        else
          Map.put(organisation_params, "slug", update_slug(Slug.slugify(new_name)))
        end
      else
        organisation_params
      end

    form = Form.validate(socket.assigns.form, new_organisation_params, errors: true)
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
            with_locale(socket.assigns.language, fn -> gettext("Organisation saved.") end)
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

  defp generate_unique_slug(base_slug) do
    new_slug = "#{base_slug}#{:rand.uniform(99)}"

    case Organisation.slug_exists?(new_slug) do
      true -> generate_unique_slug(base_slug)
      false -> Slug.slugify(new_slug)
    end
  end

  defp update_slug(slug) do
    case Organisation.slug_exists?(slug) do
      true -> generate_unique_slug(slug)
      false -> Slug.slugify(slug)
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{organisation: organisation}} = socket) do
    form =
      if organisation do
        AshPhoenix.Form.for_update(organisation, :update,
          as: "organisation",
          actor: socket.assigns.current_user
        )
      else
        AshPhoenix.Form.for_create(Omedis.Accounts.Organisation, :create,
          as: "organisation",
          actor: socket.assigns.current_user
        )
      end

    assign(socket, form: to_form(form))
  end

  defp get_field_errors(field, _name) do
    Enum.map(field.errors, &translate_error(&1))
  end

  defp path_for(:edit, organisation), do: ~p"/organisations/#{organisation}"
  defp path_for(:new, _organisation), do: ~p"/organisations"
end
