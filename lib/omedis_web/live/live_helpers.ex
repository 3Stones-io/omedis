defmodule OmedisWeb.LiveHelpers do
  @moduledoc false

  import Phoenix.Component
  import Phoenix.LiveView

  alias Omedis.Accounts.Organisation
  alias OmedisWeb.Endpoint

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

  def on_mount(:assign_current_organisation, _params, session, socket) do
    pubsub_topics_unique_id = session["pubsub_topics_unique_id"]

    maybe_updated_socket =
      socket
      |> attach_hook(
        :handle_assign_current_organisation,
        :handle_params,
        fn
          %{"slug" => slug} = _params, _uri, socket ->
            organisation =
              Organisation.by_slug!(slug, actor: socket.assigns.current_user)

            :ok = Endpoint.subscribe("time_tracker_live_view_#{pubsub_topics_unique_id}")

            :ok =
              Phoenix.PubSub.broadcast_from(
                Omedis.PubSub,
                self(),
                "current_organisation_#{pubsub_topics_unique_id}",
                {:organisation_selected, organisation}
              )

            {:cont, assign(socket, :organisation, organisation)}

          _, _, socket ->
            {:cont, socket}
        end
      )
      |> attach_hook(:handle_update_current_organisation, :handle_info, fn
        {:time_tracker_live_view, :mounted}, socket ->
          :ok =
            Phoenix.PubSub.broadcast_from(
              Omedis.PubSub,
              self(),
              "current_organisation_#{pubsub_topics_unique_id}",
              {:organisation_selected, socket.assigns[:organisation]}
            )

          {:halt, socket}

        _no_broadcast, socket ->
          {:cont, socket}
      end)

    {:cont, maybe_updated_socket}
  end

  def on_mount(:assign_pubsub_topics_unique_id, _params, session, socket) do
    maybe_updated_socket =
      case session["pubsub_topics_unique_id"] do
        nil ->
          socket

        id ->
          assign(socket, :pubsub_topics_unique_id, id)
      end

    {:cont, maybe_updated_socket}
  end

  def add_pubsub_topics_unique_id_to_session(_conn) do
    %{"pubsub_topics_unique_id" => Ash.UUID.generate()}
  end
end
