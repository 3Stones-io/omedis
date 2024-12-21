defmodule OmedisWeb.ActivityLive.FormComponent do
  use OmedisWeb, :live_component

  alias Omedis.TimeTracking
  alias Omedis.TimeTracking.Activity

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="activity-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:name]}
          type="text"
          label={Phoenix.HTML.raw("Name  <span class='text-red-600'>*</span>")}
          phx-change={JS.push("generate-slug", value: %{"name" => input_value(@form, :name)})}
        />

        <.input
          field={@form[:slug]}
          type="text"
          label={Phoenix.HTML.raw("Slug <span class='text-red-600'>*</span>")}
          id="activity-slug"
          phx-hook="SlugInput"
        />

        <%= if @group.id do %>
          <.input
            field={@form[:group_id]}
            type="select"
            label={Phoenix.HTML.raw("Group <span class='text-red-600'>*</span>")}
            options={Enum.map(@groups, &{&1.name, &1.id})}
            disabled={true}
            value={@group.id}
          />
          <input type="hidden" name="activity[group_id]" value={@group.id} />
        <% else %>
          <.input
            field={@form[:group_id]}
            type="select"
            label={Phoenix.HTML.raw("Organisation  <span class='text-red-600'>*</span>")}
            options={Enum.map(@groups, &{&1.name, &1.id})}
          />
        <% end %>

        <.input
          field={@form[:project_id]}
          type="select"
          label={Phoenix.HTML.raw("Project  <span class='text-red-600'>*</span>")}
          options={Enum.map(@projects, &{&1.name, &1.id})}
        />

        <.input field={@form[:is_default]} type="checkbox" label={Phoenix.HTML.raw("Is default")} />

        <div class="flex gap-5">
          <p>
            <%= dgettext("activity", "Enter custom color") %>
          </p>
          <div
            role="switch"
            phx-click="toggle_color_mode"
            phx-target={@myself}
            class={
         "relative inline-flex items-center h-6 rounded-full w-11 transition-colors duration-200 ease-in-out " <>
           if @is_custom_color, do: "bg-green-500", else: "bg-gray-200"
           }
            aria-checked={@is_custom_color}
          >
            <span class="sr-only">
              <%= dgettext("activity", "Enable or disable custom color input") %>
            </span>

            <span class={
          "block w-5 h-5 transform bg-white rounded-full transition duration-200 ease-in-out " <>
         if @is_custom_color, do: "translate-x-5", else: "translate-x-0"
        }>
            </span>
          </div>
        </div>
        <div :if={!@is_custom_color}>
          <.input
            field={@form[:color_code]}
            type="select"
            options={[
              "#1f77b4",
              "#ff7f0e",
              "#2ca02c",
              "#d62728",
              "#9467bd",
              "#8c564b",
              "#e377c2",
              "#7f7f7f",
              "#bcbd22",
              "#17becf"
            ]}
            value={@color_code}
            label={Phoenix.HTML.raw("Color code  <span class='text-red-600'>*</span>")}
          />
        </div>

        <div :if={@is_custom_color}>
          <.input
            field={@form[:color_code]}
            type="text"
            value={@form[:color_code].value || @color_code}
            label={Phoenix.HTML.raw("Color code  <span class='text-red-600'>*</span>")}
          />
        </div>

        <.custom_color_button :if={@form[:name].value} color={@form[:color_code].value || @color_code}>
          <%= @form[:name].value || "Name" %>
        </.custom_color_button>

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
            phx-disable-with={dgettext("activity", "Saving...")}
          >
            <%= dgettext("activity", "Save Activity") %>
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
  def handle_event("validate", %{"activity" => activity_params}, socket) do
    form =
      AshPhoenix.Form.validate(socket.assigns.form, activity_params)

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("generate-slug", %{"activity" => %{"name" => name}}, socket) do
    slug =
      name
      |> String.trim()
      |> Slug.slugify()

    {:noreply,
     socket
     |> assign(:form, AshPhoenix.Form.validate(socket.assigns.form, %{"name" => name}))
     |> push_event("update-slug", %{"slug" => slug})}
  end

  def handle_event("toggle_color_mode", _params, socket) do
    {:noreply,
     socket
     |> update(:is_custom_color, fn is_custom_color -> not is_custom_color end)}
  end

  def handle_event("save", %{"activity" => activity_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: activity_params) do
      {:ok, activity} ->
        notify_parent({:saved, activity})

        socket =
          socket
          |> put_flash(
            :info,
            dgettext("activity", "Activity saved successfully")
          )
          |> push_patch(to: socket.assigns.patch)

        {:noreply, socket}

      {:error, form} ->
        {:noreply,
         socket
         |> assign(form: form)
         |> put_flash(
           :error,
           dgettext("activity", "Please correct the errors below")
         )}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{activity: activity}} = socket) do
    form =
      if activity do
        AshPhoenix.Form.for_update(
          activity,
          :update,
          as: "activity",
          actor: socket.assigns.current_user,
          tenant: socket.assigns.organisation
        )
      else
        AshPhoenix.Form.for_create(
          Activity,
          :create,
          as: "activity",
          actor: socket.assigns.current_user,
          tenant: socket.assigns.organisation
        )
      end

    color_code = TimeTracking.select_unused_color_code(socket.assigns.organisation)

    assign(socket,
      form: to_form(form),
      color_code: color_code
    )
  end
end
