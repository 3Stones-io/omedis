defmodule OmedisWeb.LogCategoryLive.FormComponent do
  use OmedisWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage log_category records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="log_category-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        
            
              <.input field={@form[:name]} type="text" label="Name" /><.input field={@form[:tenant_id]} type="text" label="Tenant" />
            
          
        <:actions>
          <.button phx-disable-with="Saving...">Save Log category</.button>
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
    {:noreply,
     assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, log_category_params))}
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
        {:noreply, assign(socket, form: form)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{log_category: log_category}} = socket) do
    form =
      if log_category do
        AshPhoenix.Form.for_update(log_category, :update, as: "log_category")
      else
        AshPhoenix.Form.for_create(Omedis.Accounts.LogCategory, :create, as: "log_category")
      end

    assign(socket, form: to_form(form))
  end
end
