defmodule OmedisWeb.GroupLive.FormComponent do
  use OmedisWeb, :live_component

  alias AshPhoenix.Form

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>
          {dgettext("group", "Use this form to manage group records in your database.")}
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
          <.input field={@form[:name]} type="text" label={dgettext("group", "Name")} />
          <input type="hidden" name="group[organisation_id]" value={@organisation.id} />
          <input type="hidden" name="group[user_id]" value={@current_user.id} />
        <% end %>
        <%= if @form.source.type == :update do %>
          <.input field={@form[:name]} type="text" label={dgettext("group", "Name")} />
        <% end %>

        <:actions>
          <.button phx-disable-with={dgettext("group", "Saving...")}>
            {dgettext("group", "Save Group")}
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
    form = Form.validate(socket.assigns.form, group_params, errors: true)

    {:noreply,
     socket
     |> assign(form: form)}
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
        AshPhoenix.Form.for_update(
          group,
          :update,
          as: "group",
          tenant: socket.assigns.organisation,
          actor: socket.assigns.current_user
        )
      else
        AshPhoenix.Form.for_create(
          Omedis.Groups.Group,
          :create,
          as: "group",
          tenant: socket.assigns.organisation,
          actor: socket.assigns.current_user
        )
      end

    assign(socket, form: to_form(form))
  end
end
