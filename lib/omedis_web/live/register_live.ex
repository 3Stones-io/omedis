defmodule OmedisWeb.RegisterLive do
  alias AshPhoenix.Form
  alias Omedis.Accounts
  alias Omedis.Accounts.Organisation
  alias Omedis.Accounts.User

  @supported_languages [
    {"English", "en"},
    {"Deutsch", "de"},
    {"Français", "fr"},
    {"Italiano", "it"}
  ]

  use OmedisWeb, :live_view

  @impl true
  def mount(_params, %{"language" => language} = _session, socket) do
    organisations = Ash.read!(Organisation, authorize?: false)
    Gettext.put_locale(OmedisWeb.Gettext, language)

    select_language_fields = %{"lang" => ""}

    socket =
      socket
      |> assign(current_user: nil)
      |> assign(:select_language_form, to_form(select_language_fields))
      |> assign(:language, language)
      |> assign(:selected_organisation_id, nil)
      |> assign(:supported_languages, @supported_languages)
      |> assign(:organisations, organisations)
      |> assign(:organisations_count, 0)
      |> assign(trigger_action: false)
      |> assign(:change_language_trigger, false)
      |> assign(:errors, [])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(
      :page_title,
      with_locale(socket.assigns.language, fn ->
        dpgettext("auth", "register_page_title", "Register")
      end)
    )
    |> assign(:action, "/auth/user/password/register/")
    |> assign(
      :form,
      Form.for_create(User, :register_with_password, api: Accounts, as: "user")
    )
  end

  @impl true
  def handle_event(
        "validate",
        %{"user" => %{"current_organisation_id" => organisation_id} = user_params},
        socket
      ) do
    case organisation_id do
      "" ->
        {:noreply, assign(socket, selected_organisation_id: nil)}

      organisation_id ->
        organisation = Enum.find(socket.assigns.organisations, &(&1.id == organisation_id))

        updated_user_params = update_user_params(user_params, organisation)

        form = Form.validate(socket.assigns.form, updated_user_params, errors: true)

        {:noreply,
         socket
         |> assign(:selected_organisation_id, organisation_id)
         |> assign(:form, form)}
    end
  end

  @impl true
  def handle_event("submit", %{"user" => user}, socket) do
    form = Form.validate(socket.assigns.form, user)

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:errors, Form.errors(form))
     |> assign(:trigger_action, form.valid?)}
  end

  def handle_event("change_language", _params, socket) do
    {:noreply, assign(socket, change_language_trigger: true)}
  end

  defp update_user_params(user_params, organisation) do
    Map.merge(
      user_params,
      %{
        "daily_start_at" => organisation.default_daily_start_at,
        "daily_end_at" => organisation.default_daily_end_at
      },
      fn _k, v1, v2 ->
        if Map.has_key?(user_params, "_unused_daily_start_at") ||
             Map.has_key?(user_params, "_unused_daily_end_at") do
          v2
        else
          v1
        end
      end
    )
  end

  defp language_to_flag(language) do
    case language do
      "de" -> "🇩🇪"
      "fr" -> "🇫🇷"
      "it" -> "🇮🇹"
      "en" -> "🇬🇧"
      _ -> nil
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
      current_organisation={nil}
      language={@language}
      organisations_count={@organisations_count}
    >
      <div class="px-4 lg:pl-80 lg:pr-8 py-10">
        <div class="flex justify-stretch w-full">
          <div class="w-full">
            <div class="lg:col-span-3 flex flex-col">
              <h2 class="text-base font-semibold leading-7 text-gray-900">
                <%= with_locale(@language, fn -> %>
                  <%= dpgettext("auth", "register_page_title", "Register") %>
                <% end) %>
              </h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                <%= with_locale(@language, fn -> %>
                  <%= dpgettext(
                    "auth",
                    "register_page_title",
                    "Use a permanent address where you can receive mail."
                  ) %>
                <% end) %>
              </p>
            </div>
          </div>
          <div class="w-full px-1">
            <p class="text-base font-semibold leading-7 text-gray-900">
              <%= with_locale(@language, fn -> %>
                <%= dpgettext("auth", "register_form", "Change language") %>
              <% end) %>
            </p>
            <div class="flex items-center space-x-2">
              <.form
                :let={f}
                id="language_form"
                for={@select_language_form}
                class="flex items-center space-x-2 cursor-pointer"
                action={~p"/change_language"}
                phx-trigger-action={@change_language_trigger}
              >
                <%= for {language, lang_code} <- @supported_languages do %>
                  <.input
                    field={f[:lang]}
                    id={language}
                    type="radio"
                    value={lang_code}
                    checked={input_value(f, :lang) == language}
                    label_type="custom_label"
                    input_class="hidden"
                    phx-change="change_language"
                  >
                    <:custom_label>
                      <span class="text-2xl cursor-pointer">
                        <%= language_to_flag(lang_code) %>
                      </span>
                    </:custom_label>
                  </.input>
                <% end %>
              </.form>
            </div>
          </div>
        </div>
        <.form
          :let={f}
          id="basic_user_sign_up_form"
          for={@form}
          action={@action}
          phx-trigger-action={@trigger_action}
          method="POST"
          class="space-y-2 group"
          phx-change="validate"
          phx-submit="submit"
        >
          <div class="space-y-6">
            <div class="border-b border-gray-900/10 pb-12">
              <div class="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
                <div class="sm:col-span-3">
                  <div>
                    <.input
                      type="select"
                      id="select_organisation"
                      field={f[:current_organisation_id]}
                      label={
                        with_locale(@language, fn ->
                          dpgettext("auth", "register_form", "Select an Organisation")
                        end)
                      }
                      options={Enum.map(@organisations, &{&1.name, &1.id})}
                      prompt={
                        with_locale(@language, fn ->
                          dpgettext("auth", "register_form", "Select an Organisation")
                        end)
                      }
                      required
                    />
                  </div>
                </div>

                <div class={["sm:col-span-3", @selected_organisation_id == nil && "opacity-50"]}>
                  <.input
                    type="email"
                    disabled={@selected_organisation_id == nil}
                    field={f[:email]}
                    placeholder={
                      with_locale(@language, fn -> dpgettext("auth", "register_form", "Email") end)
                    }
                    autocomplete="email"
                    required
                    label={
                      with_locale(@language, fn -> dpgettext("auth", "register_form", "Email") end)
                    }
                  />
                </div>

                <div class={["sm:col-span-3", @selected_organisation_id == nil && "opacity-50"]}>
                  <.input
                    type="text"
                    disabled={@selected_organisation_id == nil}
                    field={f[:first_name]}
                    placeholder={
                      with_locale(@language, fn ->
                        dpgettext("auth", "register_form", "First Name")
                      end)
                    }
                    required
                    label={
                      with_locale(@language, fn ->
                        dpgettext("auth", "register_form", "First Name")
                      end)
                    }
                    phx-debounce="blur"
                  />
                </div>

                <div class={["sm:col-span-3", @selected_organisation_id == nil && "opacity-50"]}>
                  <.input
                    type="text"
                    disabled={@selected_organisation_id == nil}
                    field={f[:last_name]}
                    placeholder={
                      with_locale(@language, fn -> dpgettext("auth", "register_form", "Last Name") end)
                    }
                    required
                    label={
                      with_locale(@language, fn -> dpgettext("auth", "register_form", "Last Name") end)
                    }
                    phx-debounce="blur"
                  />
                </div>

                <div class={["sm:col-span-3", @selected_organisation_id == nil && "opacity-50"]}>
                  <.input
                    type="password"
                    disabled={@selected_organisation_id == nil}
                    field={f[:password]}
                    placeholder={
                      with_locale(@language, fn -> dpgettext("auth", "register_form", "Password") end)
                    }
                    autocomplete={dpgettext("auth", "register_form", "new password")}
                    required
                    label={
                      with_locale(@language, fn -> dpgettext("auth", "register_form", "Password") end)
                    }
                    phx-debounce="blur"
                  />
                </div>

                <div class={["sm:col-span-3", @selected_organisation_id == nil && "opacity-50"]}>
                  <.input
                    type="select"
                    disabled={@selected_organisation_id == nil}
                    field={f[:gender]}
                    required
                    label={
                      with_locale(@language, fn -> dpgettext("auth", "register_form", "Gender") end)
                    }
                    options={[
                      with_locale(@language, fn -> dpgettext("auth", "register_form", "Male") end),
                      with_locale(@language, fn -> dpgettext("auth", "register_form", "Female") end)
                    ]}
                    prompt={
                      with_locale(@language, fn ->
                        dpgettext("auth", "register_form", "Select Your Gender")
                      end)
                    }
                  />
                </div>

                <div class={["sm:col-span-3", @selected_organisation_id == nil && "opacity-50"]}>
                  <.input
                    type="date"
                    disabled={@selected_organisation_id == nil}
                    field={f[:birthdate]}
                    required
                    label={
                      with_locale(@language, fn -> dpgettext("auth", "register_form", "Birthdate") end)
                    }
                    phx-debounce="blur"
                  />
                </div>

                <div class={["sm:col-span-3", @selected_organisation_id == nil && "opacity-50"]}>
                  <label class="block text-sm font-medium leading-6 text-gray-900">
                    <%= with_locale(@language, fn -> %>
                      <%= dpgettext("auth", "register_form", "Daily Start Time") %>
                    <% end) %>
                  </label>

                  <div phx-feedback-for={f[:daily_start_at].name} class="mt-2">
                    <%= time_input(f, :daily_start_at,
                      class:
                        "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                      value: f[:daily_start_at].value,
                      disabled: @selected_organisation_id == nil,
                      "phx-debounce": "blur"
                    ) %>
                    <.error :for={msg <- get_field_errors(f[:daily_start_at], :daily_start_at)}>
                      <%= with_locale(@language, fn -> %>
                        <%= dpgettext("auth", "register_form", "Daily Start Time") <> " " <> msg %>
                      <% end) %>
                    </.error>
                  </div>
                </div>

                <div class={["sm:col-span-3", @selected_organisation_id == nil && "opacity-50"]}>
                  <label class="block text-sm font-medium leading-6 text-gray-900">
                    <%= with_locale(@language, fn -> %>
                      <%= dpgettext("auth", "register_form", "Daily End Time") %>
                    <% end) %>
                  </label>

                  <div phx-feedback-for={f[:daily_end_at].name} class="mt-2">
                    <%= time_input(f, :daily_end_at,
                      class:
                        "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                      value: f[:daily_end_at].value,
                      disabled: @selected_organisation_id == nil,
                      "phx-debounce": "blur"
                    ) %>
                    <.error :for={msg <- get_field_errors(f[:daily_start_at], :daily_end_at)}>
                      <%= with_locale(@language, fn -> %>
                        <%= dpgettext("auth", "register_form", "Daily End Time") <> " " <> msg %>
                      <% end) %>
                    </.error>
                  </div>
                </div>
              </div>

              <div class="w-[100%] flex mt-6 justify-between items-center">
                <.link navigate="/login">
                  <p class="block text-sm leading-6 text-blue-600 transition-all duration-500 ease-in-out hover:text-blue-500 dark:hover:text-blue-500 hover:cursor-pointer hover:underline">
                    <%= with_locale(@language, fn -> %>
                      <%= dpgettext("auth", "register_form", "Don't have an account? Sign up") %>
                    <% end) %>
                  </p>
                </.link>
              </div>
            </div>

            <div class="mt-6 flex items-center justify-end gap-x-6">
              <%= submit(
                with_locale(@language, fn -> dpgettext("auth", "register_action", "Sign up") end),
                phx_disable_with:
                  with_locale(@language, fn ->
                    dpgettext("auth", "register_action", "Signing up...")
                  end),
                disabled: @selected_organisation_id == nil,
                class:
                  "rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
              ) %>
            </div>
          </div>

          <.input type="hidden" field={f[:lang]} value={@language} />
        </.form>
      </div>
    </.side_and_topbar>
    """
  end
end
