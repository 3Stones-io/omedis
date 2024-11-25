defmodule OmedisWeb.LiveHelpers do
  @moduledoc false

  import Phoenix.Component
  import Phoenix.LiveView

  alias Omedis.Accounts.Organisation

  def on_mount(:assign_default_pagination_assigns, _params, _session, socket) do
    number_of_records_per_page = Application.get_env(:omedis, :pagination_default_limit)

    {:cont,
     socket
     |> assign(:current_page, 1)
     |> assign(:number_of_records_per_page, number_of_records_per_page)
     |> assign(:total_pages, 1)}
  end

  def on_mount(:assign_locale, _params, %{"language" => language}, socket) do
    Gettext.put_locale(OmedisWeb.Gettext, language)

    {:cont, assign(socket, :language, language)}
  end

  def on_mount(:maybe_assign_organisation, _params, _session, socket) do
    maybe_updated_socket =
      attach_hook(
        socket,
        :handle_maybe_assign_organisation,
        :handle_params,
        fn
          %{"slug" => slug} = _params, _uri, socket ->
            organisation =
              Organisation.by_slug!(slug, actor: socket.assigns.current_user)

            {:cont, assign(socket, :organisation, organisation)}

          _, _, socket ->
            {:cont, socket}
        end
      )

    {:cont, maybe_updated_socket}
  end
end
