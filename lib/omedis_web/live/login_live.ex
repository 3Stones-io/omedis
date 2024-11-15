defmodule OmedisWeb.LoginLive do
  alias AshPhoenix.Form
  alias Omedis.Accounts
  alias Omedis.Accounts.User

  use OmedisWeb, :live_view

  on_mount {OmedisWeb.LiveHelpers, :assign_locale}

  @impl true
  def mount(_params, %{"language" => language} = _session, socket) do
    socket =
      socket
      |> assign(current_user: nil)
      |> assign(:language, language)
      |> assign(:organisations_count, 0)
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
      with_locale(socket.assigns.language, fn -> dpgettext("auth", "auth", "Sign in") end)
    )
    |> assign(:action, "/auth/user/password/sign_in/")
    |> assign(
      :form,
      Form.for_action(User, :sign_in_with_password, api: Accounts, as: "user")
    )
  end

  @impl true
  def handle_event("validate", %{"user" => user}, socket) do
    form = Form.validate(socket.assigns.form, user, errors: true)

    {:noreply, socket |> assign(form: form)}
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
        <.form
          :let={f}
          id="basic_user_sign_in_form"
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
              <h2 class="text-base font-semibold leading-7 text-gray-900">
                <%= with_locale(@language, fn -> dpgettext("auth", "auth", "Sign in") end) %>
              </h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                <%= with_locale(@language, fn ->
                  dpgettext("auth", "auth", "Use your credentials to sign in")
                end) %>
              </p>

              <div>
                <label class="block text-sm font-medium leading-6 text-gray-900">
                  <%= with_locale(@language, fn -> dpgettext("auth", "login_form", "Email") end) %>
                </label>
                <div phx-feedback-for={f[:email].name} class="mt-2">
                  <%= text_input(f, :email,
                    class:
                      "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                    placeholder:
                      with_locale(@language, fn -> dpgettext("auth", "login_form", "Email") end),
                    value: f[:email].value,
                    required: true,
                    autocomplete: :email,
                    "phx-debounce": "200"
                  ) %>
                  <.error :for={msg <- get_field_errors(f[:email], :email)}>
                    <%= with_locale(@language, fn ->
                      dpgettext("auth", "login_form", "Email") <> " " <> msg
                    end) %>
                  </.error>
                </div>
              </div>

              <div>
                <label class="block text-sm font-medium leading-6 text-gray-900">
                  <%= with_locale(@language, fn -> dpgettext("auth", "login_form", "Password") end) %>
                </label>

                <div phx-feedback-for={f[:password].name} class="mt-2">
                  <%= password_input(f, :password,
                    class:
                      "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                    placeholder:
                      with_locale(@language, fn -> dpgettext("auth", "login_form", "Password") end),
                    value: f[:password].value,
                    autocomplete: dpgettext("auth", "login_form", "new password"),
                    "phx-debounce": "blur"
                  ) %>
                  <.error :for={msg <- get_field_errors(f[:password], :password)}>
                    <%= with_locale(@language, fn ->
                      dpgettext("auth", "login_form", "Password") <> " " <> msg
                    end) %>
                  </.error>
                </div>
              </div>

              <div class="mt-6 flex items-center justify-end gap-x-6">
                <%= submit(
                  with_locale(@language, fn -> dpgettext("auth", "login_action", "Signing in...") end),
                  phx_disable_with:
                    with_locale(@language, fn ->
                      dpgettext("auth", "login_action", "Signing in...")
                    end),
                  class:
                    "rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                ) %>
              </div>
            </div>
          </div>
        </.form>
      </div>
    </.side_and_topbar>
    """
  end
end
