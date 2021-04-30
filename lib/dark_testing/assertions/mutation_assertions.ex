defmodule DarkTesting.Assertions.MutationAssertions do
  @moduledoc """
  Mutation assertion helpers
  """

  import ExUnit.Assertions
  # use StructAssert
  import StructAssert, only: [assert_subset: 2]

  alias DarkMatter.Maps

  alias DarkTesting.Mutation
  alias DarkTesting.Mutations

  def assert_mutation(given, %Mutations{} = struct, opts \\ []) when is_map(given) do
    %Mutations{mutations: mutations, selected: selected} = Mutations.select(struct, opts)

    for mutation <- mutations, mutation.name in selected do
      # Check each individual mutation
      assert_mutation_with_matcher(given, mutation)
    end

    # Check each all mutations in aggregate
    assert_mutation_with_matcher(given, struct)
  end

  def assert_mutation_with_matcher(given, %Mutation{params: params, matcher: matcher})
      when is_map(given) do
    given_params = source_params(given)
    expected_params = mutation_params(given, params, matcher)
    assert_subset(given_params, expected_params)
  end

  def assert_mutation_with_matcher(given, %Mutations{params: params, matcher: matcher})
      when is_map(given) do
    given_params = source_params(given)
    expected_params = mutation_params(given, params, matcher)
    assert_subset(given_params, expected_params)
  end

  defp source_params(given) do
    Maps.compact(given, deep: true, allow_nil: true)
  end

  defp mutation_params(given, params, matcher) do
    params
    |> Map.merge(matcher)
    |> Map.take(Map.keys(given))
  end
end
