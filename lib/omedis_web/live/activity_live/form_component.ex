defmodule OmedisWeb.ActivityLive.FormComponent do
  use OmedisWeb, :live_component

  alias Omedis.TimeTracking

  @color_presets [
    "#cb328a",
    "#db133c",
    "#c11f56",
    "#cb5a43",
    "#eb9020",
    "#029967",
    "#8dbd8f",
    "#6399ca",
    "#e4e5f8",
    "#9400d2",
    "#320162",
    "#37444d"
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
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
          label={
            Phoenix.HTML.raw("#{dgettext("activity", "Name")} <span class='text-red-600'>*</span>")
          }
        />

        <%= if @group.id do %>
          <.input
            field={@form[:group_id]}
            type="select"
            label={
              Phoenix.HTML.raw("#{dgettext("activity", "Group")} <span class='text-red-600'>*</span>")
            }
            options={Enum.map(@groups, &{&1.name, &1.id})}
            disabled={true}
            value={@group.id}
          />
          <input type="hidden" name="activity[group_id]" value={@group.id} />
        <% else %>
          <.input
            field={@form[:group_id]}
            type="select"
            label={
              Phoenix.HTML.raw(
                "#{dgettext("activity", "Organisation")} <span class='text-red-600'>*</span>"
              )
            }
            options={Enum.map(@groups, &{&1.name, &1.id})}
          />
        <% end %>

        <.input
          field={@form[:project_id]}
          type="select"
          label={
            Phoenix.HTML.raw("#{dgettext("activity", "Project")} <span class='text-red-600'>*</span>")
          }
          options={Enum.map(@projects, &{&1.name, &1.id})}
        />

        <.input
          field={@form[:is_default]}
          type="checkbox"
          label={Phoenix.HTML.raw(dgettext("activity", "Is default"))}
        />

        <div id="color-input-container" phx-hook="ActivityColorInput">
          <p class="block text-sm font-semibold leading-6 text-zinc-800 mb-2">
            <span>{dgettext("activity", "Color Code")}</span>
            <span class="text-red-600">*</span>
          </p>
          <div class="grid grid-cols-[10%_90%] outline outline-[1px] outline-gray-300 rounded-md mb-2">
            <input
              type="color"
              class="px-1 border-r border-r-[1.5px] h-full"
              id="color-picker-input"
              phx-update="ignore"
              value={@form[:color_code].value}
            />
            <input
              type="text"
              id="color-picker-input-text"
              disabled
              class="border-none outline-none"
              phx-update="ignore"
              value={@form[:color_code].value}
            />
          </div>

          <p class="mb-2">
            {dgettext("activity", "Select a color from the color picker or from the presets below")}
          </p>

          <div class="flex items-center gap-x-2">
            <div :for={color <- @color_presets}>
              <label class="cursor-pointer">
                <input
                  type="radio"
                  value={color}
                  class="absolute opacity-0 w-0 h-0 activity-color-radio"
                  id={"color-radio-#{color}"}
                  phx-update="ignore"
                />
                <span
                  class={[
                    "cursor-pointer text-2xl h-8 w-8 rounded-md inline-block color-preset",
                    @form[:color_code].value == color && "checked-radio"
                  ]}
                  style={"background: #{color}"}
                >
                </span>
              </label>
            </div>
          </div>
          <.input field={@form[:color_code]} type="hidden" id="color-code-input" />
        </div>

        <:actions>
          <.button phx-disable-with={dgettext("activity", "Saving...")}>
            {dgettext("activity", "Save Activity")}
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
     |> assign(:color_presets, @color_presets)
     |> assign_form()}
  end

  @impl true
  def handle_event("validate", %{"activity" => activity_params}, socket) do
    form =
      AshPhoenix.Form.validate(socket.assigns.form, activity_params)

    {:noreply, assign(socket, form: form)}
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
        {:noreply, assign(socket, :form, form)}
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
          TimeTracking.Activity,
          :create,
          api: TimeTracking,
          params: %{color_code: "#000000"},
          as: "activity",
          actor: socket.assigns.current_user,
          tenant: socket.assigns.organisation
        )
      end

    assign(socket, :form, to_form(form))
  end
end
