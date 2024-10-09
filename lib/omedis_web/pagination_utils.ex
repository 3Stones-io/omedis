defmodule Omedis.PaginationUtils do
  @moduledoc """
  Utility functions.
  """

  def maybe_parse_value(_key, value) when is_binary(value) do
    case Integer.parse(value) do
      {int_value, ""} -> int_value
      _error -> 1
    end
  end

  def maybe_parse_value(_key, value) when is_integer(value), do: value
  def maybe_parse_value(:page, _value), do: 1
  def maybe_parse_value(:limit, _value), do: 10
end
