defmodule OmedisWeb.RegisterLive do
  alias AshPhoenix.Form
  alias Omedis.Accounts
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
    socket =
      socket
      |> assign(current_user: nil)
      |> assign(:language, language)
      |> assign(:default_language, language)
      |> assign(:supported_languages, @supported_languages)
      |> assign(trigger_action: false)
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
      with_locale(socket.assigns.language, fn -> gettext("Sign up") end)
    )
    |> assign(:action, "/auth/user/password/register/")
    |> assign(
      :form,
      Form.for_create(User, :register_with_password, api: Accounts, as: "user")
    )
  end

  @impl true
  def handle_event("change_language", %{"language" => language}, socket) do
    {
      :noreply,
      socket
      |> assign(:language, language)
      |> put_flash(
        :info,
        with_locale(language, fn -> gettext("Language changed") end)
      )
    }
  end

  def handle_event("validate", %{"user" => user}, socket) do
    form = Form.validate(socket.assigns.form, user, errors: true)

    default_language = user["lang"] || socket.assigns.default_language

    {:noreply,
     socket
     |> assign(default_language: default_language)
     |> assign(form: form)}
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
          <div class="grid grid-cols-2 lg:grid-cols-6 gap-x-2 lg:gap-x-6">
            <div class="lg:col-span-3 flex flex-col">
              <h2 class="text-base font-semibold leading-7 text-gray-900">
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Register") %>
                <% end) %>
              </h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Use a permanent address where you can receive mail.") %>
                <% end) %>
              </p>
            </div>
            <div class="lg:col-span-3 flex flex-col space-x-2 items-end md:items-start">
              <p class="text-base font-semibold leading-7 text-gray-900">
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Change language") %>
                <% end) %>
              </p>
              <div class="flex items-center space-x-2">
                <%= for {_language, lang_code} <- @supported_languages do %>
                  <button
                    class={"text-2xl #{if @language == lang_code, do: "opacity-100", else: "opacity-50 hover:opacity-75"}"}
                    phx-click="change_language"
                    phx-value-language={lang_code}
                    type="button"
                  >
                    <%= language_to_flag(lang_code) %>
                  </button>
                <% end %>
              </div>
            </div>
          </div>
          <div class="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
            <div class="sm:col-span-3">
              <label class="block text-sm font-medium leading-6 text-gray-900">
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Email") %>
                <% end) %>
              </label>
              <div phx-feedback-for={f[:email].name} class="mt-2">
                <%= text_input(f, :email,
                  class:
                    "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                  placeholder: with_locale(@language, fn -> gettext("Email") end),
                  value: f[:email].value,
                  required: true,
                  autocomplete: :email,
                  "phx-debounce": "200"
                ) %>
                <.error :for={msg <- get_field_errors(f[:email], :email)}>
                  <%= with_locale(@language, fn -> %>
                    <%= gettext("Email") <> " " <> msg %>
                  <% end) %>
                </.error>
              </div>
            </div>

            <div class="sm:col-span-3">
              <label class="block text-sm font-medium leading-6 text-gray-900">
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Password") %>
                <% end) %>
              </label>

              <div phx-feedback-for={f[:password].name} class="mt-2">
                <%= password_input(f, :password,
                  class:
                    "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                  placeholder: with_locale(@language, fn -> gettext("Password") end),
                  value: f[:password].value,
                  autocomplete: gettext("new password"),
                  "phx-debounce": "blur"
                ) %>
                <.error :for={msg <- get_field_errors(f[:password], :password)}>
                  <%= with_locale(@language, fn -> %>
                    <%= gettext("Password") <> " " <> msg %>
                  <% end) %>
                </.error>
              </div>
            </div>

            <div class="sm:col-span-3">
              <label class="block text-sm font-medium leading-6 text-gray-900">
                <%= with_locale(@language, fn -> %>
                  <%= gettext("First Name") %>
                <% end) %>
              </label>

              <div phx-feedback-for={f[:first_name].name} class="mt-2">
                <%= text_input(f, :first_name,
                  class:
                    "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                  placeholder: with_locale(@language, fn -> gettext("First Name") end),
                  value: f[:first_name].value,
                  "phx-debounce": "blur"
                ) %>
                <.error :for={msg <- get_field_errors(f[:first_name], :first_name)}>
                  <%= with_locale(@language, fn -> %>
                    <%= gettext("First Name") <> " " <> msg %>
                  <% end) %>
                </.error>
              </div>
            </div>

            <div class="sm:col-span-3">
              <label class="block text-sm font-medium leading-6 text-gray-900">
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Last Name") %>
                <% end) %>
              </label>
              <div phx-feedback-for={f[:last_name].name} class="mt-2">
                <%= text_input(f, :last_name,
                  class:
                    "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                  placeholder: with_locale(@language, fn -> gettext("Last Name") end),
                  value: f[:last_name].value,
                  "phx-debounce": "blur"
                ) %>
                <.error :for={msg <- get_field_errors(f[:last_name], :last_name)}>
                  <%= with_locale(@language, fn -> %>
                    <%= gettext("Last Name") <> " " <> msg %>
                  <% end) %>
                </.error>
              </div>
            </div>

            <div class="sm:col-span-3">
              <label class="block text-sm font-medium leading-6 text-gray-900">
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Gender") %>
                <% end) %>
              </label>

              <div phx-feedback-for={f[:gender].name} class="mt-2">
                <%= select(f, :gender, ["Male", "Female"],
                  prompt: with_locale(@language, fn -> gettext("Select Your Gender") end),
                  class:
                    "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                  value: f[:gender].value,
                  "phx-debounce": "blur"
                ) %>
                <.error :for={msg <- get_field_errors(f[:gender], :gender)}>
                  <%= with_locale(@language, fn -> %>
                    <%= gettext("Gender") <> " " <> msg %>
                  <% end) %>
                </.error>
              </div>
            </div>

            <div class="sm:col-span-3">
              <label class="block text-sm font-medium leading-6 text-gray-900">
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Birthdate") %>
                <% end) %>
              </label>

              <div phx-feedback-for={f[:birthdate].name} class="mt-2">
                <%= date_input(f, :birthdate,
                  class:
                    "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                  value: f[:birthdate].value,
                  "phx-debounce": "blur"
                ) %>
                <.error :for={msg <- get_field_errors(f[:birthdate], :birthdate)}>
                  <%= with_locale(@language, fn -> %>
                    <%= gettext("Birthdate") <> " " <> msg %>
                  <% end) %>
                </.error>
              </div>
            </div>

            <div class="sm:col-span-3">
              <label class="block text-sm font-medium leading-6 text-gray-900">
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Language") %>
                <% end) %>
              </label>

              <div phx-feedback-for={f[:lang].name} class="mt-2">
                <%= select(f, :lang, @supported_languages,
                  prompt: with_locale(@language, fn -> gettext("Select Your Language") end),
                  value: @default_language,
                  class:
                    "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                  "phx-debounce": "blur"
                ) %>
                <.error :for={msg <- get_field_errors(f[:lang], :lang)}>
                  <%= with_locale(@language, fn -> %>
                    <%= gettext("Language") <> " " <> msg %>
                  <% end) %>
                </.error>
              </div>
            </div>
          </div>

          <div class="w-[100%] flex mt-6 justify-between items-center">
            <.link navigate="/login">
              <p class="block text-sm leading-6 text-blue-600 transition-all duration-500 ease-in-out hover:text-blue-500 dark:hover:text-blue-500 hover:cursor-pointer hover:underline">
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Don't have an account? Sign up") %>
                <% end) %>
              </p>
            </.link>
          </div>
        </div>

        <div class="mt-6 flex items-center justify-end gap-x-6">
          <%= submit(with_locale(@language, fn -> gettext("Sign up") end),
            phx_disable_with: with_locale(@language, fn -> gettext("Signing up...") end),
            class:
              "rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
          ) %>
        </div>
      </div>
    </.form>
    """
  end
end
