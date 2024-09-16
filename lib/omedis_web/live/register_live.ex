defmodule OmedisWeb.RegisterLive do
  use OmedisWeb, :live_view
  alias Omedis.Accounts
  alias Omedis.Accounts.User
  alias AshPhoenix.Form

  @impl true
  def mount(_params, session, socket) do
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
      <p class="text-xl font-medium">
        Create an account
      </p>
      <div class="w-[100%] grid md:grid-cols-2 gap-4">
        <div>
          <label
            for="user_email"
            class="block text-sm font-medium leading-6 text-gray-900 dark:text-white"
          >
            E-mail
          </label>
          <div phx-feedback-for={f[:email].name} class="mt-2">
            <%= text_input(f, :email,
              class: "w-[100%] bg-white rounded-md",
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

        <div>
          <div class="flex items-center justify-between">
            <label
              for="user_password"
              class="block text-sm font-medium leading-6 text-gray-900 dark:text-white"
            >
              Password
            </label>
          </div>
          <div phx-feedback-for={f[:password].name} class="mt-2">
            <%= password_input(f, :password,
              class: "w-[100%] bg-white rounded-md",
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

        <div>
          <div class="flex items-center justify-between">
            <label
              for="user_first_name"
              class="block text-sm font-medium leading-6 text-gray-900 dark:text-white"
            >
              first_name
            </label>
          </div>
          <div phx-feedback-for={f[:first_name].name} class="mt-2">
            <%= text_input(f, :first_name,
              class: "w-[100%] bg-white rounded-md",
              placeholder: "First Name",
              value: f[:first_name].value,
              "phx-debounce": "blur"
            ) %>
            <.error :for={msg <- get_field_errors(f[:first_name], :first_name)}>
              <%= "first_name" <> " " <> msg %>
            </.error>
          </div>
        </div>

        <div>
          <div class="flex items-center justify-between">
            <label
              for="user_last_name"
              class="block text-sm font-medium leading-6 text-gray-900 dark:text-white"
            >
              last_name
            </label>
          </div>
          <div phx-feedback-for={f[:last_name].name} class="mt-2">
            <%= text_input(f, :last_name,
              class: "w-[100%] bg-white rounded-md",
              placeholder: "Last Name",
              value: f[:last_name].value,
              "phx-debounce": "blur"
            ) %>
            <.error :for={msg <- get_field_errors(f[:last_name], :last_name)}>
              <%= "last_name" <> " " <> msg %>
            </.error>
          </div>
        </div>

        <div>
          <div class="flex items-center justify-between">
            <label
              for="user_gender"
              class="block text-sm font-medium leading-6 text-gray-900 dark:text-white"
            >
              gender
            </label>
          </div>
          <div phx-feedback-for={f[:gender].name} class="mt-2">
            <%= select(f, :gender, ["Male", "Female"],
              prompt: "Select Gender",
              class: "w-[100%] bg-white rounded-md",
              value: f[:gender].value,
              "phx-debounce": "blur"
            ) %>
            <.error :for={msg <- get_field_errors(f[:gender], :gender)}>
              <%= "gender" <> " " <> msg %>
            </.error>
          </div>
        </div>

        <div>
          <div class="flex items-center justify-between">
            <label
              for="user_birthdate"
              class="block text-sm font-medium leading-6 text-gray-900 dark:text-white"
            >
              birthdate
            </label>
          </div>
          <div phx-feedback-for={f[:birthdate].name} class="mt-2">
            <%= date_input(f, :birthdate,
              class: "w-[100%] bg-white rounded-md",
              placeholder: "birthdate",
              value: f[:birthdate].value,
              "phx-debounce": "blur"
            ) %>
            <.error :for={msg <- get_field_errors(f[:birthdate], :birthdate)}>
              <%= "birthdate" <> " " <> msg %>
            </.error>
          </div>
        </div>
      </div>

      <div class="w-[100%] flex justify-between items-center">
        <.link navigate="/login">
          <p class="block text-sm leading-6 text-blue-600 transition-all duration-500 ease-in-out hover:text-blue-500 dark:hover:text-blue-500 hover:cursor-pointer hover:underline">
            Don't have an account? Sign up
          </p>
        </.link>
      </div>

      <div>
        <%= submit("Sign Up",
          phx_disable_with: "Signing up...",
          class:
            "flex w-full justify-center rounded-md bg-indigo-600 dark:bg-indigo-500 px-3 py-1.5 text-sm font-semibold leading-6 text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 "
        ) %>
      </div>
    </.form>
    """
  end
end
