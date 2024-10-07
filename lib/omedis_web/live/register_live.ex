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
              <.input
                type="email"
                field={f[:email]}
                placeholder={with_locale(@language, fn -> gettext("Email") end)}
                autocomplete="email"
                required
                label={with_locale(@language, fn -> gettext("Email") end)}
              />
            </div>

            <div class="sm:col-span-3">
              <.input
                type="password"
                field={f[:password]}
                placeholder={with_locale(@language, fn -> gettext("Password") end)}
                autocomplete={gettext("new password")}
                required
                label={with_locale(@language, fn -> gettext("Password") end)}
                phx-debounce="blur"
              />
            </div>

            <div class="sm:col-span-3">
              <.input
                type="text"
                field={f[:first_name]}
                placeholder={with_locale(@language, fn -> gettext("First Name") end)}
                required
                label={with_locale(@language, fn -> gettext("First Name") end)}
                phx-debounce="blur"
              />
            </div>

            <div class="sm:col-span-3">
              <.input
                type="text"
                field={f[:last_name]}
                placeholder={with_locale(@language, fn -> gettext("Last Name") end)}
                required
                label={with_locale(@language, fn -> gettext("Last Name") end)}
                phx-debounce="blur"
              />
            </div>

            <div class="sm:col-span-3">
              <.input
                type="select"
                field={f[:gender]}
                required
                label={with_locale(@language, fn -> gettext("Gender") end)}
                options={[
                  with_locale(@language, fn -> gettext("Male") end),
                  with_locale(@language, fn -> gettext("Female") end)
                ]}
                prompt={with_locale(@language, fn -> gettext("Select Your Gender") end)}
              />
            </div>

            <div class="sm:col-span-3">
              <.input
                type="date"
                field={f[:birthdate]}
                required
                label={with_locale(@language, fn -> gettext("Birthdate") end)}
                phx-debounce="blur"
              />
            </div>

            <div class="sm:col-span-3">
              <.input
                type="select"
                field={f[:lang]}
                required
                label={with_locale(@language, fn -> gettext("Gender") end)}
                options={@supported_languages}
                prompt={with_locale(@language, fn -> gettext("Select Your Language") end)}
                value={@default_language}
                phx-debounce="blur"
              />
            </div>
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
