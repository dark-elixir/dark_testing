defmodule DarkTesting.Factories.Plan do
  @moduledoc """
  Struct to represent the construction plan for group of `DarkTesting.FactoryShorthand`.
  """

  alias DarkTesting.Factories.FactoryShorthand
  alias DarkTesting.Factories.Planner

  defstruct mode: :build,
            factory_shorthands: [],
            factory_shorthand_map: %{}

  @typedoc """
  Struct to represent factory setup tags.
  """
  @type t() :: %__MODULE__{
          mode: FactoryShorthand.mode(),
          factory_shorthands: [FactoryShorthand.t()],
          factory_shorthand_map: factory_shorthand_map()
        }

  @type factory_shorthand_map() :: %{required(:atom) => FactoryShorthand.t()}

  @type error() :: String.t()
  @type error_result() :: {:error, nonempty_list(error())}

  @doc """
  Build
  """
  @spec build(Planner.factory(), [FactoryShorthand.shorthand()], Macro.Env.t()) ::
          {:ok, t()} | error_result()
  def build(factory, shorthands, env \\ __ENV__) when is_atom(factory) and is_list(shorthands) do
    factory_shorthands = cast_factory_shorthands(shorthands, env)

    case factory_shorthand_map(factory, factory_shorthands) do
      {:ok, factory_shorthand_map} ->
        struct = %__MODULE__{
          factory_shorthands: factory_shorthands,
          factory_shorthand_map: factory_shorthand_map
        }

        {:ok, struct}

      {:error, errors} ->
        {:error, errors}
    end
  end

  @doc """
  Casts a lists of `t:DarkTesting.shorthands()` into a list of `DarkTesting.FactoryShorthand`.
  """
  @spec cast_factory_shorthands([FactoryShorthand.shorthand()], Macro.Env.t()) :: [
          FactoryShorthand.t()
        ]
  def cast_factory_shorthands(shorthands, env \\ __ENV__) when is_list(shorthands) do
    for shorthand <- shorthands, factory_shorthand = FactoryShorthand.shorthand(shorthand, env) do
      factory_shorthand
    end
  end

  @doc """
  Builds a `factory_shorthand_map` of `t:DarkTesting.FactoryShorthand.t()` keyed by the tag `key`.
  """
  @spec factory_shorthand_map(Planner.factory(), [FactoryShorthand.t()]) ::
          {:ok, factory_shorthand_map()} | error_result()
  def factory_shorthand_map(factory, factory_shorthands)
      when is_atom(factory) and is_list(factory_shorthands) do
    Enum.reduce_while(factory_shorthands, {:ok, %{}}, fn
      %FactoryShorthand{key: key} = tag, {:ok, factory_shorthand_map} ->
        case validate_factory_shorthand(factory, factory_shorthand_map, tag) do
          :ok ->
            {:cont, {:ok, Map.put(factory_shorthand_map, key, tag)}}

          {:error, errors} ->
            {:halt, {:error, errors}}
        end
    end)
  end

  @doc """
  Validate if a tag is valid given the `factory` and `factory_shorthand_map`.
  """
  @spec validate_factory_shorthand(
          Planner.factory(),
          factory_shorthand_map(),
          FactoryShorthand.t()
        ) ::
          :ok | error_result()
  def validate_factory_shorthand(
        factory,
        factory_shorthand_map,
        %FactoryShorthand{
          mode: mode,
          key: key,
          name: name,
          assocs: assocs,
          mutations: mutations,
          params: _params
        }
      )
      when is_atom(factory) and is_map(factory_shorthand_map) do
    existing_keys =
      [key]
      |> Enum.filter(&Map.has_key?(factory_shorthand_map, &1))
      |> Enum.map(&"#{key}: key already present in context for #{&1}")

    missing_assocs =
      assocs
      |> Enum.reject(&Map.has_key?(factory_shorthand_map, &1))
      |> Enum.map(&"#{key}: assoc not present in context for #{&1}")

    missing_factories =
      [name]
      |> Enum.map(&:"#{&1}_factory")
      |> Enum.reject(&(factory_exported?(factory, &1) or mode in Planner.non_factory_modes()))
      |> Enum.map(&"#{key}: factory not defined for #{&1}")

    missing_mutations =
      mutations
      |> Enum.map(&:"#{&1}_mutation_factory")
      |> Enum.reject(&factory_exported?(factory, &1))
      |> Enum.map(&"#{key}: mutation not defined for #{&1}")

    case existing_keys ++ missing_assocs ++ missing_factories ++ missing_mutations do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  @doc """
  Reject non-exported `keys`.
  """
  @spec factory_exported?(Planner.factory(), atom()) :: boolean()
  def factory_exported?(factory, method) when is_atom(factory) and is_atom(method) do
    function_exported?(factory, method, 0)
  end
end
