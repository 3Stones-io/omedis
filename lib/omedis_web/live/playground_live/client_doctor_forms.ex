defmodule OmedisWeb.PlaygroundLive.ClientDoctorForms do
  use OmedisWeb, :live_view

  import OmedisWeb.ClientDoctorFormComponents

  def mount(_params, _session, socket) do
    fields = %{
      "title" => "",
      "first_name" => "",
      "last_name" => "",
      "email" => "",
      "dob" => "",
      "contact_category_type" => "",
      "doctor_speciality" => "",
      "canton" => "",
      "client_status" => ""
    }

    {:ok,
     socket
     |> assign(:form, to_form(fields, as: "user"))
     |> assign(:titles, ["Mr", "Mrs", "Miss"])
     |> assign_doctors_and_speciality()
     |> assign_contact_category_types()
     |> assign_client_status()
     |> assign_cantons()}
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

  defp assign_cantons(socket) do
    cantons = [
      "Zürich",
      "Bern",
      "Luzern",
      "Uri",
      "Schwyz",
      "Obwalden",
      "Nidwalden",
      "Glarus",
      "Zürich",
      "Bern",
      "Luzern",
      "Uri",
      "Schwyz",
      "Obwalden",
      "Nidwalden",
      "Glarus"
    ]

    assign(socket, :cantons, cantons)
  end

  def handle_event("validate", user_params, socket) do
    {:noreply, assign(socket, :form, to_form(user_params))}
  end

  def handle_event("save", user_params, socket) do
    {:noreply, assign(socket, :form, to_form(user_params))}
  end

  def render(assigns) do
    ~H"""
    <section>
      <.navbar breadcrumb_items={[
        {"Client", ~p"/", false},
        {"Create new client", ~p"/", true}
      ]} />
      <section class="min-h-full content px-4 py-2">
        <h1>Create a new client</h1>

        <.form for={@form} phx-submit="save" class="grid gap-y-3" phx-change="validate">
          <.form_subtitle>Personal information</.form_subtitle>

          <div class="flex gap-x-3 items-center">
            <%= for title <- @titles do %>
              <.custom_input
                type="radio"
                field={@form[:title]}
                id={title}
                value={title}
                checked={input_value(@form, :title) == title}
                label={title}
              />
            <% end %>
          </div>

          <.custom_input
            field={@form[:first_name]}
            type="text"
            label={Phoenix.HTML.raw("First Name" <> "<span class='text-red-600'>*</span>")}
            required={true}
          />

          <.custom_input
            field={@form[:last_name]}
            type="text"
            label={Phoenix.HTML.raw("Last Name" <> "<span class='text-red-600'>*</span>")}
            required={true}
          />

          <.custom_input field={@form[:email]} type="email" label="Email" />

          <.custom_input
            id="dob"
            field={@form[:dob]}
            type="datetime"
            label="Date of Birth"
            value={input_value(@form, :dob)}
          />

          <.form_subtitle>Client status</.form_subtitle>
          <%= for status <- @client_statuses do %>
            <.custom_input
              type="radio"
              field={@form[:client_status]}
              id={status}
              value={status}
              checked={input_value(@form, :client_status) == status}
              label={status}
              radio_checked_color={if status == "Inactive", do: "danger", else: "primary"}
            />
          <% end %>

          <.custom_input
            type="dropdown"
            field={@form[:contact_category_type]}
            id="contact-category-type-list"
            dropdown_prompt="Select a contact category type"
            dropdown_options={@contact_category_types}
          />

          <.form_subtitle>Canton</.form_subtitle>
          <.custom_input
            type="dropdown"
            field={@form[:canton]}
            id="canton-list"
            dropdown_prompt="Select a canton"
            dropdown_options={@cantons}
            dropdown_searchable={true}
          />

          <.form_subtitle>Doctor</.form_subtitle>
          <.custom_input
            type="dropdown"
            field={@form[:doctor_speciality]}
            id="doctor-speciality-list"
            dropdown_prompt="Select a doctor"
            dropdown_options={
              Enum.map(@doctors_and_specialities, &"#{&1["name"]} - #{&1["speciality"]}")
            }
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

          <.custom_button type="submit" class="ml-auto my-2">
            Save
          </.custom_button>

          <.form_error_message_pop_up errors={["First Name is required", "Last Name is required"]} />
        </.form>
      </section>
    </section>
    """
  end
end
