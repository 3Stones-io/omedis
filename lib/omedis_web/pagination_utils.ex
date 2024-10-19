defmodule Omedis.PaginationUtils do
  @moduledoc """
  Utility functions.
  """
  def maybe_convert_page_to_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int_value, ""} -> int_value
      _ -> 1
    end
  end

  def maybe_convert_page_to_integer(value) when is_integer(value), do: value
  def maybe_convert_page_to_integer(_value), do: 1
end
