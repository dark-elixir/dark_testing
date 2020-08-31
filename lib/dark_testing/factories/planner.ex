defmodule DarkTesting.Factories.Planner do
  @moduledoc """
  Struct to represent the construction plan for group of `DarkTesting.FactoryShorthand`.
  """

  alias DarkMatter.Maps
  alias DarkTesting.Factories.FactoryShorthand
  alias DarkTesting.Factories.MutationShorthand
  alias DarkTesting.Factories.Plan

  @type mode() :: :build | :insert | :put | :put_list
  @type factory() :: module()
  @type entry() :: map() | struct()
  @type context() :: %{required(:atom) => entry() | [entry()]}
  @type callback() :: (Plan.t() -> Plan.t())
  @type opts() :: %{
          optional(:mode) => mode()
        }

  @factory_modes [:build, :insert]
  @non_factory_modes [:put, :put_list]
  @modes @factory_modes ++ @non_factory_modes

  @doc """
  All execution modes.
  """
  def modes, do: @modes

  @doc """
  Factory execution modes.
  """
  def factory_modes, do: @factory_modes

  @doc """
  Non-factory execution modes.
  """
  def non_factory_modes, do: @non_factory_modes

  @spec apply_callbacks(factory(), Plan.t(), [callback()]) :: {:ok, Plan.t()}
  def apply_callbacks(factory, %Plan{} = plan, callbacks)
      when is_atom(factory) and is_list(callbacks) do
    for callback <- callbacks, reduce: {:ok, plan} do
      {:ok, acc} -> {:ok, callback.(acc)}
    end
  end

  @spec execute(factory(), Plan.t(), opts()) :: {:ok, map()}
  def execute(
        factory,
        %Plan{
          factory_shorthands: factory_shorthands,
          factory_shorthand_map: factory_shorthand_map
        },
        _opts
      )
      when is_atom(factory) and is_list(factory_shorthands) and is_map(factory_shorthand_map) do
    factories =
      for %FactoryShorthand{key: key} <- factory_shorthands,
          %FactoryShorthand{
            mode: mode,
            name: name,
            assocs: assocs,
            lookup: lookup,
            mutations: mutations,
            params: params
          } = Map.fetch!(factory_shorthand_map, key),
          reduce: %{} do
        acc ->
          assoc_params = Map.take(acc, assocs)
          lookup_params = cast_lookup_params(acc, name, lookup)

          factory_params =
            params
            |> Map.merge(assoc_params)
            |> Map.merge(lookup_params)

          entity = Kernel.apply(factory, :"#{mode}_with", [name, mutations, factory_params])
          Map.put(acc, key, entity)
      end

    {:ok, factories}
  end

  def build_mutations(factory, factories, mutation_shorthands)
      when is_atom(factory) and is_list(mutation_shorthands) do
    mutations =
      for %MutationShorthand{
            key: key,
            assocs: assocs,
            mutations: mutations,
            params: params
          } <- mutation_shorthands,
          reduce: %{} do
        acc ->
          assoc_params = Map.take(factories, assocs)
          mutation_params = Map.merge(assoc_params, params)
          entity = Kernel.apply(factory, :build_mutation, [mutations, mutation_params])
          Map.put(acc, key, entity)
      end

    {:ok, mutations}
  end

  @doc """
  Reject non-exported `keys`.
  """
  @spec factory_exported?(factory(), atom()) :: boolean()
  def factory_exported?(factory, method) when is_atom(factory) and is_atom(method) do
    function_exported?(factory, method, 0)
  end

  defp cast_lookup_params(_acc, _key, []) do
    %{}
  end

  defp cast_lookup_params(_acc, key, fun) when is_function(fun, 0) do
    %{key => fun.()}
  end

  defp cast_lookup_params(acc, key, fun) when is_function(fun, 1) do
    %{key => fun.(acc)}
  end

  defp cast_lookup_params(acc, key, key_or_keys)
       when is_atom(key_or_keys) or is_binary(key_or_keys) or is_list(key_or_keys) do
    %{key => Maps.access_in(acc, key_or_keys)}
  end
end
