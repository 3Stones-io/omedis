defmodule OmedisWeb.LogCategoryLive.Show do
  use OmedisWeb, :live_view
  alias Omedis.Accounts.Group
  alias Omedis.Accounts.LogCategory
  alias Omedis.Accounts.Organisation
  alias Omedis.Accounts.Project

  @impl true
  def render(assigns) do
    ~H"""
    <.side_and_topbar
      current_user={@current_user}
      current_organisation={@current_organisation}
      language={@language}
      organisations_count={@organisations_count}
    >
      <div class="px-4 lg:pl-80 lg:pr-8 py-10">
        <.breadcrumb
          items={[
            {gettext("Home"), ~p"/", false},
            {gettext("Organisations"), ~p"/organisations", false},
            {@organisation.name, ~p"/organisations/#{@organisation.slug}", false},
            {gettext("Groups"), ~p"/organisations/#{@organisation.slug}/groups", false},
            {@group.name, ~p"/organisations/#{@organisation.slug}/groups/#{@group.slug}", false},
            {gettext("Log Categories"),
             ~p"/organisations/#{@organisation.slug}/groups/#{@group.slug}/log_categories", false},
            {@log_category.name, "", true}
          ]}
          language={@language}
        />

        <.header>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Log category") %>
          <% end) %>

          <:subtitle>
            <%= with_locale(@language, fn -> %>
              <%= gettext("This is a log_category record from your database.") %>
            <% end) %>
          </:subtitle>

          <:actions>
            <.link
              patch={
                ~p"/organisations/#{@organisation.slug}/groups/#{@group.slug}/log_categories/#{@log_category}/show/edit"
              }
              phx-click={JS.push_focus()}
            >
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= gettext("Edit log_category") %>
                <% end) %>
              </.button>
            </.link>

            <.link
              navigate={
                ~p"/organisations/#{@organisation.slug}/log_categories/#{@log_category}/log_entries"
              }
              phx-click={JS.push_focus()}
            >
              <.button>
                <%= with_locale(@language, fn -> %>
                  <%= gettext("View Log entries") %>
                <% end) %>
              </.button>
            </.link>
          </:actions>
        </.header>

        <.list>
          <:item title={with_locale(@language, fn -> gettext("Name") end)}>
            <%= @log_category.name %>
          </:item>

          <:item title={with_locale(@language, fn -> gettext("Color code") end)}>
            <%= @log_category.color_code %>
          </:item>
          <:item title={with_locale(@language, fn -> gettext("Position") end)}>
            <%= @log_category.position %>
          </:item>
        </.list>

        <.back navigate={
          ~p"/organisations/#{@organisation.slug}/groups/#{@group.slug}/log_categories"
        }>
          <%= with_locale(@language, fn -> %>
            <%= gettext("Back to log categories") %>
          <% end) %>
        </.back>

        <.modal
          :if={@live_action == :edit}
          id="log_category-modal"
          show
          on_cancel={
            JS.patch(
              ~p"/organisations/#{@organisation.slug}/groups/#{@group.slug}/log_categories/#{@log_category}"
            )
          }
        >
          <.live_component
            module={OmedisWeb.LogCategoryLive.FormComponent}
            id={@log_category.id}
            current_user={@current_user}
            projects={@projects}
            title={@page_title}
            action={@live_action}
            organisation={@organisation}
            groups={@groups}
            color_code={@color_code}
            is_custom_color={@is_custom_color}
            organisations={@organisations}
            group={@group}
            next_position={@next_position}
            language={@language}
            log_category={@log_category}
            patch={
              ~p"/organisations/#{@organisation.slug}/groups/#{@group.slug}/log_categories/#{@log_category}"
            }
          />
        </.modal>
      </div>
    </.side_and_topbar>
    """
  end

  @impl true
  def mount(_params, %{"language" => language} = _session, socket) do
    {:ok,
     socket
     |> assign(:language, language)}
  end

  @impl true
  def handle_params(%{"slug" => slug, "id" => id, "group_slug" => group_slug}, _, socket) do
    organisation = Organisation.by_slug!(slug, actor: socket.assigns.current_user)
    group = Group.by_slug!(group_slug, actor: socket.assigns.current_user, tenant: organisation)
    groups = Ash.read!(Group, actor: socket.assigns.current_user, tenant: organisation)

    log_category =
      LogCategory.by_id!(id, actor: socket.assigns.current_user, tenant: organisation)

    next_position = log_category.position

    projects =
      Project.by_organisation_id!(%{organisation_id: organisation.id},
        actor: socket.assigns.current_user,
        tenant: organisation
      )

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action, socket.assigns.language))
     |> assign(:log_category, log_category)
     |> assign(:organisations, Ash.read!(Organisation, actor: socket.assigns.current_user))
     |> assign(:projects, projects)
     |> assign(:group, group)
     |> assign(:groups, groups)
     |> assign(:organisation, organisation)
     |> assign(:is_custom_color, true)
     |> assign(:color_code, log_category.color_code)
     |> assign(:next_position, next_position)
     |> apply_action(socket.assigns.live_action)}
  end

  defp page_title(:show, language),
    do: with_locale(language, fn -> gettext("Show Log category") end)

  defp page_title(:edit, language),
    do: with_locale(language, fn -> gettext("Edit Log category") end)

  defp apply_action(socket, :edit) do
    actor = socket.assigns.current_user
    organisation = socket.assigns.organisation
    log_category = socket.assigns.log_category

    if Ash.can?({log_category, :update}, actor, tenant: organisation) do
      assign(socket, :page_title, page_title(:edit, socket.assigns.language))
    else
      socket
      |> put_flash(:error, gettext("You are not authorized to access this page"))
      |> push_navigate(
        to:
          ~p"/organisations/#{organisation.slug}/groups/#{socket.assigns.group.slug}/log_categories/#{log_category.id}"
      )
    end
  end

  defp apply_action(socket, _), do: socket
end
