defmodule OmedisWeb.OrganisationLive.FormComponent do
  use OmedisWeb, :live_component

  alias AshPhoenix.Form
  alias Omedis.Accounts
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
                "#{with_locale(@language, fn -> dgettext("organisation", "Name") end)} <span class='text-red-600'>*</span>"
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
                "#{with_locale(@language, fn -> dgettext("organisation", "Slug") end)} <span class='text-red-600'>*</span>"
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
                "#{with_locale(@language, fn -> dgettext("organisation", "Street") end)} <span class='text-red-600'>*</span>"
              )
            }
          />
        </div>

        <div class="space-y-3">
          <.input
            field={@form[:street2]}
            type="text"
            label={
              with_locale(@language, fn ->
                dgettext("organisation", "Street2")
              end)
            }
          />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:zip_code]}
            type="text"
            label={
              Phoenix.HTML.raw(
                "#{with_locale(@language, fn -> dgettext("organisation", "Zip Code") end)} <span class='text-red-600'>*</span>"
              )
            }
          />
          <.input
            field={@form[:city]}
            type="text"
            label={with_locale(@language, fn -> dgettext("organisation", "City") end)}
          />
        </div>
        <div class="space-y-3">
          <.input field={@form[:country]} type="text" label={dgettext("organisation", "Country")} />
        </div>

        <input type="hidden" value={@current_user.id} name="organisation[owner_id]" />
        <div class="space-y-3">
          <.input
            field={@form[:default_daily_start_at]}
            type="time"
            label={
              with_locale(@language, fn ->
                dgettext("organisation", "Daily Start At")
              end)
            }
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
            label={
              with_locale(@language, fn ->
                dgettext("organisation", "Daily End At")
              end)
            }
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
            label={
              with_locale(@language, fn ->
                dgettext("organisation", "Additional Info")
              end)
            }
          />
        </div>

        <div class="space-y-3">
          <.input
            field={@form[:po_box]}
            type="text"
            label={
              with_locale(@language, fn ->
                dgettext("organisation", "PO Box")
              end)
            }
          />
        </div>

        <div class="space-y-3">
          <.input
            field={@form[:canton]}
            type="text"
            label={
              with_locale(@language, fn ->
                dgettext("organisation", "Canton")
              end)
            }
          />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:phone]}
            type="text"
            label={with_locale(@language, fn -> dgettext("organisation", "Phone") end)}
          />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:fax]}
            type="text"
            label={with_locale(@language, fn -> dgettext("organisation", "Fax") end)}
          />
        </div>

        <div class="space-y-3">
          <.input
            field={@form[:email]}
            type="text"
            label={with_locale(@language, fn -> dgettext("organisation", "Email") end)}
          />
          <.error :for={msg <- get_field_errors(f[:email], :email)}>
            <%= "Email" <> " " <> msg %>
          </.error>
        </div>

        <div class="space-y-3">
          <.input
            field={@form[:website]}
            type="text"
            label={
              with_locale(@language, fn ->
                dgettext("organisation", "Website")
              end)
            }
          />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:zsr_number]}
            type="text"
            label={
              with_locale(@language, fn ->
                dgettext("organisation", "ZSR Number")
              end)
            }
          />
          <.error :for={msg <- get_field_errors(f[:zsr_number], :zsr_number)}>
            <%= "Zsr_number" <> " " <> msg %>
          </.error>
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:ean_gln]}
            type="text"
            label={
            label={
              with_locale(@language, fn ->
                dgettext("organisation", "EAN/GLN")
              end)
            }
          />
        </div>

        <div class="space-y-3">
          <.input
            field={@form[:uid_bfs_number]}
            type="text"
            label={
            label={
              with_locale(@language, fn ->
                dgettext("organisation", "UID/BFS Number")
              end)
            }
          />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:trade_register_no]}
            type="text"
            label={
              with_locale(@language, fn ->
                dgettext("organisation", "Trade Register No")
              end)
            }
          />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:bank]}
            type="text"
            label={with_locale(@language, fn -> dgettext("organisation", "Bank") end)}
          />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:iban]}
            type="text"
            label={with_locale(@language, fn -> dgettext("organisation", "IBAN") end)}
          />
        </div>
        <div class="space-y-3">
          <.input
            field={@form[:bic]}
            type="text"
            label={with_locale(@language, fn -> dgettext("organisation", "BIC") end)}
          />
        </div>

        <div class="space-y-3">
          <.input
            field={@form[:account_number]}
            type="text"
            label={
              with_locale(@language, fn ->
                dgettext("organisation", "Account Number")
              end)
            }
          />
        </div>

        <:actions>
          <.button phx-disable-with={
            with_locale(@language, fn ->
              dgettext("organisation", "Saving...")
            end)
          }>
            <%= with_locale(@language, fn ->
              dgettext("organisation", "Save Organisation")
            end) %>
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
          Map.put(organisation_params, "slug", update_slug(Slug.slugify(new_name), socket))
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
            with_locale(socket.assigns.language, fn ->
              dgettext("organisation", "Organisation saved.")
            end)
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

  defp generate_unique_slug(base_slug, socket) do
    new_slug = "#{base_slug}#{:rand.uniform(99)}"

    if Accounts.slug_exists?(Organisation, [slug: new_slug],
         actor: socket.assigns.current_user,
         tenant: socket.assigns.organisation
       ) do
      generate_unique_slug(base_slug, socket)
    else
      Slug.slugify(new_slug)
    end
  end

  defp update_slug(slug, socket) do
    if Accounts.slug_exists?(Organisation, [slug: slug],
         actor: socket.assigns.current_user,
         tenant: socket.assigns.organisation
       ) do
      generate_unique_slug(slug, socket)
    else
      Slug.slugify(slug)
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
