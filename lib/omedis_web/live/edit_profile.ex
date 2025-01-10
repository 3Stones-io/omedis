defmodule OmedisWeb.EditProfileLive do
  use OmedisWeb, :live_view

  alias AshPhoenix.Form
  alias Omedis.Accounts

  @supported_languages [
    {"English", "en"},
    {"Deutsch", "de"},
    {"Français", "fr"},
    {"Italiano", "it"}
  ]

  @impl true
  def mount(_params, %{"language" => language} = _session, socket) do
    Gettext.put_locale(language)

    socket =
      socket
      |> assign(:language, language)
      |> assign(:supported_languages, @supported_languages)
      |> assign(:errors, [])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    form = AshPhoenix.Form.for_update(socket.assigns.current_user, :update, as: "user")

    socket
    |> assign(
      :page_title,
      dgettext("user_profile", "Update Profile")
    )
    |> assign(
      :form,
      to_form(form)
    )
  end

  @impl true
  def handle_event("validate", %{"user" => user}, socket) do
    form = Form.validate(socket.assigns.form, user, errors: true)

    {:noreply, socket |> assign(form: form)}
  end

  @impl true
  def handle_event("submit", %{"user" => user}, socket) do
    case Form.submit(socket.assigns.form, params: user) do
      {:ok, user} ->
        socket =
          socket
          |> redirect(to: "/edit_profile?locale=#{user.lang}")
          |> put_flash(
            :info,
            dgettext("user_profile", "Profile updated successfully")
          )
          |> assign(:current_user, user)
          |> assign(:form, to_form(AshPhoenix.Form.for_update(user, :update, as: "user")))

        {:noreply, socket}

      {:error, form} ->
        {:noreply,
         socket
         |> assign(form: form)
         |> put_flash(
           :error,
           dgettext("user_profile", "Profile update failed")
         )}
    end
  end

  def handle_event("delete_account", %{"id" => id}, socket) do
    case Accounts.delete_user(id, actor: socket.assigns.current_user) do
      :ok ->
        {:noreply,
         socket
         |> redirect(to: "/")
         |> put_flash(
           :info,
           dgettext("user_profile", "Account deleted successfully")
         )}

      _error ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           dgettext("user_profile", "Failed to delete account! Please try again.")
         )}
    end
  end

  defp get_field_errors(field, _name) do
    Enum.map(field.errors, &translate_error(&1))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.side_and_topbar
      current_user={@current_user}
      current_organisation={@current_organisation}
      language={@language}
    >
      <div class="px-4 lg:pl-80 lg:pr-8 py-10">
        <.form
          :let={f}
          id="basic_user_edit_profile_form"
          for={@form}
          class="space-y-2 group"
          phx-change="validate"
          phx-submit="submit"
        >
          <div class="space-y-4">
            <div class="border-b border-gray-900/10 pb-12">
              <h2 class="text-base font-semibold leading-7 text-gray-900">
                {dgettext("user_profile", "Update Profile")}
              </h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                {dgettext("user_profile", "Edit your profile details")}
              </p>
              <div class="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
                <div class="sm:col-span-3">
                  <label class="block text-sm font-medium leading-6 text-gray-900">
                    {dgettext("user_profile", "First Name")}
                  </label>

                  <div phx-feedback-for={f[:first_name].name} class="mt-2">
                    {text_input(f, :first_name,
                      class:
                        "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                      placeholder: dgettext("user_profile", "First Name"),
                      value: f[:first_name].value,
                      "phx-debounce": "blur"
                    )}
                    <.error :for={msg <- get_field_errors(f[:first_name], :first_name)}>
                      {dgettext("user_profile", "First Name %{msg}", msg: msg)}
                    </.error>
                  </div>
                </div>

                <div class="sm:col-span-3">
                  <label class="block text-sm font-medium leading-6 text-gray-900">
                    {dgettext("user_profile", "Last Name")}
                  </label>
                  <div phx-feedback-for={f[:last_name].name} class="mt-2">
                    {text_input(f, :last_name,
                      class:
                        "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                      placeholder: dgettext("user_profile", "Last Name"),
                      value: f[:last_name].value,
                      "phx-debounce": "blur"
                    )}
                    <.error :for={msg <- get_field_errors(f[:last_name], :last_name)}>
                      {dgettext("user_profile", "Last Name %{msg}", msg: msg)}
                    </.error>
                  </div>
                </div>

                <div class="sm:col-span-3">
                  <label class="block text-sm font-medium leading-6 text-gray-900">
                    {dgettext("user_profile", "Gender")}
                  </label>

                  <div phx-feedback-for={f[:gender].name} class="mt-2">
                    {select(f, :gender, ["Male", "Female"],
                      prompt: dgettext("user_profile", "Select Gender"),
                      class:
                        "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                      value: f[:gender].value,
                      "phx-debounce": "blur"
                    )}
                    <.error :for={msg <- get_field_errors(f[:gender], :gender)}>
                      {dgettext("user_profile", "Gender %{msg}", msg: msg)}
                    </.error>
                  </div>
                </div>

                <div class="sm:col-span-3">
                  <label class="block text-sm font-medium leading-6 text-gray-900">
                    {dgettext("user_profile", "Birthdate")}
                  </label>

                  <div phx-feedback-for={f[:birthdate].name} class="mt-2">
                    {date_input(f, :birthdate,
                      class:
                        "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                      placeholder: dgettext("user_profile", "Birthdate"),
                      value: f[:birthdate].value,
                      "phx-debounce": "blur"
                    )}
                    <.error :for={msg <- get_field_errors(f[:birthdate], :birthdate)}>
                      {dgettext("user_profile", "Birthdate %{msg}", msg: msg)}
                    </.error>
                  </div>
                </div>

                <div class="sm:col-span-3">
                  <label class="block text-sm font-medium leading-6 text-gray-900">
                    {dgettext("user_profile", "Language")}
                  </label>

                  <div phx-feedback-for={f[:lang].name} class="mt-2">
                    {select(f, :lang, @supported_languages,
                      prompt: dgettext("user_profile", "Select Your Language"),
                      class:
                        "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                      "phx-debounce": "blur"
                    )}
                    <.error :for={msg <- get_field_errors(f[:lang], :lang)}>
                      {dgettext("user_profile", "Language %{msg}", msg: msg)}
                    </.error>
                  </div>

                  <div class="mt-6 flex items-center justify-end gap-x-6">
                    {submit(
                      dgettext("user_profile", "Save Profile"),
                      phx_disable_with: dgettext("user_profile", "Saving..."),
                      class:
                        "rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                    )}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </.form>

        <div class="mt-6 flex items-center justify-end gap-x-6">
          <.link
            :if={Ash.can?({@current_user, :destroy}, @current_user)}
            id={"delete-account-#{@current_user.id}"}
            phx-click={JS.push("delete_account", value: %{id: @current_user.id})}
            data-confirm={
              dgettext(
                "user_profile",
                "Are you sure you want to delete your account?"
              )
            }
            class="bg-red-600 hover:bg-red-900 text-white px-3 py-2 rounded-md"
          >
            {dgettext("user_profile", "Delete Account")}
          </.link>
        </div>
      </div>
    </.side_and_topbar>
    """
  end
end
