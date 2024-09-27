defmodule OmedisWeb.ProjectLive.FormComponent do
  use OmedisWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Use this form to manage project records in your database.") %>
          <% end) %>
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="project-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:name]}
          type="text"
          label={with_locale(@language, fn -> gettext("Name") end)}
        />
        <input type="hidden" name="project[tenant_id]" value={@tenant.id} />
        <.input
          field={@form[:tenant_id]}
          type="select"
          label={Phoenix.HTML.raw("Tenant  <span class='text-red-600'>*</span>")}
          disabled={true}
          options={Enum.map(@tenants, &{&1.name, &1.id})}
        />
        <div class="hidden">
          <.input
            field={@form[:position]}
            value={@next_position}
            label={Phoenix.HTML.raw("Position  <span class='text-red-600'>*</span>")}
          />
        </div>

        <:actions>
          <.button phx-disable-with={with_locale(@language, fn -> gettext("Saving...") end)}>
            <%= with_locale(@language, fn -> %>
              <%= gettext("Save Project") %>
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
  def handle_event("validate", %{"project" => project_params}, socket) do
    {:noreply,
     assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, project_params))}
  end

  def handle_event("save", %{"project" => project_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: project_params) do
      {:ok, project} ->
        notify_parent({:saved, project})

        socket =
          socket
          |> put_flash(
            :info,
            with_locale(socket.assigns.language, fn -> gettext("Project saved.") end)
          )
          |> push_patch(to: socket.assigns.patch)

        {:noreply, socket}

      {:error, form} ->
        {:noreply,
         socket
         |> assign(form: form)
         |> put_flash(
           :error,
           with_locale(socket.assigns.language, fn ->
             gettext("Please correct the errors below.")
           end)
         )}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{project: project}} = socket) do
    form =
      if project do
        AshPhoenix.Form.for_update(project, :update, as: "project")
      else
        AshPhoenix.Form.for_create(Omedis.Accounts.Project, :create, as: "project")
      end

    assign(socket, form: to_form(form))
  end
end
