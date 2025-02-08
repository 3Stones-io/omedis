defmodule OmedisWeb.PlaygroundLive.ClientDoctorForms do
  use OmedisWeb, :live_view

  import OmedisWeb.ClientDoctorFormComponents

  alias Omedis.Playground.Client

  @billing_fields %{
    "insurance_provider" => "",
    "insurance_policy_number" => "",
    "klv7_billing_type" => "",
    "veka_number" => "",
    "card_expiry" => "",
    "invoice_type" => ""
  }

  @doctor_fields %{
    "selected_doctor" => "",
    "doctor_client_relationship" => ""
  }

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:form_percentages, %{
       "client_info" => 0,
       "billing" => 0,
       "doctor" => 0
     })
     |> assign(:show_submission_error, false)
     |> assign_cantons()
     |> assign_client_status()
     |> assign_contact_category_types()
     |> assign_file_assignment_options()
     |> assign_relationship_options()
     |> assign_titles()
     |> assign_insurers()
     |> assign_klv7_services_list()
     |> assign_invoice_type()
     |> assign_doctors_and_speciality()
     |> assign_doctor_client_relationship()}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"client_info" => client_params}, socket) do
    changeset = Client.changeset(%Client{}, client_params)
    {:noreply, assign(socket, :form, to_form(changeset, as: :client_info))}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("submit", %{"client_info" => client_params} = params, socket) do
    changeset = Client.changeset(%Client{}, client_params)

    if changeset.valid? do
      {:noreply,
       socket
       |> assign(:show_submission_error, false)
       |> assign_percentage_complete(params)}
    else
      {:noreply,
       socket
       |> assign(:show_submission_error, true)
       |> assign_form(changeset, "client_info")
       |> assign_percentage_complete(params)}
    end
  end

  def handle_event("submit", params, socket) do
    {:noreply, assign_percentage_complete(socket, params)}
  end

  defp apply_action(socket, :client_info, _params) do
    assign_form(socket, Client.changeset(%Client{}), "client_info")
  end

  defp apply_action(socket, :billing, _params) do
    assign_form(socket, @billing_fields, "billing")
  end

  defp apply_action(socket, :doctor, _params) do
    assign_form(socket, @doctor_fields, "doctor")
  end

  defp assign_form(socket, fields, name) do
    assign(socket, :form, to_form(fields, as: name))
  end

  defp assign_percentage_complete(socket, params) do
    form_name = socket.assigns.form.name
    %{^form_name => fields} = params
    total_fields = map_size(fields)

    filled_fields =
      fields
      |> Map.values()
      |> Enum.count(&(not is_nil(&1) and &1 != ""))

    percentage = trunc(ceil(filled_fields / total_fields * 100))

    updated_percentages =
      Map.put(
        socket.assigns.form_percentages,
        form_name,
        percentage
      )

    assign(socket, :form_percentages, updated_percentages)
  end

  defp assign_titles(socket) do
    assign(socket, :titles, ["Mr", "Mrs", "Miss"])
  end

  defp assign_contact_category_types(socket) do
    contact_category_types = [
      "Contact Category type",
      "Contact Category type 2",
      "Contact Category type 3",
      "Contact Category type 4",
      "Contact Category type 5",
      "Contact Category type 6",
      "Contact Category type 7",
      "Contact Category type 8",
      "Contact Category type 9",
      "Contact Category type 10"
    ]

    assign(socket, :contact_category_types, contact_category_types)
  end

  defp assign_client_status(socket) do
    client_statuses = [
      "Inactive",
      "Awaiting List",
      "Active"
    ]

    assign(socket, :client_statuses, client_statuses)
  end

  defp assign_doctors_and_speciality(socket) do
    doctors_and_specialities = [
      %{"name" => "Dr. John Smith", "speciality" => "Dermatology"},
      %{"name" => "Dr. Emily Johnson", "speciality" => "Cardiology"},
      %{"name" => "Dr. Michael Brown", "speciality" => "Neurology"},
      %{"name" => "Dr. Sarah Davis", "speciality" => "Pediatrics"},
      %{"name" => "Dr. David Wilson", "speciality" => "Orthopedics"},
      %{"name" => "Dr. Laura Martinez", "speciality" => "Gastroenterology"},
      %{"name" => "Dr. James Anderson", "speciality" => "Oncology"},
      %{"name" => "Dr. Linda Thomas", "speciality" => "Psychiatry"},
      %{"name" => "Dr. Robert Jackson", "speciality" => "Ophthalmology"},
      %{"name" => "Dr. Patricia White", "speciality" => "Endocrinology"}
    ]

    assign(socket, :doctors_and_specialities, doctors_and_specialities)
  end

  defp assign_doctor_client_relationship(socket) do
    doctor_client_relationship = [
      "Client",
      "Patient"
    ]

    assign(socket, :doctor_client_relationship, doctor_client_relationship)
  end

  defp assign_cantons(socket) do
    cantons = [
      %{"name" => "Zürich", "abbr" => "ZH"},
      %{"name" => "Bern", "abbr" => "BE"},
      %{"name" => "Luzern", "abbr" => "LU"},
      %{"name" => "Uri", "abbr" => "UR"},
      %{"name" => "Schwyz", "abbr" => "SZ"},
      %{"name" => "Obwalden", "abbr" => "OW"},
      %{"name" => "Nidwalden", "abbr" => "NW"},
      %{"name" => "Glarus", "abbr" => "GL"}
    ]

    assign(socket, :cantons, cantons)
  end

  defp assign_file_assignment_options(socket) do
    file_assignment_options = [
      "Only me",
      "All Administrators",
      "All Active Employees"
    ]

    assign(socket, :file_assignment_options, file_assignment_options)
  end

  defp assign_relationship_options(socket) do
    relationship_options = [
      "Type 1",
      "Type 2",
      "Type 3",
      "Type 4",
      "Type 5"
    ]

    assign(socket, :relationship_options, relationship_options)
  end

  defp assign_insurers(socket) do
    insurers = [
      "Insurer 1",
      "Insurer 2",
      "Insurer 3"
    ]

    assign(socket, :insurers, insurers)
  end

  defp assign_klv7_services_list(socket) do
    klv7_services_list = [
      "Billing handled by Client",
      "Direct billing with medical insurance company"
    ]

    assign(socket, :klv7_services_list, klv7_services_list)
  end

  defp assign_invoice_type(socket) do
    invoice_types = [
      "Client pays own share",
      "Client is exempt from own share"
    ]

    assign(socket, :invoice_types, invoice_types)
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <section>
      <.navbar breadcrumb_items={[
        {"Client", ~p"/", false},
        {"Create new client", ~p"/", true}
      ]} />
      <section class="min-h-full content p-4">
        <h1 class="text-xl font-semibold">Create a new client</h1>
        <.collapsable_menu
          form_link={~p"/playground/client-doctor-forms"}
          id="collapsible-client-info"
          label="Client Info"
          live_action={@live_action}
          page_action={:client_info}
          percentage_complete={@form_percentages["client_info"]}
        >
          <.client_info_form
            cantons={@cantons}
            client_statuses={@client_statuses}
            contact_category_types={@contact_category_types}
            file_assignment_options={@file_assignment_options}
            form={@form}
            relationship_options={@relationship_options}
            titles={@titles}
            show_submission_error={@show_submission_error}
          />
        </.collapsable_menu>

        <.collapsable_menu
          form_link={~p"/playground/client-doctor-forms/billing"}
          id="collapsible-billing"
          label="Billing"
          live_action={@live_action}
          page_action={:billing}
          percentage_complete={@form_percentages["billing"]}
        >
          <.billing_form
            form={@form}
            insurers={@insurers}
            klv7_services_list={@klv7_services_list}
            invoice_types={@invoice_types}
          />
        </.collapsable_menu>

        <.collapsable_menu
          form_link={~p"/playground/client-doctor-forms/doctor"}
          id="collapsible-doctor"
          label="Assign a Doctor"
          live_action={@live_action}
          page_action={:doctor}
          show_divider={false}
          percentage_complete={@form_percentages["doctor"]}
        >
          <.doctor_form
            form={@form}
            doctors_and_specialities={@doctors_and_specialities}
            doctor_client_relationship={@doctor_client_relationship}
          />
        </.collapsable_menu>
      </section>
    </section>
    """
  end

  defp doctor_form(assigns) do
    ~H"""
    <.form
      :let={f}
      for={@form}
      phx-change="validate"
      phx-submit="submit"
      class="grid gap-y-4"
      phx-mounted={JS.transition("transition-all transform ease-in duration-100", time: 100)}
      phx-remove={
        JS.hide(
          transition: {"transition-all transform ease-in duration-100", "opacity-100", "opacity-0"}
        )
      }
    >
      <.custom_input
        type="dropdown"
        field={@form[:doctor_speciality]}
        id="doctor-speciality-list"
        dropdown_prompt="Select a doctor"
        dropdown_options={Enum.map(@doctors_and_specialities, &"#{&1["name"]} - #{&1["speciality"]}")}
        dropdown_searchable={true}
        has_dropdown_slot={true}
      >
        <:dropdown_slot>
          <button type="button" class="text-md flex items-center p-4 gap-2 w-full">
            <.icon name="hero-plus-circle" class="w-6 h-6 text-form-radio-checked-primary" />
            <span class="text-form-radio-checked-primary">Add new doctor</span>
          </button>
        </:dropdown_slot>
      </.custom_input>

      <.custom_input
        field={f[:doctor_client_relationship]}
        type="dropdown"
        dropdown_options={@doctor_client_relationship}
        dropdown_prompt="Doctor-Client Relationship"
      />

      <.custom_button type="submit" class="ml-auto my-2">Save</.custom_button>
    </.form>
    """
  end

  defp billing_form(assigns) do
    ~H"""
    <.form
      :let={f}
      for={@form}
      phx-change="validate"
      phx-submit="submit"
      class="grid gap-y-4"
      phx-mounted={JS.transition("transition-all transform ease-in duration-100", time: 100)}
      phx-remove={
        JS.hide(
          transition: {"transition-all transform ease-in duration-100", "opacity-100", "opacity-0"}
        )
      }
    >
      <.form_subtitle>Add Insurer</.form_subtitle>
      <.custom_input
        type="dropdown"
        field={f[:insurance_provider]}
        id="insurance-provider-list"
        dropdown_prompt="Select an insurance provider"
        dropdown_options={@insurers}
      />

      <.custom_input field={f[:insurance_policy_number]} type="text" label="Insurance Policy Number" />

      <.form_subtitle class="mt-4">KLV7 Services</.form_subtitle>
      <%= for option <- @klv7_services_list do %>
        <.custom_input
          type="radio"
          field={f[:klv7_billing_type]}
          id={option}
          value={option}
          checked={input_value(f, :klv7_billing_type) == option}
          label={option}
        />
      <% end %>

      <.form_subtitle class="mt-4">Add Card Details</.form_subtitle>
      <.custom_input field={f[:veka_number]} type="text" label="VEKA Number" />

      <.custom_input
        id="card-expiry"
        field={f[:card_expiry]}
        type="datetime"
        label="Card Expiry(DD/MM/YYYY)"
      />

      <.form_subtitle class="mt-4">Invoice Type</.form_subtitle>
      <%= for invoice_type <- @invoice_types do %>
        <.custom_input
          type="radio"
          field={f[:invoice_type]}
          id={invoice_type}
          value={invoice_type}
          checked={input_value(f, :invoice_type) == invoice_type}
          label={invoice_type}
        />
      <% end %>

      <.custom_button type="submit" class="ml-auto my-2">Save</.custom_button>
    </.form>
    """
  end

  defp client_info_form(assigns) do
    ~H"""
    <.form
      :let={f}
      for={@form}
      phx-change="validate"
      phx-submit="submit"
      class="grid gap-y-4"
      phx-mounted={JS.transition("transition-all transform ease-in duration-100", time: 100)}
      phx-remove={
        JS.hide(
          transition: {"transition-all transform ease-in duration-100", "opacity-100", "opacity-0"}
        )
      }
    >
      <.form_subtitle>Personal information</.form_subtitle>
      <div class="flex gap-x-3 items-center">
        <%= for title <- @titles do %>
          <.custom_input
            type="radio"
            field={f[:title]}
            id={title}
            value={title}
            checked={input_value(f, :title) == title}
            label={title}
          />
        <% end %>
      </div>

      <.custom_input
        field={f[:first_name]}
        type="text"
        label={Phoenix.HTML.raw("First Name" <> "<span class='text-red-600'>*</span>")}
        required={true}
      />

      <.custom_input
        field={f[:last_name]}
        type="text"
        label={Phoenix.HTML.raw("Last Name" <> "<span class='text-red-600'>*</span>")}
        required={true}
      />

      <.custom_input field={f[:email]} type="email" label="Email" />

      <.custom_input
        id="dob"
        field={f[:dob]}
        type="datetime"
        label="Date of Birth(DD/MM/YYYY)"
        value={input_value(f, :dob)}
      />

      <.form_subtitle class="mt-4">Contact Details</.form_subtitle>
      <.custom_input field={f[:street_no]} type="text" label="Street/ No." />

      <.custom_input field={f[:city]} type="text" label="City" />

      <.custom_input field={f[:zip_code]} type="text" label="Zip Code" />

      <.custom_input
        type="dropdown"
        field={f[:canton]}
        id="canton-list"
        dropdown_prompt="Select a canton"
        dropdown_options={
          Enum.map(@cantons, fn canton ->
            Phoenix.HTML.raw(
              "#{canton["name"]}" <> " (<span class='font-bold'>#{canton["abbr"]}</span>)"
            )
          end)
        }
        dropdown_searchable={true}
      />

      <.custom_input field={f[:social_security_number]} type="text" label="Social Security Number" />

      <.custom_input field={f[:telephone_number]} type="tel" label="Telephone Number" />

      <.custom_input
        field={f[:mobile_number]}
        type="tel"
        label={Phoenix.HTML.raw("Mobile Number" <> "<span class='text-red-600'>*</span>")}
        required={true}
      />

      <.form_subtitle class="mt-4">Client Status</.form_subtitle>
      <%= for status <- @client_statuses do %>
        <.custom_input
          type="radio"
          field={f[:client_status]}
          id={status}
          value={status}
          checked={input_value(f, :client_status) == status}
          label={status}
          radio_checked_color={if status == "Inactive", do: "danger", else: "primary"}
        />
      <% end %>

      <.form_subtitle class="mt-4">File Assignment</.form_subtitle>
      <%= for option <- @file_assignment_options do %>
        <.custom_input
          type="radio"
          field={f[:file_assignment]}
          id={option}
          value={option}
          checked={input_value(f, :file_assignment) == option}
          label={option}
        />
      <% end %>

      <.form_subtitle class="mt-4">Add Contact to Client Dossier</.form_subtitle>
      <.custom_input field={f[:contact_mobile_number]} type="tel" label="Mobile Number" />

      <.custom_input
        type="dropdown"
        field={f[:contact_category_type]}
        id="contact-category-type-list"
        dropdown_prompt="Select a contact category type"
        dropdown_options={@contact_category_types}
      />

      <.custom_input
        type="dropdown"
        field={f[:relationship]}
        id="relationship-list"
        dropdown_prompt="Relationship"
        dropdown_options={@relationship_options}
      />

      <.form_error_message_pop_up
        errors={Enum.map(f.errors, fn {_field, {error, _}} -> "#{error}" end)}
        show_submission_error={@show_submission_error}
      />

      <.custom_button type="submit" class="ml-auto my-2">Save</.custom_button>
    </.form>
    """
  end
end
