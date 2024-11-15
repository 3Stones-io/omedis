defmodule OmedisWeb.EditProfileLive do
  alias AshPhoenix.Form
  alias Omedis.Accounts.Organisation

  use OmedisWeb, :live_view

  @supported_languages [
    {"English", "en"},
    {"Deutsch", "de"},
    {"Français", "fr"},
    {"Italiano", "it"}
  ]

  @impl true
  def mount(_params, %{"language" => language} = _session, socket) do
    Gettext.put_locale(language)
    organisations_for_an_owner = organisations_for_an_owner(socket.assigns.current_user)

    socket =
      socket
      |> assign(:organisations_for_an_owner, organisations_for_an_owner)
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
      dpgettext("user_profile", "user_profile", "Update Profile")
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
            with_locale(user.lang, fn ->
              dpgettext("user_profile", "profile_edit_status", "Profile updated successfully")
            end)
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
           with_locale(socket.assigns.language, fn ->
             dpgettext("user_profile", "profile_edit_status", "Profile update failed")
           end)
         )}
    end
  end

  defp get_field_errors(field, _name) do
    Enum.map(field.errors, &translate_error(&1))
  end

  defp organisations_for_an_owner(owner) do
    case Organisation.by_owner_id(%{owner_id: owner.id}, actor: owner) do
      {:ok, organisations} ->
        Enum.map(organisations, fn organisation ->
          {organisation.name, organisation.id}
        end)

      _ ->
        []
    end
  end

  @impl true

  def render(assigns) do
    ~H"""
    <.side_and_topbar
      current_user={@current_user}
      current_organisation={@current_organisation}
      language={@language}
      organisations_count={@organisations_count}
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
          <div class="space-y-6">
            <div class="border-b border-gray-900/10 pb-12">
              <h2 class="text-base font-semibold leading-7 text-gray-900">
                <%= with_locale(@language, fn ->
                  dpgettext("user_profile", "user_profile", "Update Profile")
                end) %>
              </h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                <%= with_locale(@language, fn ->
                  dpgettext("user_profile", "profile_edit_page_title", "Edit your profile details")
                end) %>
              </p>
              <div class="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
                <div class="sm:col-span-3">
                  <label class="block text-sm font-medium leading-6 text-gray-900">
                    <%= with_locale(@language, fn ->
                      dpgettext("user_profile", "profile_edit_form", "First Name")
                    end) %>
                  </label>

                  <div phx-feedback-for={f[:first_name].name} class="mt-2">
                    <%= text_input(f, :first_name,
                      class:
                        "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                      placeholder:
                        with_locale(@language, fn ->
                          dpgettext("user_profile", "profile_edit_form", "First Name")
                        end),
                      value: f[:first_name].value,
                      "phx-debounce": "blur"
                    ) %>
                    <.error :for={msg <- get_field_errors(f[:first_name], :first_name)}>
                      <%= with_locale(@language, fn ->
                        dpgettext("user_profile", "profile_edit_form", "First Name %{msg}", msg: msg)
                      end) %>
                    </.error>
                  </div>
                </div>

                <div class="sm:col-span-3">
                  <label class="block text-sm font-medium leading-6 text-gray-900">
                    <%= with_locale(@language, fn ->
                      dpgettext("user_profile", "profile_edit_form", "Last Name")
                    end) %>
                  </label>
                  <div phx-feedback-for={f[:last_name].name} class="mt-2">
                    <%= text_input(f, :last_name,
                      class:
                        "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                      placeholder:
                        with_locale(@language, fn ->
                          dpgettext("user_profile", "profile_edit_form", "Last Name")
                        end),
                      value: f[:last_name].value,
                      "phx-debounce": "blur"
                    ) %>
                    <.error :for={msg <- get_field_errors(f[:last_name], :last_name)}>
                      <%= with_locale(@language, fn ->
                        dpgettext("user_profile", "profile_edit_form", "Last Name %{msg}", msg: msg)
                      end) %>
                    </.error>
                  </div>
                </div>

                <div class="sm:col-span-3">
                  <label class="block text-sm font-medium leading-6 text-gray-900">
                    <%= with_locale(@language, fn ->
                      dpgettext("user_profile", "profile_edit_form", "Gender")
                    end) %>
                  </label>

                  <div phx-feedback-for={f[:gender].name} class="mt-2">
                    <%= select(f, :gender, ["Male", "Female"],
                      prompt:
                        with_locale(@language, fn ->
                          dpgettext("user_profile", "profile_edit_form", "Select Gender")
                        end),
                      class:
                        "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                      value: f[:gender].value,
                      "phx-debounce": "blur"
                    ) %>
                    <.error :for={msg <- get_field_errors(f[:gender], :gender)}>
                      <%= with_locale(@language, fn ->
                        dpgettext("user_profile", "profile_edit_form", "Gender %{msg}", msg: msg)
                      end) %>
                    </.error>
                  </div>
                </div>

                <div class="sm:col-span-3">
                  <label class="block text-sm font-medium leading-6 text-gray-900">
                    <%= with_locale(@language, fn ->
                      dpgettext("user_profile", "profile_edit_form", "Birthdate")
                    end) %>
                  </label>

                  <div phx-feedback-for={f[:birthdate].name} class="mt-2">
                    <%= date_input(f, :birthdate,
                      class:
                        "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                      placeholder:
                        with_locale(@language, fn ->
                          dpgettext("user_profile", "profile_edit_form", "Birthdate")
                        end),
                      value: f[:birthdate].value,
                      "phx-debounce": "blur"
                    ) %>
                    <.error :for={msg <- get_field_errors(f[:birthdate], :birthdate)}>
                      <%= with_locale(@language, fn ->
                        dpgettext("user_profile", "profile_edit_form", "Birthdate %{msg}", msg: msg)
                      end) %>
                    </.error>
                  </div>
                </div>

                <div class="sm:col-span-3">
                  <label class="block text-sm font-medium leading-6 text-gray-900">
                    <%= with_locale(@language, fn ->
                      dpgettext("user_profile", "profile_edit_form", "Current Organisation")
                    end) %>
                  </label>

                  <div phx-feedback-for={f[:current_organisation_id].name} class="mt-2">
                    <%= select(f, :current_organisation_id, @organisations_for_an_owner,
                      prompt:
                        with_locale(@language, fn ->
                          dpgettext("user_profile", "profile_edit_form", "Select Organisation")
                        end),
                      class:
                        "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                      value: f[:current_organisation_id].value,
                      "phx-debounce": "blur"
                    ) %>
                    <.error :for={
                      msg <- get_field_errors(f[:current_organisation_id], :current_organisation_id)
                    }>
                      <%= with_locale(@language, fn ->
                        dpgettext("user_profile", "profile_edit_form", "Current Organisation %{msg}",
                          msg: msg
                        )
                      end) %>
                    </.error>
                  </div>
                </div>

                <div class="sm:col-span-3">
                  <label class="block text-sm font-medium leading-6 text-gray-900">
                    <%= with_locale(@language, fn ->
                      dpgettext("user_profile", "profile_edit_form", "Language")
                    end) %>
                  </label>

                  <div phx-feedback-for={f[:lang].name} class="mt-2">
                    <%= select(f, :lang, @supported_languages,
                      prompt:
                        with_locale(@language, fn ->
                          dpgettext("user_profile", "profile_edit_form", "Select Your Language")
                        end),
                      class:
                        "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                      "phx-debounce": "blur"
                    ) %>
                    <.error :for={msg <- get_field_errors(f[:lang], :lang)}>
                      <%= with_locale(@language, fn ->
                        dpgettext("user_profile", "profile_edit_form", "Language %{msg}", msg: msg)
                      end) %>
                    </.error>
                  </div>
                </div>
              </div>
            </div>

            <div class="mt-6 flex items-center justify-end gap-x-6">
              <%= submit(
                with_locale(@language, fn ->
                  dpgettext("user_profile", "profile_edit_action", "Save Profile")
                end),
                phx_disable_with:
                  with_locale(@language, fn ->
                    dpgettext("user_profile", "profile_edit_action", "Saving...")
                  end),
                class:
                  "rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
              ) %>
            </div>
          </div>
        </.form>
      </div>
    </.side_and_topbar>
    """
  end
end
