defmodule OmedisWeb.ProjectLive.FormComponent do
  use OmedisWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>
          <%= dgettext(
            "project",
            "Use this form to manage project records in your database."
          ) %>
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="project-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label={dgettext("project", "Name")} />
        <input type="hidden" name="project[organisation_id]" value={@organisation.id} />
        <.input
          field={@form[:organisation_id]}
          type="select"
          label={
            Phoenix.HTML.raw(
              "#{dgettext("project", "Organisation")}  <span class='text-red-600'>*</span>"
            )
          }
          disabled={true}
          options={Enum.map(@organisations, &{&1.name, &1.id})}
        />
        <div class="hidden">
          <.input
            field={@form[:position]}
            value={@next_position}
            label={
              Phoenix.HTML.raw(
                "#{dgettext("project", "Position")}  <span class='text-red-600'>*</span>"
              )
            }
          />
        </div>

        <:actions>
          <.button phx-disable-with={dgettext("project", "Saving...")}>
            <%= dgettext("project", "Save Project") %>
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
            dgettext("project", "Project saved.")
          )
          |> push_patch(to: socket.assigns.patch)

        {:noreply, socket}

      {:error, form} ->
        {:noreply,
         socket
         |> assign(form: form)
         |> put_flash(
           :error,
           dgettext("project", "Please correct the errors below.")
         )}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{project: project}} = socket) do
    actor = socket.assigns.current_user
    organisation = socket.assigns.organisation

    form =
      if project do
        AshPhoenix.Form.for_update(project, :update,
          as: "project",
          actor: actor,
          tenant: organisation
        )
      else
        AshPhoenix.Form.for_create(Omedis.Accounts.Project, :create,
          as: "project",
          actor: actor,
          tenant: organisation
        )
      end

    assign(socket, form: to_form(form))
  end
end
