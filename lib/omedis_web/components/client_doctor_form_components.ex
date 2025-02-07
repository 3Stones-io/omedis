defmodule OmedisWeb.ClientDoctorFormComponents do
  @moduledoc false

  use OmedisWeb, :html

  alias OmedisWeb.Components.Icons
  alias OmedisWeb.CoreComponents

  attr :breadcrumb_items, :list, default: []
  attr :company_name, :string, default: "Omedis"
  attr :language, :string, default: "en"

  def navbar(assigns) do
    ~H"""
    <nav class="font-openSans relative">
      <div class="nav-primary px-3 py-5 border-y-[1.5px] border-y-section-border bg-bg-secondary">
        <div class="w-full flex justify-between items-center">
          <div class="flex gap-3">
            <button
              class="inline-block border border-btn-border rounded-lg flex items-center justify-center px-2 my-[.15em]"
              phx-click={show_mobile_menu()}
            >
              <.icon name="hero-bars-3" class="w-6 h-6 text-icons-txt-secondary" />
            </button>
            <div>
              <h2 class="font-semibold text-txt-primary">{@company_name}</h2>
              <.client_doctor_breadcrumb items={@breadcrumb_items} />
            </div>
          </div>
          <div class="flex items-center border border-btn-border text-txt-secondary rounded-lg">
            <button class="h-full w-full py-2 px-3 border-r border-btn-border">
              <.icon name="hero-clock" class="w-5 h-5" />
            </button>
            <button class="h-full w-full p-2">
              <.icon name="hero-chevron-down" class="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>

      <.mobile_menu />
    </nav>
    """
  end

  defp mobile_menu(assigns) do
    ~H"""
    <nav
      class="sidebar-nav bg-bg-primary min-h-screen w-[70%] shadow-md rounded-r-lg absolute top-0 left-0 z-[10000] px-4 hidden"
      id="mobile-menu"
      phx-click-away={hide_mobile_menu()}
    >
      <div class="flex justify-between items-center py-6">
        <div class="logo flex items-center gap-2">
          <div class="bg-icons-txt-secondary h-8 w-8 rounded-lg"></div>
          <p class="uppercase font-semibold text-xl text-txt-primary">Company</p>
        </div>
        <button phx-click={hide_mobile_menu()}>
          <.icon name="hero-x-mark" class="w-6 h-6 text-icons-txt-secondary" />
        </button>
      </div>

      <ul class="grid gap-y-4">
        <li :for={{icon, label, path} <- mobile_menu_items()} class="py-4">
          <.link navigate={path} class="flex items-center gap-4">
            <.icon name={icon} class="w-6 h-6 text-icons-txt-secondary" />
            <span class="text-txt-secondary">{label}</span>
          </.link>
        </li>
      </ul>
    </nav>
    """
  end

  defp client_doctor_breadcrumb(assigns) do
    assigns =
      if(length(assigns.items) >= 2,
        do: assign_breadcrumb_items(assigns, Enum.take(assigns.items, -2)),
        else: assign_breadcrumb_items(assigns, assigns.items)
      )

    ~H"""
    <nav
      :if={!Enum.empty?(@breadcrumb_items)}
      class="flex items-center"
      aria-label={dgettext("navigation", "Navigation Breadcrumb")}
    >
      <ul class="flex items-center gap-1">
        <.breadcrumb_item
          :for={{label, path, is_current} <- @breadcrumb_items}
          label={label}
          path={path}
          is_current={is_current}
        />
      </ul>
    </nav>
    """
  end

  defp assign_breadcrumb_items(assigns, items) do
    assign(assigns, :breadcrumb_items, items)
  end

  defp breadcrumb_item(assigns) do
    ~H"""
    <li class="flex items-center">
      <.link navigate={@path} class="flex gap-x-1 text-xs font-medium">
        <span class={[
          @is_current && "text-txt-primary",
          !@is_current && "text-txt-secondary"
        ]}>
          {@label}
        </span>
        <span :if={!@is_current} class="text-txt-secondary"> / </span>
      </.link>
    </li>
    """
  end

  defp mobile_menu_items do
    [
      {"hero-clock", "Time Tracker", ~p"/today"},
      {"hero-user", "Clients", ~p"/"},
      {"hero-user", "Doctors", ~p"/"},
      {"hero-building-office", "Organisations", ~p"/"},
      {"hero-user-group", "Team", ~p"/"},
      {"hero-folder", "Project", ~p"/"},
      {"hero-calendar", "Calendar", ~p"/"},
      {"hero-document", "Documents", ~p"/"},
      {"hero-chart-bar", "Report", ~p"/"}
    ]
  end

  defp show_mobile_menu(js \\ %JS{}) do
    js
    |> JS.show(to: "#mobile-menu")
    |> JS.add_class("blur-[4px]", to: ".nav-primary")
    # TODO: Replace with container for actual elements
    |> JS.add_class("blur-[4px]", to: ".content")
  end

  defp hide_mobile_menu(js \\ %JS{}) do
    js
    |> JS.hide(to: "#mobile-menu")
    |> JS.remove_class("blur-[4px]", to: ".nav-primary")
    # TODO: Replace with container for actual elements
    |> JS.remove_class("blur-[4px]", to: ".content")
  end

  # Form components
  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.custom_input field={@form[:email]} type="email" />
      <.custom_input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values:
      ~w(checkbox color date datetime-local datetime dropdown email file month number password
               range search select tel text textarea time url week radio)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :dropdown_options, :list, doc: "the options for dropdown inputs"
  attr :dropdown_prompt, :string, doc: "the prompt for dropdown inputs"
  attr :dropdown_search_prompt, :string, doc: "the prompt for search inputs", default: "Search"

  attr :has_dropdown_slot, :boolean,
    default: false,
    doc: "the slot for extra content on the dropdown component"

  attr :dropdown_search_options_event, :string,
    doc: "the event for search inputs",
    default: "search_options"

  attr :dropdown_searchable, :boolean,
    default: false,
    doc: "the searchable flag for dropdown inputs"

  attr :radio_checked_color, :string,
    default: "primary",
    doc: "determines the color for radio inputs when checked"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :dropdown_slot, doc: "the slot for extra content on the dropdown component"

  def custom_input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &CoreComponents.translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> custom_input()
  end

  def custom_input(%{type: "dropdown"} = assigns) do
    ~H"""
    <div
      phx-feedback-for={@name}
      class="font-openSans"
      id={"dropdown-#{@id}"}
      data-dropdown-id={@id}
      phx-click-away={hide_dropdown(@id)}
      phx-hook="DropDownInput"
    >
      <input type="hidden" name={@name} id={@id} value={@value} />

      <button
        class="text-form-txt-primary flex items-center justify-between w-full py-2 border-b-[1px] border-form-input-border mb-1"
        type="button"
        id={"dropdown-prompt-#{@id}"}
        phx-update="ignore"
      >
        <span class="prompt-text">{@dropdown_prompt}</span>
        <.icon name="hero-chevron-down" class="w-5 h-5" id={"dropdown-chevron-#{@id}"} />
      </button>

      <div
        class={[
          "bg-form-dropdown-bg text-form-dropdown-txt border border-form-dropdown-border hidden",
          "shadow-lg shadow-form-dropdown-shadow rounded-lg",
          @dropdown_searchable && !@has_dropdown_slot && "py-4",
          @has_dropdown_slot && "pt-4"
        ]}
        id={"dropdown-options-container-#{@id}"}
      >
        <div
          :if={@dropdown_searchable}
          class={[
            "search-input-container px-2 border-[1px] border-form-input-border rounded-lg mx-2 bg-inherit",
            "grid grid-cols-[1em_1fr] items-center"
          ]}
        >
          <.icon
            name="hero-magnifying-glass"
            class="w-5 h-5 inline-block text-form-txt-primary row-span-full col-span-full"
          />
          <input
            type="text"
            placeholder={@dropdown_search_prompt}
            class="border-none focus:ring-0 row-span-full col-span-full mx-4 search-input"
            id={"dropdown-search-#{@id}"}
          />
        </div>

        <ul
          class={[
            "grid gap-y-2 max-h-[20em] overflow-y-scroll dropdown-options-list",
            @dropdown_searchable && "mt-2"
          ]}
          id={"dropdown-options-list-#{@id}"}
          role="listbox"
          phx-update="ignore"
        >
          <li
            :for={option <- @dropdown_options}
            class="py-4 px-2 hover:bg-form-radio-checked-primary/20 focus:bg-form-radio-checked-primary/20 cursor-pointer text-form-dropdown-txt"
            role="option"
            tabindex="0"
          >
            {option}
          </li>
        </ul>

        <div :if={@has_dropdown_slot} class="border-t border-form-input-border">
          {render_slot(@dropdown_slot)}
        </div>
      </div>
    </div>
    """
  end

  def custom_input(%{type: "radio"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="flex items-center gap-2">
      <input
        type={@type}
        name={@name}
        id={@id}
        value={@value}
        class={[
          "border-[2px] border-form-input-border phx-no-feedback:border-form-input-border peer",
          @radio_checked_color == "primary" &&
            "checked:bg-form-radio-checked-primary phx-no-feedback:checked:border-form-radio-checked-primary phx-no-feedback:focus:border-form-radio-checked-primary checked:border-form-radio-checked-primary focus:bg-form-radio-checked-primary focus:ring-form-radio-checked-primary focus:border-form-radio-checked-primary text-form-radio-checked-primary",
          @radio_checked_color == "danger" &&
            "checked:bg-form-radio-checked-secondary phx-no-feedback:checked:border-form-radio-checked-secondary phx-no-feedback:focus:border-form-radio-checked-secondary checked:border-form-radio-checked-secondary focus:bg-form-radio-checked-secondary focus:ring-form-radio-checked-secondary focus:border-form-radio-checked-secondary text-form-radio-checked-secondary"
        ]}
        phx-update="ignore"
        {@rest}
      />
      <.custom_label
        for={@id}
        class={[
          @radio_checked_color == "primary" && "peer-checked:text-form-radio-checked-primary",
          @radio_checked_color == "danger" && "peer-checked:text-form-radio-checked-secondary"
        ]}
      >
        {@label}
      </.custom_label>
    </div>
    """
  end

  # Note: id is required for the date time picker to work
  def custom_input(%{type: "datetime"} = assigns) do
    ~H"""
    <div id={"#{@id}-container"} class="relative" phx-update="ignore">
      <.custom_label
        for={@id}
        class={[
          "text-form-txt-primary flex w-full justify-between items-center",
          "absolute left-0 translate-y-[60%]",
          "has-[+input:focus]:translate-y-[0%] top-0 mb-2"
        ]}
      >
        {@label}
        <.icon name="hero-calendar" class="w-5 h-5 text-form-txt-primary" />
      </.custom_label>

      <input
        type="text"
        name={@name}
        id={@id}
        value={@value}
        class={[
          "mt-2 block w-full text-form-txt-primary focus:ring-0 sm:text-sm sm:leading-6 border-[0] px-0",
          @errors == [] &&
            "border-b-[1px] border-form-input-border phx-no-feedback:border-form-input-border focus:border-b focus:border-form-border-focus phx-no-feedback:focus:border-form-border-focus :placeholdertext-form-txt-primary",
          @errors != [] &&
            "border-b-[1px] border-form-error-msg placeholder:text-form-error-msg focus:border-b focus:border-form-error-msg"
        ]}
        data-input
        phx-hook="DateTimePicker"
        {@rest}
      />
    </div>
    """
  end

  # All other inputs text, url, password, etc. are handled here...
  def custom_input(assigns) do
    ~H"""
    <div
      phx-feedback-for={@name}
      class="font-openSans relative"
      id={"#{@id}-container"}
      phx-hook="InputLabel"
    >
      <.custom_label
        for={@id}
        class={[
          "text-form-txt-primary",
          "absolute left-0 translate-y-[60%]",
          "has-[+input:focus]:translate-y-[0%] top-0 mb-2"
        ]}
      >
        {@label}
      </.custom_label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full text-form-txt-primary focus:ring-0 sm:text-sm sm:leading-6 border-[0] px-0",
          @errors == [] &&
            "border-b-[1px] border-form-input-border phx-no-feedback:border-form-input-border focus:border-b focus:border-form-border-focus phx-no-feedback:focus:border-form-border-focus :placeholdertext-form-txt-primary",
          @errors != [] &&
            "border-b-[1px] border-form-error-msg placeholder:text-form-error-msg focus:border-b focus:border-form-error-msg"
        ]}
        {@rest}
      />
      <.custom_error :for={msg <- @errors}>{msg}</.custom_error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def custom_label(assigns) do
    ~H"""
    <label for={@for} class={["font-openSans text-form-txt-primary", @class]}>
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc """
  Renders a button.
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def custom_button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 hover:opacity-75 focus:opacity-75 bg-client-form-btn-bg py-2 w-[25%] rounded-lg font-openSans",
        "text-base font-semibold leading-6 text-client-form-btn-txt",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def custom_error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-form-error-msg phx-no-feedback:hidden">
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a form subtitle.
  """
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def form_subtitle(assigns) do
    ~H"""
    <h4 class={["font-openSans font-semibold text-form-subtitle-txt text-base mt-2", @class]}>
      {render_slot(@inner_block)}
    </h4>
    """
  end

  @doc """
  Renders a collapsable menu.
  """

  attr :live_action, :atom, required: true
  attr :page_action, :atom, required: true
  attr :label, :string, required: true
  attr :show_divider, :boolean, default: true
  attr :id, :string, required: true
  attr :form_link, :any, required: true

  slot :inner_block, required: true

  def collapsable_menu(assigns) do
    ~H"""
    <div class="wrap-collapsible my-2">
      <div class={[
        "divider bg-form-input-border w-full self-center",
        !@show_divider && "hidden",
        @live_action != @page_action && "h-[6svh]",
        @live_action == @page_action && "h-full"
      ]}>
      </div>
      <label for={@id} class="toggle-label flex items-center gap-2 my-2">
        <input type="checkbox" id={@id} class="toggle hidden" phx-change={JS.navigate(@form_link)} />
        <Icons.circle_with_dot fill={if @live_action == @page_action, do: "#7BC46D", else: "#9d9d9d"} />
        <span class={[
          "toggle-label-text font-semibold",
          @live_action == @page_action && "text-form-sidebar-active-txt",
          @live_action != @page_action && "text-form-txt-primary"
        ]}>
          {@label}
        </span>
      </label>

      <div :if={@live_action == @page_action} class="collapsible-content">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  Renders an error pop up message.
  """
  attr :errors, :list, default: []

  def form_error_message_pop_up(assigns) do
    ~H"""
    <div class="text-form-error-popup-txt bg-form-error-popup-bg rounded-lg py-4 px-6">
      <div class="flex items-center gap-2 font-semibold mb-3">
        <.icon name="hero-exclamation-triangle" class="w-5 h-5 stroke-2" />
        <h4>Submission Error</h4>
      </div>

      <ul class="list-disc list-inside ml-[1.6rem] grid gap-y-1">
        <li :for={error <- @errors}>{error}</li>
      </ul>
    </div>
    """
  end

  defp hide_dropdown(id, js \\ %JS{}) do
    js
    |> JS.add_class("hidden", to: "#dropdown-options-container-#{id}")
    |> JS.remove_class("rotate-180", to: "#dropdown-chevron-#{id}")
    |> JS.remove_class("border-form-border-focus", to: "#dropdown-prompt-#{id}")
    |> JS.add_class("border-form-input-border", to: "#dropdown-prompt-#{id}")
  end
end
