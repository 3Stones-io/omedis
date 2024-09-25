defmodule OmedisWeb.LogCategoryLive.FormComponent do
  use OmedisWeb, :live_component
  alias Omedis.Accounts.LogCategory

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="log_category-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:name]}
          type="text"
          label={Phoenix.HTML.raw("Name  <span class='text-red-600'>*</span>")}
        />

        <%= if @tenant.id do %>
          <.input
            field={@form[:tenant_id]}
            type="select"
            label={Phoenix.HTML.raw("Tenant  <span class='text-red-600'>*</span>")}
            options={Enum.map(@tenants, &{&1.name, &1.id})}
            disabled={true}
            value={@tenant.id}
          />
          <input type="hidden" name="log_category[tenant_id]" value={@tenant.id} />
        <% else %>
          <.input
            field={@form[:tenant_id]}
            type="select"
            label={Phoenix.HTML.raw("Tenant  <span class='text-red-600'>*</span>")}
            options={Enum.map(@tenants, &{&1.name, &1.id})}
          />
        <% end %>

        <.input
          field={@form[:color_code]}
          type="color"
          value={@color_code}
          label={Phoenix.HTML.raw("Color code  <span class='text-red-600'>*</span>")}
        />
        <div class="hidden">
          <.input
            field={@form[:position]}
            value={@next_position}
            label={Phoenix.HTML.raw("Position  <span class='text-red-600'>*</span>")}
          />
        </div>

        <:actions>
          <.button
            class={
              if @form.source.source.valid? == false do
                "opacity-40 cursor-not-allowed hover:bg-blue-500 active:bg-blue-500"
              else
                ""
              end
            }
            disabled={@form.source.source.valid? == false}
            phx-disable-with="Saving..."
          >
            Save Log category
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
     |> assign_form()}
  end

  @impl true
  def handle_event("validate", %{"log_category" => log_category_params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, log_category_params)

    {:noreply,
     socket
     |> assign(form: form)}
  end

  def handle_event("save", %{"log_category" => log_category_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: log_category_params) do
      {:ok, log_category} ->
        notify_parent({:saved, log_category})

        socket =
          socket
          |> put_flash(:info, "Log category #{socket.assigns.form.source.type}d successfully")
          |> push_patch(to: socket.assigns.patch)

        {:noreply, socket}

      {:error, form} ->
        {:noreply,
         socket
         |> assign(form: form)
         |> put_flash(:error, "Log category could not be saved")}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{log_category: log_category}} = socket) do
    form =
      if log_category do
        AshPhoenix.Form.for_update(log_category, :update, as: "log_category")
      else
        AshPhoenix.Form.for_create(LogCategory, :create, as: "log_category")
      end

    color_code =
      LogCategory.select_unused_color_code(socket.assigns.tenant.id)

    assign(socket, form: to_form(form), color_code: color_code)
  end
end
