defmodule DarkTesting.MutationsTest do
  @moduledoc """
  Test for query `DarkTesting.Mutations`.
  """

  use ExUnit.Case, async: true

  alias DarkTesting.Mutation
  alias DarkTesting.Mutations
  alias DarkTesting.TestFactory
  alias DarkTesting.TestFactory.TestStruct

  @example_test_mutation %Mutation{
    json: %{no_matcher: []},
    matcher: %{},
    name: :example_test,
    params: %{no_matcher: []},
    atom_params: %{no_matcher: []},
    string_params: %{"no_matcher" => []}
  }

  @example_test_struct %TestStruct{
    no_matcher: true,
    a: 2,
    c: 4
  }

  @example_test_with_struct_mutation %Mutation{
    json: %{
      a: 2,
      c: 4,
      no_matcher: true,
      b: nil,
      d: nil,
      matcher: nil
    },
    matcher: %{},
    name: :example_test_with_struct,
    params: @example_test_struct,
    atom_params: %{
      matcher: nil,
      no_matcher: true,
      a: 2,
      b: nil,
      c: 4,
      d: nil
    },
    string_params: %{
      "matcher" => nil,
      "no_matcher" => true,
      "a" => 2,
      "b" => nil,
      "c" => 4,
      "d" => nil
    }
  }

  @cases_without_params [
    {:example_test, %{},
     %Mutations{
       json: %{no_matcher: []},
       matcher: %{},
       mutations: [@example_test_mutation],
       override_params: %{},
       params: %{no_matcher: []},
       atom_params: %{no_matcher: []},
       string_params: %{"no_matcher" => []},
       selected: [:example_test]
     }},
    {:example_test_with_struct, %{},
     %Mutations{
       json: @example_test_with_struct_mutation.json,
       matcher: %{},
       mutations: [@example_test_with_struct_mutation],
       override_params: %{},
       params: @example_test_with_struct_mutation.params,
       atom_params: %{
         matcher: nil,
         no_matcher: true,
         a: 2,
         b: nil,
         c: 4,
         d: nil
       },
       string_params: %{
         "matcher" => nil,
         "no_matcher" => true,
         "a" => 2,
         "b" => nil,
         "c" => 4,
         "d" => nil
       },
       selected: [:example_test_with_struct]
     }}
  ]

  @cases_with_params [
    {:example_test, %{c: 2},
     %Mutations{
       json: %{c: 2, no_matcher: []},
       matcher: %{},
       mutations: [@example_test_mutation],
       override_params: %{c: 2},
       params: %{c: 2, no_matcher: []},
       atom_params: %{c: 2, no_matcher: []},
       string_params: %{"c" => 2, "no_matcher" => []},
       selected: [:example_test]
     }},
    {:example_test, %{c: 2, not_present: 3},
     %Mutations{
       json: %{c: 2, no_matcher: [], not_present: 3},
       matcher: %{},
       mutations: [@example_test_mutation],
       override_params: %{c: 2, not_present: 3},
       params: %{c: 2, no_matcher: [], not_present: 3},
       atom_params: %{c: 2, no_matcher: [], not_present: 3},
       string_params: %{"c" => 2, "no_matcher" => [], "not_present" => 3},
       selected: [:example_test]
     }}
  ]

  describe ".build_mutation/2" do
    for {name, _, expected} <- @cases_without_params do
      test "given name #{inspect(name)}" do
        assert Mutations.build_mutation(TestFactory, unquote(name)) ==
                 unquote(Macro.escape(expected))
      end
    end
  end

  describe ".build_mutation/3" do
    for {name, params, expected} <- @cases_without_params ++ @cases_with_params do
      test "given name #{inspect(name)} and #{inspect(params)}" do
        assert Mutations.build_mutation(TestFactory, unquote(name), unquote(Macro.escape(params))) ==
                 unquote(Macro.escape(expected))
      end
    end
  end

  describe ".filter_by_opts/2" do
    @list [:key1, :key2, :key3, :key4]

    @cases [
      # noop
      {@list, nil, @list},
      {@list, [], @list},
      {@list, %{}, @list},
      # :only
      {@list, [only: :key1], [:key1]},
      {@list, [only: [:key2, :key3]], [:key2, :key3]},
      {@list, [only: [:key2, :key3, :missing]], [:key2, :key3]},
      {@list, %{only: :key1}, [:key1]},
      {@list, %{only: [:key1]}, [:key1]},
      {@list, %{only: [:key2, :key3, :missing]}, [:key2, :key3]},
      # :except
      {@list, [except: :key1], [:key2, :key3, :key4]},
      {@list, [except: [:key2, :key3]], [:key1, :key4]},
      {@list, [except: [:key2, :key3, :missing]], [:key1, :key4]},
      {@list, %{except: :key1}, [:key2, :key3, :key4]},
      {@list, %{except: [:key1]}, [:key2, :key3, :key4]},
      {@list, %{except: [:key2, :key3, :missing]}, [:key1, :key4]}
    ]

    for {given, opts, expected} <- @cases do
      test "given #{inspect(given)} and opts #{inspect(opts)} expect #{inspect(expected)}" do
        assert Mutations.filter_by_opts(unquote(Macro.escape(given)), unquote(Macro.escape(opts))) ==
                 unquote(Macro.escape(expected))
      end
    end

    @error_cases [
      # Invalid usecases
      {@list, "key1", []},
      {@list, ["key1"], []},
      # Non-atoms values
      {@list, [only: "key1"], []},
      {@list, %{only: "key1"}, []},
      {@list, [except: "key1"], @list},
      {@list, %{except: "key1"}, @list}
    ]

    for {given, opts, _expected} <- @error_cases do
      test "given #{inspect(given)} and opts #{inspect(opts)} raises" do
        assert_raise FunctionClauseError,
                     "no function clause matching in DarkTesting.Mutations.filter_by_opts/2",
                     fn ->
                       Mutations.filter_by_opts(
                         unquote(Macro.escape(given)),
                         unquote(Macro.escape(opts))
                       )
                     end
      end
    end
  end

  describe ".build_with/3" do
    test "given :example_test_struct and []" do
      name = :example_test_struct
      mutations = []

      assert Mutations.build_with(TestFactory, name, mutations) == %TestStruct{
               a: 100,
               b: 100
             }
    end

    test "given :example_test_struct and [:example_test]" do
      name = :example_test_struct
      mutations = [:example_test]

      assert Mutations.build_with(TestFactory, name, mutations) == %TestStruct{
               a: 100,
               b: 100,
               no_matcher: []
             }
    end
  end

  describe ".build_with/4" do
    test "given :example_test_struct and [] and %{}" do
      name = :example_test_struct
      mutations = []
      params = %{}

      assert Mutations.build_with(TestFactory, name, mutations, params) == %TestStruct{
               a: 100,
               b: 100
             }
    end

    test "given :example_test_struct and [] and %{c: 100}" do
      name = :example_test_struct
      mutations = []
      params = %{c: 100}

      assert Mutations.build_with(TestFactory, name, mutations, params) == %TestStruct{
               a: 100,
               b: 100,
               c: 100
             }
    end

    test "given :example_test_struct and [:example_test] and %{c: 120}" do
      name = :example_test_struct
      mutations = [:example_test]
      params = %{c: 120}

      assert Mutations.build_with(TestFactory, name, mutations, params) == %TestStruct{
               a: 100,
               b: 100,
               c: 120,
               no_matcher: []
             }
    end

    test "given :example_test_struct and [:example_test] and %{c: 120, not_present: 300}" do
      name = :example_test_struct
      mutations = [:example_test]
      params = %{c: 120, not_present: 300}

      assert Mutations.build_with(TestFactory, name, mutations, params) == %TestStruct{
               a: 100,
               b: 100,
               c: 120,
               no_matcher: []
             }
    end
  end

  # select(%__MODULE__{} = struct, opts \\ []) do
  # select_mutations(%__MODULE__{mutations: mutations} = struct, :all) do
  # select_mutations(%__MODULE__{mutations: mutations} = struct, selected)
  # insert_with(factory, factory_name, mutation_or_mutations, params) do
  # with_mutations(factory, struct, mutations, params) do
  # compose_mutations(factory, mutations, opts \\ []) when is_list(mutations) do
end
