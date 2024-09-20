defmodule OmedisWeb.RegisterLive do
  alias AshPhoenix.Form
  alias Omedis.Accounts
  alias Omedis.Accounts.User

  use OmedisWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(current_user: nil)
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
      "Register"
    )
    |> assign(:action, "/auth/user/password/register/")
    |> assign(
      :form,
      Form.for_create(User, :register_with_password, api: Accounts, as: "user")
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
          <h2 class="text-base font-semibold leading-7 text-gray-900">
            Register
          </h2>
          <p class="mt-1 text-sm leading-6 text-gray-600">
            Use a permanent address where you can receive mail.
          </p>
          <div class="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
            <div class="sm:col-span-3">
              <label class="block text-sm font-medium leading-6 text-gray-900">
                E-mail
              </label>
              <div phx-feedback-for={f[:email].name} class="mt-2">
                <%= text_input(f, :email,
                  class:
                    "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                  placeholder: "E-mail",
                  value: f[:email].value,
                  required: true,
                  autocomplete: :email,
                  "phx-debounce": "200"
                ) %>
                <.error :for={msg <- get_field_errors(f[:email], :email)}>
                  <%= "Email" <> " " <> msg %>
                </.error>
              </div>
            </div>

            <div class="sm:col-span-3">
              <label class="block text-sm font-medium leading-6 text-gray-900">
                Password
              </label>

              <div phx-feedback-for={f[:password].name} class="mt-2">
                <%= password_input(f, :password,
                  class:
                    "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                  placeholder: "Password",
                  value: f[:password].value,
                  autocomplete: gettext("new password"),
                  "phx-debounce": "blur"
                ) %>
                <.error :for={msg <- get_field_errors(f[:password], :password)}>
                  <%= "Password" <> " " <> msg %>
                </.error>
              </div>
            </div>

            <div class="sm:col-span-3">
              <label class="block text-sm font-medium leading-6 text-gray-900">
                First Name
              </label>

              <div phx-feedback-for={f[:first_name].name} class="mt-2">
                <%= text_input(f, :first_name,
                  class:
                    "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                  placeholder: "First Name",
                  value: f[:first_name].value,
                  "phx-debounce": "blur"
                ) %>
                <.error :for={msg <- get_field_errors(f[:first_name], :first_name)}>
                  <%= "First Name" <> " " <> msg %>
                </.error>
              </div>
            </div>

            <div class="sm:col-span-3">
              <label class="block text-sm font-medium leading-6 text-gray-900">
                Last Name
              </label>
              <div phx-feedback-for={f[:last_name].name} class="mt-2">
                <%= text_input(f, :last_name,
                  class:
                    "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                  placeholder: "Last Name",
                  value: f[:last_name].value,
                  "phx-debounce": "blur"
                ) %>
                <.error :for={msg <- get_field_errors(f[:last_name], :last_name)}>
                  <%= "Last Name" <> " " <> msg %>
                </.error>
              </div>
            </div>

            <div class="sm:col-span-3">
              <label class="block text-sm font-medium leading-6 text-gray-900">
                Gender
              </label>

              <div phx-feedback-for={f[:gender].name} class="mt-2">
                <%= select(f, :gender, ["Male", "Female"],
                  prompt: "Select Gender",
                  class:
                    "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                  value: f[:gender].value,
                  "phx-debounce": "blur"
                ) %>
                <.error :for={msg <- get_field_errors(f[:gender], :gender)}>
                  <%= "Gender" <> " " <> msg %>
                </.error>
              </div>
            </div>

            <div class="sm:col-span-3">
              <label class="block text-sm font-medium leading-6 text-gray-900">
                Birthdate
              </label>

              <div phx-feedback-for={f[:birthdate].name} class="mt-2">
                <%= date_input(f, :birthdate,
                  class:
                    "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                  placeholder: "birthdate",
                  value: f[:birthdate].value,
                  "phx-debounce": "blur"
                ) %>
                <.error :for={msg <- get_field_errors(f[:birthdate], :birthdate)}>
                  <%= "Birthdate" <> " " <> msg %>
                </.error>
              </div>
            </div>
          </div>

          <div class="w-[100%] flex mt-6 justify-between items-center">
            <.link navigate="/login">
              <p class="block text-sm leading-6 text-blue-600 transition-all duration-500 ease-in-out hover:text-blue-500 dark:hover:text-blue-500 hover:cursor-pointer hover:underline">
                Don't have an account? Sign up
              </p>
            </.link>
          </div>
        </div>

        <div class="mt-6 flex items-center justify-end gap-x-6">
          <%= submit("Sign Up",
            phx_disable_with: "Signing up...",
            class:
              "rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
          ) %>
        </div>
      </div>
    </.form>
    """
  end
end
