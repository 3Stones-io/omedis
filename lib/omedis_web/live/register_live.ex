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
    Gettext.put_locale(OmedisWeb.Gettext, language)

    select_language_fields = %{"lang" => ""}

    {:ok,
     socket
     |> assign(:change_language_trigger, false)
     |> assign(current_user: nil)
     |> assign(:errors, [])
     |> assign(:language, language)
     |> assign(:organisations_count, 0)
     |> assign(:select_language_form, to_form(select_language_fields))
     |> assign(:supported_languages, @supported_languages)
     |> assign(trigger_action: false)
     |> assign(:page_title, dgettext("auth", "Register"))
     |> assign_form()}
  end

  @impl true
  def handle_event(
        "validate",
        %{"user" => user_params},
        socket
      ) do
    form = Form.validate(socket.assigns.form, user_params, errors: true)

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("submit", %{"user" => user_params}, socket) do
    form = Form.validate(socket.assigns.form, user_params, errors: true)

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:errors, Form.errors(form))
     |> assign(:trigger_action, form.valid?)}
  end

  def handle_event("change_language", _params, socket) do
    {:noreply, assign(socket, change_language_trigger: true)}
  end

  defp assign_form(socket) do
    assign(
      socket,
      :form,
      Form.for_create(User, :register_with_password, api: Accounts, as: "user")
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

  @impl true
  def render(assigns) do
    ~H"""
    <section class="min-h-screen grid place-items-center py-3">
      <div class="md:w-[60%] w-[90%] mt-3 rounded-lg p-10">
        <div class="md:flex justify-stretch w-full">
          <div class="w-full">
            <div class="lg:col-span-3 flex flex-col">
              <h2 class="text-base font-semibold leading-7 text-gray-900">
                {dgettext("auth", "Register")}
              </h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                {dgettext("auth", "Use a permanent email address where you can receive email.")}
              </p>
            </div>
          </div>
          <div class="mt-2 md:mt-0 w-full px-1">
            <p class="text-base font-semibold leading-7 text-gray-900">
              {dgettext("auth", "Change language")}
            </p>
            <div class="flex items-center space-x-2">
              <.form
                :let={f}
                id="language-form"
                for={@select_language_form}
                class="flex items-center space-x-2 cursor-pointer"
                action={~p"/change_language"}
                phx-trigger-action={@change_language_trigger}
                phx-submit="change_language"
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
                    phx-change={JS.dispatch("click", to: "#language-form-submit")}
                  >
                    <:custom_label>
                      <span class="text-2xl cursor-pointer">
                        {language_to_flag(lang_code)}
                      </span>
                    </:custom_label>
                  </.input>
                <% end %>

                <button id="language-form-submit" type="submit" class="hidden">Submit</button>
              </.form>
            </div>
          </div>
        </div>

        <.form
          :let={f}
          id="basic_user_sign_up_form"
          for={@form}
          class="space-y-2 group"
          phx-change="validate"
          phx-submit="submit"
          action={~p"/auth/user/password/register/"}
          phx-trigger-action={@trigger_action}
          method="POST"
        >
          <div class="space-y-6">
            <div class="border-b border-gray-900/10 pb-12">
              <div class="sm:col-span-3">
                <.input
                  type="email"
                  field={f[:email]}
                  placeholder={dgettext("auth", "Email")}
                  autocomplete="email"
                  required
                  label={dgettext("auth", "Email")}
                />
              </div>

              <div class="sm:col-span-3 mt-8">
                <.input
                  type="password"
                  field={f[:password]}
                  placeholder={dgettext("auth", "Password")}
                  autocomplete={dgettext("auth", "new password")}
                  required
                  label={dgettext("auth", "Password")}
                  phx-debounce="blur"
                />
              </div>
            </div>
            <div class="mt-6 flex items-center justify-end gap-x-6">
              <button
                type="submit"
                class="rounded-md bg-indigo-600 px-6 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
              >
                {dgettext("auth", "Register")}
              </button>
            </div>
          </div>
        </.form>
      </div>
    </section>
    """
  end
end
