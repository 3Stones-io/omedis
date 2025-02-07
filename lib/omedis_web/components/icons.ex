defmodule OmedisWeb.Components.Icons do
  @moduledoc false
  use OmedisWeb, :html

  attr :fill, :string, default: "#9d9d9d"

  def circle_with_dot(assigns) do
    ~H"""
    <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path
        d="M20 10C20 15.5228 15.5228 20 10 20C4.47715 20 0 15.5228 0 10C0 4.47715 4.47715 0 10 0C15.5228 0 20 4.47715 20 10ZM1.9775 10C1.9775 14.4307 5.5693 18.0225 10 18.0225C14.4307 18.0225 18.0225 14.4307 18.0225 10C18.0225 5.5693 14.4307 1.9775 10 1.9775C5.5693 1.9775 1.9775 5.5693 1.9775 10Z"
        fill={@fill}
      />
      <circle cx="10" cy="10" r="3" fill={@fill} />
    </svg>
    """
  end
end

# "#7BC46D"
