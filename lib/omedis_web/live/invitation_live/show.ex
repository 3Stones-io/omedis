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
              <div class="sm:col-span-3">
                <.input
                  type="email"
                  field={f[:email]}
                  placeholder={dgettext("invitation", "Email")}
                  autocomplete="email"
                  required
                  label={dgettext("invitation", "Email")}
                  value={@invitation.email}
                />
              </div>

              <div class="mt-8  sm:col-span-3">
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
    form = Form.validate(socket.assigns.form, user_params)

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:errors, Form.errors(form))
     |> assign(:trigger_action, form.valid?)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    invitation = %Invitation{} = Invitation.by_id!(id)

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
end
