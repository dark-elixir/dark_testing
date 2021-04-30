defmodule DarkTesting.FailureFormatter do
  @moduledoc """
  Helpers for nice `ExUnit` assertions
  """

  alias IO.ANSI

  @regex %{
    newline: ~r{(\r\n\|\r|\n|<br>)}
  }

  @doc """
  Returns a nicely formated expect message
  """
  def expected_message(field, expected, actual, options \\ %{}) do
    expected_line = compact_join(["Expected", field, options[:after_expect]])
    expected_result = maybe_inspect(:expect, expected, options)
    actual_line = compact_join(["Actual", field, options[:after_actual]])
    actual_result = maybe_inspect(:actual, actual, options)

    format_failure(expected_line, expected_result, actual_line, actual_result)
  end

  def format_failure(expected_line, expected_result, actual_line, actual_result) do
    """
    #{ANSI.yellow()}#{expected_line}#{ANSI.reset()}

    #{ANSI.red()}#{expected_result}#{ANSI.reset()}

    #{ANSI.yellow()}#{actual_line}#{ANSI.reset()}

    #{ANSI.blue()}#{actual_result}#{ANSI.reset()}
    """
  end

  defp maybe_inspect(:actual, value, %{inspect_actual: false}), do: value
  defp maybe_inspect(:expect, value, %{inspect_expect: false}), do: value
  defp maybe_inspect(_type, value, _opts), do: inspect(value)

  @doc """
  Removes `nil` value from `list` and joins by `delimiter`
  """
  def compact_join(list, delimiter \\ " ")
      when is_list(list) and is_binary(delimiter) do
    list
    |> Enum.reject(&is_nil/1)
    |> Enum.join(delimiter)
  end

  @doc """
  Splits a `text`` by line, using a regex to handle different OS line ending
  """
  def split_lines(text) when is_binary(text) do
    String.split(text, @regex.newline)
  end
end
