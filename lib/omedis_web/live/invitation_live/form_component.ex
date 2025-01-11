defmodule OmedisWeb.InvitationLive.FormComponent do
  use OmedisWeb, :live_component

  alias AshPhoenix.Form
  alias Omedis.Groups.Group
  alias Omedis.Invitations.Invitation

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
  def handle_event("validate", %{"invitation" => params}, socket) do
    params = add_organisation_and_creator(params, socket)
    form = Form.validate(socket.assigns.form, params)

    {:noreply, assign(socket, :form, form)}
  end

  @impl true
  def handle_event("save", %{"invitation" => params}, socket) do
    params =
      params
      |> add_organisation_and_creator(socket)
      |> add_users_group(socket.assigns.groups)

    case Form.submit(socket.assigns.form, params: params) do
      {:ok, _invitation} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("invitation", "Invitation created successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, form} ->
        {:noreply, assign(socket, :form, form)}
    end
  end

  defp add_users_group(params, groups) do
    users_group = Enum.find(groups, &(&1.name == "Users"))
    put_in(params, ["groups", users_group.id], "true")
  end

  defp assign_groups(socket) do
    case Group.by_organisation_id(%{organisation_id: socket.assigns.organisation.id},
           actor: socket.assigns.current_user,
           tenant: socket.assigns.organisation
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
        tenant: socket.assigns.organisation,
        params: %{"language" => socket.assigns.current_user.lang},
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

  defp language_to_flag(language) do
    case language do
      "de" -> "🇩🇪"
      "fr" -> "🇫🇷"
      "it" -> "🇮🇹"
      "en" -> "🇬🇧"
      _ -> nil
    end
  end

  defp add_organisation_and_creator(params, socket) do
    Map.merge(params, %{
      "creator_id" => socket.assigns.current_user.id,
      "organisation_id" => socket.assigns.organisation.id
    })
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:checked_groups, Form.value(assigns.form, :groups) || [])

    ~H"""
    <div>
      <.header>
        {dgettext("invitation", "New Invitation")}

        <:subtitle>
          {dgettext("invitation", "Use this form to invite new members.")}
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="invitation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:email]} type="email" label={dgettext("invitation", "Email")} />

        <div class="space-y-2">
          <label class="block text-sm font-medium leading-6 text-gray-900">
            {dgettext("invitation", "Language")}
          </label>
          <div class="flex space-x-4">
            <%= for {_language, code} <- @supported_languages do %>
              <div>
                <label class="cursor-pointer">
                  <input
                    type="radio"
                    name={@form[:language].name}
                    value={code}
                    class="hidden invitation-language-input"
                    checked={input_value(@form, :language) == code}
                  />
                  <span class="cursor-pointer text-2xl px-2 lang-flag">
                    {language_to_flag(code)}
                  </span>
                </label>
              </div>
            <% end %>
          </div>
          <div phx-feedback-for={@form[:language].name}>
            <.error :for={error <- @form[:language].errors}>
              {translate_error(error)}
            </.error>
          </div>
        </div>

        <div class="space-y-2">
          <label class="block text-sm font-medium leading-6 text-gray-900">
            {dgettext("invitation", "Groups")}
          </label>

          <div class="space-y-2">
            <%= for group <- @groups do %>
              <.input
                type="checkbox"
                label={group.name}
                name={@form.name <> "[groups][#{group.id}]"}
                id={@form.id <> "_groups_#{group.id}"}
                checked={group.name == "Users" or group.id in @checked_groups}
                phx-debounce="blur"
                disabled={group.name == "Users"}
              />
            <% end %>
          </div>
        </div>
        <:actions>
          <.button phx-disable-with={dgettext("invitation", "Saving...")}>
            {dgettext("invitation", "Send Invitation")}
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
