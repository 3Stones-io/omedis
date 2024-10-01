defmodule OmedisWeb.GroupLive.FormComponent do
  use OmedisWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Use this form to manage group records in your database.") %>
          <% end) %>
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="group-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <%= if @form.source.type == :create do %>
          <.input
            field={@form[:name]}
            type="text"
            label={with_locale(@language, fn -> gettext("Name") end)}
          />
          <.input
            field={@form[:slug]}
            type="text"
            label={with_locale(@language, fn -> gettext("Slug") end)}
          />
          <input type="hidden" name="group[tenant_id]" value={@tenant.id} />
          <input type="hidden" name="group[user_id]" value={@current_user.id} />
        <% end %>
        <%= if @form.source.type == :update do %>
          <.input
            field={@form[:name]}
            type="text"
            label={with_locale(@language, fn -> gettext("Name") end)}
          />
          <.input
            field={@form[:slug]}
            type="text"
            label={with_locale(@language, fn -> gettext("Slug") end)}
          />
        <% end %>

        <:actions>
          <.button phx-disable-with={with_locale(@language, fn -> gettext("Saving...") end)}>
            <%= with_locale(@language, fn -> %>
              <%= gettext("Save Group") %>
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
     |> assign_form()}
  end

  @impl true
  def handle_event("validate", %{"group" => group_params}, socket) do
    {:noreply, assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, group_params))}
  end

  def handle_event("save", %{"group" => group_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: group_params) do
      {:ok, group} ->
        notify_parent({:saved, group})

        socket =
          socket
          |> put_flash(:info, "Group #{socket.assigns.form.source.type}d successfully")
          |> push_patch(to: socket.assigns.patch)

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{group: group}} = socket) do
    form =
      if group do
        AshPhoenix.Form.for_update(group, :update, as: "group")
      else
        AshPhoenix.Form.for_create(Omedis.Accounts.Group, :create, as: "group")
      end

    assign(socket, form: to_form(form))
  end
end
