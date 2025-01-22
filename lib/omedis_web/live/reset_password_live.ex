defmodule OmedisWeb.ResetPasswordLive do
  use OmedisWeb, :live_view

  alias Omedis.Accounts

  @impl Phoenix.LiveView
  def mount(params, %{"language" => language} = _session, socket) do
    Gettext.put_locale(language)

    {
      :ok,
      socket
      |> assign(:language, language)
      |> assign(:token, params["token"])
      |> assign(:trigger_action, false)
      |> assign_form()
    }
  end

  @impl Phoenix.LiveView
  def handle_event("submit", %{"user" => user_params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, user_params)

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:trigger_action, form.source.valid?)}
  end

  defp assign_form(socket) do
    form =
      AshPhoenix.Form.for_action(Accounts.User, :password_reset_with_password,
        domain: Accounts,
        as: "user",
        context: %{
          strategy: AshAuthentication.Strategy.Password,
          private: %{ash_authentication?: true}
        }
      )

    assign(socket, :form, to_form(form))
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.side_and_topbar current_user={@current_user} current_organisation={nil} language={@language}>
      <div class="px-4 lg:pl-80 lg:pr-8 py-10">
        <.header class="text-center">
          {dgettext("auth", "Reset Password")}
        </.header>

        <.form
          for={@form}
          action={~p"/auth/user/password/reset"}
          phx-trigger-action={@trigger_action}
          id="reset-password-form"
          class="max-w-md w-[90%] mx-auto grid gap-4"
          phx-submit="submit"
          method="post"
        >
          <.input
            field={@form[:password]}
            type="password"
            label={dgettext("auth", "New password")}
            required
          />
          <.input field={@form[:reset_token]} type="hidden" value={@token} />

          <.button phx-disable-with={dgettext("auth", "Resetting...")} class="w-full mt-4">
            {dgettext("auth", "Reset Password")}
          </.button>
        </.form>
      </div>
    </.side_and_topbar>
    """
  end
end
