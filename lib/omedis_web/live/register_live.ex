defmodule OmedisWeb.RegisterLive do
  alias AshPhoenix.Form
  alias Omedis.Accounts
  alias Omedis.Accounts.Tenant
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
    tenants = Ash.read!(Tenant, authorize?: false)

    socket =
      socket
      |> assign(current_user: nil)
      |> assign(:language, language)
      |> assign(:default_language, language)
      |> assign(:selected_tenant_id, nil)
      |> assign(:supported_languages, @supported_languages)
      |> assign(:tenants, tenants)
      |> assign(:tenants_count, 0)
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

  def handle_event(
        "validate",
        %{"user" => %{"current_tenant_id" => tenant_id} = user_params},
        socket
      ) do
    case tenant_id do
      "" ->
        {:noreply, assign(socket, selected_tenant_id: nil)}

      tenant_id ->
        tenant = Enum.find(socket.assigns.tenants, &(&1.id == tenant_id))

        updated_user_params = update_user_params(user_params, tenant)

        form = Form.validate(socket.assigns.form, updated_user_params, errors: true)

        default_language = user_params["lang"] || socket.assigns.default_language

        {:noreply,
         socket
         |> assign(default_language: default_language)
         |> assign(:selected_tenant_id, tenant_id)
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

  defp update_user_params(user_params, tenant) do
    Map.merge(
      user_params,
      %{
        "daily_start_at" => tenant.default_daily_start_at,
        "daily_end_at" => tenant.default_daily_end_at
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
      current_tenant={nil}
      language={@language}
      tenants_count={@tenants_count}
    >
      <div class="px-4 lg:pl-80 lg:pr-8 py-10">
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
                  <div>
                    <.input
                      type="select"
                      id="select_tenant"
                      field={f[:current_tenant_id]}
                      label={with_locale(@language, fn -> gettext("Select a Tenant") end)}
                      options={Enum.map(@tenants, &{&1.name, &1.id})}
                      prompt={with_locale(@language, fn -> gettext("Select a Tenant") end)}
                      required
                    />
                  </div>
                </div>

                <div class={["sm:col-span-3", @selected_tenant_id == nil && "opacity-50"]}>
                  <.input
                    type="email"
                    disabled={@selected_tenant_id == nil}
                    field={f[:email]}
                    placeholder={with_locale(@language, fn -> gettext("Email") end)}
                    autocomplete="email"
                    required
                    label={with_locale(@language, fn -> gettext("Email") end)}
                  />
                </div>

                <div class={["sm:col-span-3", @selected_tenant_id == nil && "opacity-50"]}>
                  <.input
                    type="text"
                    disabled={@selected_tenant_id == nil}
                    field={f[:first_name]}
                    placeholder={with_locale(@language, fn -> gettext("First Name") end)}
                    required
                    label={with_locale(@language, fn -> gettext("First Name") end)}
                    phx-debounce="blur"
                  />
                </div>

                <div class={["sm:col-span-3", @selected_tenant_id == nil && "opacity-50"]}>
                  <.input
                    type="text"
                    disabled={@selected_tenant_id == nil}
                    field={f[:last_name]}
                    placeholder={with_locale(@language, fn -> gettext("Last Name") end)}
                    required
                    label={with_locale(@language, fn -> gettext("Last Name") end)}
                    phx-debounce="blur"
                  />
                </div>

                <div class={["sm:col-span-3", @selected_tenant_id == nil && "opacity-50"]}>
                  <.input
                    type="password"
                    disabled={@selected_tenant_id == nil}
                    field={f[:password]}
                    placeholder={with_locale(@language, fn -> gettext("Password") end)}
                    autocomplete={gettext("new password")}
                    required
                    label={with_locale(@language, fn -> gettext("Password") end)}
                    phx-debounce="blur"
                  />
                </div>

                <div class={["sm:col-span-3", @selected_tenant_id == nil && "opacity-50"]}>
                  <.input
                    type="select"
                    disabled={@selected_tenant_id == nil}
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

                <div class={["sm:col-span-3", @selected_tenant_id == nil && "opacity-50"]}>
                  <.input
                    type="date"
                    disabled={@selected_tenant_id == nil}
                    field={f[:birthdate]}
                    required
                    label={with_locale(@language, fn -> gettext("Birthdate") end)}
                    phx-debounce="blur"
                  />
                </div>

                <div class={["sm:col-span-3", @selected_tenant_id == nil && "opacity-50"]}>
                  <label class="block text-sm font-medium leading-6 text-gray-900">
                    <%= with_locale(@language, fn -> %>
                      <%= gettext("Language") %>
                    <% end) %>
                  </label>

                  <div phx-feedback-for={f[:lang].name} class="mt-2">
                    <%= select(f, :lang, @supported_languages,
                      prompt: with_locale(@language, fn -> gettext("Select Your Language") end),
                      value: @default_language,
                      disabled: @selected_tenant_id == nil,
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

                <div class={["sm:col-span-3", @selected_tenant_id == nil && "opacity-50"]}>
                  <label class="block text-sm font-medium leading-6 text-gray-900">
                    <%= with_locale(@language, fn -> %>
                      <%= gettext("Daily Start Time") %>
                    <% end) %>
                  </label>

                  <div phx-feedback-for={f[:daily_start_at].name} class="mt-2">
                    <%= time_input(f, :daily_start_at,
                      class:
                        "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                      value: f[:daily_start_at].value,
                      disabled: @selected_tenant_id == nil,
                      "phx-debounce": "blur"
                    ) %>
                    <.error :for={msg <- get_field_errors(f[:daily_start_at], :daily_start_at)}>
                      <%= with_locale(@language, fn -> %>
                        <%= gettext("Daily Start Time") <> " " <> msg %>
                      <% end) %>
                    </.error>
                  </div>
                </div>

                <div class={["sm:col-span-3", @selected_tenant_id == nil && "opacity-50"]}>
                  <label class="block text-sm font-medium leading-6 text-gray-900">
                    <%= with_locale(@language, fn -> %>
                      <%= gettext("Daily End Time") %>
                    <% end) %>
                  </label>

                  <div phx-feedback-for={f[:daily_end_at].name} class="mt-2">
                    <%= time_input(f, :daily_end_at,
                      class:
                        "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                      value: f[:daily_end_at].value,
                      disabled: @selected_tenant_id == nil,
                      "phx-debounce": "blur"
                    ) %>
                    <.error :for={msg <- get_field_errors(f[:daily_start_at], :daily_end_at)}>
                      <%= with_locale(@language, fn -> %>
                        <%= gettext("Daily End Time") <> " " <> msg %>
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
                disabled: @selected_tenant_id == nil,
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
