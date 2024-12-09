defmodule OmedisWeb.InvitationLive.Show do
  use OmedisWeb, :live_view

  alias AshPhoenix.Form
  alias Omedis.Accounts.Invitation
  alias Omedis.Accounts.Organisation
  alias Omedis.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <.side_and_topbar
      current_user={@current_user}
      current_organisation={@organisation}
      language={@language}
      organisations_count={1}
    >
      <div class="px-4 lg:pl-80 lg:pr-8 py-10">
        <div class="flex justify-stretch w-full">
          <div class="w-full">
            <div class="lg:col-span-3 flex flex-col">
              <h2 class="text-base font-semibold leading-7 text-gray-900">
                <%= dgettext("invitation", "Register") %>
              </h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                <%= dgettext(
                  "invitation",
                  "Use a permanent address where you can receive mail."
                ) %>
              </p>
            </div>
          </div>
        </div>
        <.form
          :let={f}
          id="invitation_user_sign_up_form"
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
                  <.input
                    type="email"
                    field={f[:email]}
                    readonly
                    required
                    label={dgettext("invitation", "Email")}
                    value={@invitation.email}
                  />
                </div>

                <div class="sm:col-span-3">
                  <.input
                    type="text"
                    field={f[:first_name]}
                    placeholder={dgettext("invitation", "First Name")}
                    required
                    label={dgettext("invitation", "First Name")}
                    phx-debounce="blur"
                  />
                </div>

                <div class="sm:col-span-3">
                  <.input
                    type="text"
                    field={f[:last_name]}
                    placeholder={dgettext("invitation", "Last Name")}
                    required
                    label={dgettext("invitation", "Last Name")}
                    phx-debounce="blur"
                  />
                </div>

                <div class="sm:col-span-3">
                  <.input
                    type="password"
                    field={f[:password]}
                    placeholder={dgettext("invitation", "Password")}
                    autocomplete={dgettext("invitation", "new password")}
                    required
                    label={dgettext("invitation", "Password")}
                    phx-debounce="blur"
                  />
                </div>

                <div class="sm:col-span-3">
                  <.input
                    type="select"
                    field={f[:gender]}
                    required
                    label={dgettext("invitation", "Gender")}
                    options={[
                      dgettext("invitation", "Male"),
                      dgettext("invitation", "Female")
                    ]}
                    prompt={dgettext("invitation", "Select Your Gender")}
                  />
                </div>

                <div class="sm:col-span-3">
                  <.input
                    type="date"
                    field={f[:birthdate]}
                    required
                    label={dgettext("invitation", "Birthdate")}
                    phx-debounce="blur"
                  />
                </div>

                <div class="sm:col-span-3">
                  <label class="block text-sm font-medium leading-6 text-gray-900">
                    <%= dgettext("invitation", "Daily Start Time") %>
                  </label>

                  <div phx-feedback-for={f[:daily_start_at].name} class="mt-2">
                    <%= time_input(f, :daily_start_at,
                      class:
                        "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                      value: f[:daily_start_at].value || @organisation.default_daily_start_at,
                      "phx-debounce": "blur"
                    ) %>
                    <.error :for={msg <- get_field_errors(f[:daily_start_at], :daily_start_at)}>
                      <%= dgettext("invitation", "Daily Start Time") <> " " <> msg %>
                    </.error>
                  </div>
                </div>

                <div class="sm:col-span-3">
                  <label class="block text-sm font-medium leading-6 text-gray-900">
                    <%= dgettext("invitation", "Daily End Time") %>
                  </label>

                  <div phx-feedback-for={f[:daily_end_at].name} class="mt-2">
                    <%= time_input(f, :daily_end_at,
                      class:
                        "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
                      value: f[:daily_end_at].value || @organisation.default_daily_end_at,
                      "phx-debounce": "blur"
                    ) %>
                    <.error :for={msg <- get_field_errors(f[:daily_start_at], :daily_end_at)}>
                      <%= dgettext("invitation", "Daily End Time") <> " " <> msg %>
                    </.error>
                  </div>
                </div>
              </div>
            </div>

            <div class="mt-6 flex items-center justify-end gap-x-6">
              <%= submit(
                dgettext("invitation", "Sign up"),
                phx_disable_with: dgettext("invitation", "Signing up..."),
                class:
                  "rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
              ) %>
            </div>
          </div>

          <div class="sm:col-span-3">
            <div>
              <.input
                type="hidden"
                id="select_organisation"
                field={f[:current_organisation_id]}
                value={@organisation.id}
                required
              />
            </div>
          </div>

          <.input type="hidden" field={f[:lang]} value={@invitation.language} />
        </.form>
      </div>
    </.side_and_topbar>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :current_user, nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    form = Form.validate(socket.assigns.form, user_params, errors: true)

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("submit", %{"user" => user_params}, socket) do
    updated_params = Map.replace(user_params, "email", socket.assigns.invitation.email)
    form = Form.validate(socket.assigns.form, updated_params)

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:errors, Form.errors(form))
     |> assign(:trigger_action, form.valid?)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    case get_invitation(id) do
      {:error, %Ash.Error.Query.NotFound{}} ->
        socket
        |> put_flash(:error, dgettext("invitation", "Invitation expired or not found"))
        |> redirect(to: ~p"/login")

      {:error, :user_already_registered} ->
        socket
        |> put_flash(:error, dgettext("invitation", "User already registered"))
        |> redirect(to: ~p"/login")

      %Invitation{} = invitation ->
        organisation = Organisation.by_id!(invitation.organisation_id, authorize?: false)
        Gettext.put_locale(OmedisWeb.Gettext, invitation.language)

        socket
        |> assign(:invitation, invitation)
        |> assign(:language, invitation.language)
        |> assign(:organisation, organisation)
        |> assign(:page_title, dgettext("invitation", "Complete Registration"))
        |> assign(:action, "/auth/user/password/register/")
        |> assign(:trigger_action, false)
        |> assign_form()
    end
  end

  defp get_invitation(id) do
    with {:ok, invitation} <- Invitation.by_id(id),
         :ok <- invited_user_not_registered?(invitation.email) do
      invitation
    end
  end

  defp invited_user_not_registered?(email) do
    case User.by_email(email) do
      {:ok, _} -> {:error, :user_already_registered}
      _ -> :ok
    end
  end

  defp assign_form(socket) do
    form =
      Form.for_create(
        User,
        :register_with_password,
        api: Accounts,
        as: "user"
      )

    assign(socket, :form, form)
  end

  defp get_field_errors(field, _name) do
    Enum.map(field.errors, &translate_error(&1))
  end
end
