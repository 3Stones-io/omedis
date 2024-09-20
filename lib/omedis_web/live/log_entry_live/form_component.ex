defmodule OmedisWeb.LogEntryLive.FormComponent do
  use OmedisWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage log_entry records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="log_entry-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:comment]} type="text" label="Comment" /><.input
          field={@form[:start_at]}
          type="time"
          label="Start at"
        /><.input field={@form[:end_at]} type="time" label="End at" /><.input
          field={@form[:tenant_id]}
          type="text"
          label="Tenant"
        /><.input field={@form[:log_category_id]} type="text" label="Log category" /><.input
          field={@form[:user_id]}
          type="text"
          label="User"
        />

        <:actions>
          <.button phx-disable-with="Saving...">Save Log entry</.button>
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
  def handle_event("validate", %{"log_entry" => log_entry_params}, socket) do
    {:noreply,
     assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, log_entry_params))}
  end

  def handle_event("save", %{"log_entry" => log_entry_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: log_entry_params) do
      {:ok, log_entry} ->
        notify_parent({:saved, log_entry})

        socket =
          socket
          |> put_flash(:info, "Log entry #{socket.assigns.form.source.type}d successfully")
          |> push_patch(to: socket.assigns.patch)

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{log_entry: log_entry}} = socket) do
    form =
      if log_entry do
        AshPhoenix.Form.for_update(log_entry, :update, as: "log_entry")
      else
        AshPhoenix.Form.for_create(Omedis.Accounts.LogEntry, :create, as: "log_entry")
      end

    assign(socket, form: to_form(form))
  end
end
