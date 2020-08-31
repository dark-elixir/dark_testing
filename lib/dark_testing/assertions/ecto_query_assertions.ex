defmodule DarkTesting.Assertions.EctoQueryAssertions do
  @moduledoc """
  Assertion helpers for working with `Ecto.Query`.
  """

  import ExUnit.Assertions

  alias DarkEcto.Reflections.EctoQueryReflection
  alias DarkEcto.SQLFormatter
  alias DarkTesting.Assertions.EctoQueryAssertions
  alias DarkTesting.FailureFormatter

  defmacro __using__(opts \\ []) do
    repo = Keyword.fetch!(opts, :repo)

    quote do
      def to_sql(query, opts \\ []) do
        EctoQueryAssertions.to_sql(unquote(repo), query, opts)
      end

      def assert_query(query, expected_query_string) do
        EctoQueryAssertions.assert_query(unquote(repo), query, expected_query_string)
      end

      def assert_query(query, expected_query_string, expected_params) do
        EctoQueryAssertions.assert_query(
          unquote(repo),
          query,
          expected_query_string,
          expected_params
        )
      end
    end
  end

  def to_sql(repo, query, opts \\ []) do
    EctoQueryReflection.to_sql(repo, query, opts)
  end

  def assert_query(repo, query, expected_query_string) do
    {query_string, _parsed_params} = to_sql(repo, query)
    formated_query = SQLFormatter.format(query_string)

    assert formated_query == expected_query_string,
      message:
        FailureFormatter.format_failure(
          "Expected",
          formated_query,
          "Received",
          expected_query_string
        )
  end

  def assert_query(repo, query, expected_query_string, expected_params) do
    {query_string, parsed_params} = to_sql(repo, query)
    formated_query = SQLFormatter.format(query_string)

    assert {formated_query, parsed_params} == {expected_query_string, expected_params},
      message:
        FailureFormatter.format_failure(
          "Expected",
          [formated_query, "\n", inspect(parsed_params)],
          "Received",
          [expected_query_string, "\n", inspect(expected_params)]
        )
  end
end
