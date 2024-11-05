defmodule OmedisWeb.InvitationLive.FormComponent do
  use OmedisWeb, :live_component

  alias AshPhoenix.Form
  alias Omedis.Accounts.Group
  alias Omedis.Accounts.Invitation

  @supported_languages [
    {"English", "en"},
    {"Deutsch", "de"},
    {"Français", "fr"},
    {"Italiano", "it"}
  ]

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:supported_languages, @supported_languages)
     |> assign(:selected_groups, [])
     |> assign_groups()
     |> assign_form()}
  end

  @impl true
  def handle_event("validate", %{"invitation" => _params}, socket) do
    # params = add_tenant_and_creator(params, socket)

    # Find a way to perform the validation without clearing the form group input
    # form = Form.validate(socket.assigns.form, params, errors: true)
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"invitation" => params}, socket) do
    params = add_tenant_and_creator(params, socket)

    case Form.submit(socket.assigns.form, params: params) do
      {:ok, invitation} ->
        notify_parent({:saved, invitation})

        {:noreply,
         socket
         |> put_flash(:info, gettext("Invitation created successfully"))
         |> push_navigate(to: socket.assigns.patch)}

      {:error, form} ->
        {:noreply, assign(socket, :form, form)}
    end
  end

  defp assign_groups(socket) do
    case Group.by_tenant_id(%{tenant_id: socket.assigns.tenant.id},
           actor: socket.assigns.current_user,
           tenant: socket.assigns.tenant
         ) do
      {:ok, %Ash.Page.Offset{results: groups}} -> assign(socket, :groups, groups)
      _ -> assign(socket, :groups, [])
    end
  end

  defp assign_form(socket) do
    form =
      Form.for_create(Invitation, :create,
        as: "invitation",
        actor: socket.assigns.current_user,
        tenant: socket.assigns.tenant,
        prepare_params: &prepare_params/2
      )

    assign(socket, :form, to_form(form))
  end

  defp prepare_params(%{"groups" => groups} = params, _) do
    groups =
      groups
      |> Enum.filter(&(elem(&1, 1) == "true"))
      |> Enum.map(&elem(&1, 0))

    Map.put(params, "groups", groups)
  end

  defp prepare_params(params, _), do: params

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp language_to_flag(language) do
    case language do
      "de" -> "🇩🇪"
      "fr" -> "🇫🇷"
      "it" -> "🇮🇹"
      "en" -> "🇬🇧"
      _ -> nil
    end
  end

  defp add_tenant_and_creator(params, socket) do
    Map.merge(params, %{
      "creator_id" => socket.assigns.current_user.id,
      "tenant_id" => socket.assigns.tenant.id
    })
  end

  defp starts_with_group?(changeset, group) do
    group in List.wrap(changeset.data.groups)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <:subtitle>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Use this form to invite new members.") %>
          <% end) %>
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="invitation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:email]}
          type="email"
          label={with_locale(@language, fn -> gettext("Email") end)}
        />

        <div class="space-y-2">
          <label class="block text-sm font-medium leading-6 text-gray-900">
            <%= with_locale(@language, fn -> gettext("Language") end) %>
          </label>
          <div class="flex space-x-4">
            <%= for {_language, code} <- @supported_languages do %>
              <label class="cursor-pointer">
                <input
                  type="radio"
                  name="invitation[language]"
                  value={code}
                  class="hidden invitation-language-input"
                  checked={input_value(@form, :language) == code}
                />
                <span class="cursor-pointer text-2xl px-2 lang-flag">
                  <%= language_to_flag(code) %>
                </span>
              </label>
            <% end %>
          </div>
        </div>

        <div class="space-y-2">
          <label class="block text-sm font-medium leading-6 text-gray-900">
            <%= gettext("Groups") %>
          </label>

          <div class="space-y-2">
            <%= for group <- @groups do %>
              <.input
                type="checkbox"
                label={group.name}
                name={@form.name <> "[groups][#{group.id}]"}
                id={@form.id <> "_groups_#{group.id}"}
                value={starts_with_group?(@form.source.source, group)}
                checked={starts_with_group?(@form.source.source, group)}
              />
            <% end %>
          </div>
        </div>
        <:actions>
          <.button phx-disable-with={with_locale(@language, fn -> gettext("Saving...") end)}>
            <%= with_locale(@language, fn -> gettext("Send Invitation") end) %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
