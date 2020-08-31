defmodule DarkTesting.MutationTest do
  @moduledoc """
  Test for query `DarkTesting.Mutation`.
  """

  use ExUnit.Case, async: true

  alias DarkTesting.Mutation
  alias DarkTesting.TestFactory

  describe ".build/2" do
    test "given valid :factory and :name" do
      name = :example_test

      assert Mutation.build(TestFactory, name) == %Mutation{
               json: %{no_matcher: []},
               matcher: %{},
               name: :example_test,
               params: %{no_matcher: []},
               atom_params: %{no_matcher: []},
               string_params: %{"no_matcher" => []}
             }
    end
  end

  # describe ".build/3" do
  #   test "given valid :factory and :name" do
  #     name = :example_test
  #     params = %{c: 2}
  #     assert Mutation.build(TestFactory, name, params) == %{}
  #   end
  # end

  describe ".build_mutation/2" do
    test "given valid :factory and :name" do
      name = :example_test
      assert Mutation.build_mutation(TestFactory, name) == %{no_matcher: []}
    end
  end

  describe ".build_mutation/3" do
    test "given valid :factory and :name" do
      name = :example_test
      params = %{c: 2}
      assert Mutation.build_mutation(TestFactory, name, params) == %{c: 2, no_matcher: []}
    end
  end

  describe ".get_matcher/2" do
    test "given an existing :factory and :name" do
      name = :example_test
      assert Mutation.get_matcher(TestFactory, name) == %{}
    end

    test "given a missing :factory and :name" do
      name = :example_test
      assert Mutation.get_matcher(TestFactory, name) == %{}
    end
  end
end
