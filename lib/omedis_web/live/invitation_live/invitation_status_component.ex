defmodule OmedisWeb.InvitationLive.InvitationStatusComponent do
  @moduledoc false
  use OmedisWeb, :html

  def status(%{status: :accepted} = assigns) do
    ~H"""
    <span class="inline-flex items-center rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20">
      <%= dgettext("invitation", "Accepted") %>
    </span>
    """
  end

  def status(%{status: :expired} = assigns) do
    ~H"""
    <span class="inline-flex items-center rounded-md bg-red-50 px-2 py-1 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/20">
      <%= dgettext("invitation", "Expired") %>
    </span>
    """
  end

  def status(%{status: :pending} = assigns) do
    ~H"""
    <span class="inline-flex items-center rounded-md bg-yellow-50 px-2 py-1 text-xs font-medium text-yellow-700 ring-1 ring-inset ring-yellow-600/20">
      <%= dgettext("invitation", "Pending") %>
    </span>
    """
  end
end
