defmodule DarkTesting.TestFactory do
  # credo:disable-for-this-file

  defmodule TestStruct do
    defstruct [:a, :b, :c, :d, :no_matcher, :matcher]
  end

  def example_test_mutation_factory do
    %{no_matcher: []}
  end

  def example_test_with_matcher_mutation_matchers do
    %{matcher: &is_nil/1}
  end

  def example_test_with_matcher_mutation_factory do
    %{matcher: "true"}
  end

  def example_test_with_struct_mutation_factory do
    %TestStruct{no_matcher: true, a: 2, c: 4}
  end

  def example_test_struct_factory do
    %TestStruct{a: 100, b: 100}
  end

  def build(name, params \\ %{}) when is_atom(name) do
    __MODULE__
    |> Kernel.apply(:"#{name}_factory", [])
    |> Map.merge(params)

    # |> DarkTesting.struct_merge(params)
  end

  def insert(name, params \\ %{}) do
    build(name, params)
  end
end
