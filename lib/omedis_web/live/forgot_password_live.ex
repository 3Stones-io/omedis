defmodule OmedisWeb.ForgotPasswordLive do
  use OmedisWeb, :live_view

  alias Omedis.Accounts

  @impl Phoenix.LiveView
  def mount(_params, %{"language" => language} = _session, socket) do
    {:ok,
     socket
     |> assign_form()
     |> assign(:language, language)
     |> assign(:organisations_count, 0)
     |> assign(:page_title, dgettext("auth", "Reset password"))
     |> assign(:trigger_action, false)
     |> assign(current_user: nil)}
  end

  @impl Phoenix.LiveView
  def handle_event("submit", %{"user" => _user}, socket) do
    {:noreply, assign(socket, :trigger_action, true)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.side_and_topbar current_user={@current_user} current_organisation={nil} language={@language}>
      <div class="px-4 lg:pl-80 lg:pr-8 py-10">
        <.header class="text-center">
          {dgettext("auth", "Forgot your password?")}
          <:subtitle>
            {dgettext("auth", "We'll send a password reset link to your inbox")}
          </:subtitle>
        </.header>

        <.form
          :let={f}
          for={@form}
          action={~p"/auth/user/password/reset_request"}
          phx-trigger-action={@trigger_action}
          id="reset-password-form"
          class="max-w-md w-[90%] mx-auto"
          phx-submit="submit"
          method="post"
        >
          <.input field={f[:email]} type="email" label={dgettext("auth", "Email")} />
          <.button phx-disable-with={dgettext("auth", "Sending...")} class="mt-4">
            {dgettext("auth", "Send reset link")}
          </.button>
        </.form>
      </div>
    </.side_and_topbar>
    """
  end

  defp assign_form(socket) do
    form =
      AshPhoenix.Form.for_action(Accounts.User, :request_password_reset_with_password,
        api: Accounts,
        as: "user",
        context: %{private: %{ash_authentication?: true}}
      )

    assign(socket, :form, to_form(form))
  end
end
