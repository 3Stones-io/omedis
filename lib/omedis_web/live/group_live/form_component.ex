defmodule OmedisWeb.GroupLive.FormComponent do
  use OmedisWeb, :live_component

  alias AshPhoenix.Form
  alias Omedis.Accounts
  alias Omedis.Accounts.Group

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>
          <%= dgettext("group", "Use this form to manage group records in your database.") %> ) %>
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
          <.input field={@form[:slug]} type="text" label={dgettext("group", "Slug")} />
          <input type="hidden" name="group[organisation_id]" value={@organisation.id} />
          <input type="hidden" name="group[user_id]" value={@current_user.id} />
        <% end %>
        <%= if @form.source.type == :update do %>
          <.input field={@form[:name]} type="text" label={dgettext("group", "Name")} />
          <.input field={@form[:slug]} type="text" label={dgettext("group", "Slug")} />
        <% end %>

        <:actions>
          <.button phx-disable-with={dgettext("group", "Saving...")}>
            <%= dgettext("group", "Save Group") %>
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
    current_name = socket.assigns.form.source.params["name"]
    new_name = group_params["name"]

    new_group_params =
      if current_name != new_name do
        if new_name == "" || new_name == nil do
          group_params
        else
          Map.put(
            group_params,
            "slug",
            update_slug(Slug.slugify(new_name), socket)
          )
        end
      else
        group_params
      end

    form = Form.validate(socket.assigns.form, new_group_params, errors: true)

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

  defp update_slug(slug, socket) do
    if Accounts.slug_exists?(Group, [slug: slug, organisation_id: socket.assigns.organisation.id],
         actor: socket.assigns.current_user,
         tenant: socket.assigns.organisation
       ) do
      generate_unique_slug(slug, socket)
    else
      Slug.slugify(slug)
    end
  end

  defp generate_unique_slug(base_slug, socket) do
    new_slug = "#{base_slug}#{:rand.uniform(99)}"

    if Accounts.slug_exists?(
         Group,
         [slug: new_slug, organisation_id: socket.assigns.organisation.id],
         actor: socket.assigns.current_user,
         tenant: socket.assigns.organisation,
         authorize?: false
       ) do
      generate_unique_slug(base_slug, socket)
    else
      Slug.slugify(new_slug)
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
          Omedis.Accounts.Group,
          :create,
          as: "group",
          tenant: socket.assigns.organisation,
          actor: socket.assigns.current_user
        )
      end

    assign(socket, form: to_form(form))
  end
end
