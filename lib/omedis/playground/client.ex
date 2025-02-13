defmodule Omedis.Playground.Client do
  @moduledoc false
  import Ecto.Changeset

  defstruct [
    :title,
    :first_name,
    :last_name,
    :email,
    :dob,
    :street_no,
    :city,
    :zip_code,
    :canton,
    :social_security_number,
    :telephone_number,
    :mobile_number,
    :date_of_contact,
    :client_status,
    :file_assignment,
    :contact_mobile_number,
    :contact_category,
    :relationship
  ]

  @types %{
    title: :string,
    first_name: :string,
    last_name: :string,
    email: :string,
    dob: :string,
    street_no: :string,
    city: :string,
    zip_code: :string,
    canton: :string,
    social_security_number: :string,
    telephone_number: :string,
    mobile_number: :string,
    date_of_contact: :string,
    client_status: :string,
    file_assignment: :string,
    contact_mobile_number: :string,
    contact_category: :string,
    relationship: :string
  }

  @email_regex ~r/^[^\s]+@[^\s]+$/
  @mobile_number_regex ~r/^(\+\d{1,3}[- ]?)?\d{10}$/

  def changeset(%__MODULE__{} = client, attrs \\ %{}) do
    {client, @types}
    |> cast(attrs, Map.keys(@types))
    |> validate_required([:first_name, :last_name, :mobile_number])
    |> validate_format(:email, @email_regex, message: "Invalid email address")
    |> validate_format(:mobile_number, @mobile_number_regex,
      message: "Invalid mobile number format"
    )
    |> validate_length(:email, max: 160)
    |> Map.put(:action, :validate)
  end
end
