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

        <%= if @group.id do %>
          <.input
            field={@form[:group_id]}
            type="select"
            label={Phoenix.HTML.raw("Group <span class='text-red-600'>*</span>")}
            options={Enum.map(@groups, &{&1.name, &1.id})}
            disabled={true}
            value={@group.id}
          />
          <input type="hidden" name="log_category[group_id]" value={@group.id} />
        <% else %>
          <.input
            field={@form[:group_id]}
            type="select"
            label={Phoenix.HTML.raw("Tenant  <span class='text-red-600'>*</span>")}
            options={Enum.map(@groups, &{&1.name, &1.id})}
          />
        <% end %>

        <div class="flex gap-5">
          <p>
            <%= with_locale(@language, fn -> %>
              <%= gettext("Enter custom color") %>
            <% end) %>
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
              <%= with_locale(@language, fn -> %>
                <%= gettext("Enable or disable custom color input") %>
              <% end) %>
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

        <div
          :if={@form[:name].value}
          class="w-[25%] h-[100%] h-[40px] rounded-md"
          style={"background-color: #{@form[:color_code].value || @color_code};"}
        >
          <div class="flex gap-2 justify-center text-sm  md:text-base p-2 text-white items-center">
            <span>
              <%= @form[:name].value || "Name" %>
            </span>
          </div>
        </div>

        <div class="hidden">
          <.input
            field={@form[:position]}
            value={@next_position}
            class="hidden"
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
            phx-disable-with={with_locale(@language, fn -> gettext("Saving...") end)}
          >
            <%= with_locale(@language, fn -> %>
              <%= gettext("Save Log category") %>
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
  def handle_event("validate", %{"log_category" => log_category_params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, log_category_params)

    {:noreply,
     socket
     |> assign(form: form)}
  end

  def handle_event("toggle_color_mode", _params, socket) do
    {:noreply,
     socket
     |> update(:is_custom_color, fn is_custom_color -> not is_custom_color end)}
  end

  def handle_event("save", %{"log_category" => log_category_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: log_category_params) do
      {:ok, log_category} ->
        notify_parent({:saved, log_category})

        socket =
          socket
          |> put_flash(
            :info,
            with_locale(socket.assigns.language, fn ->
              gettext("Log category saved successfully")
            end)
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
             gettext("Please correct the errors below")
           end)
         )}
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
