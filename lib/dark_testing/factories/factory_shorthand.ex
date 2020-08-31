defmodule DarkTesting.Factories.FactoryShorthand do
  @moduledoc """
  Struct to represent the construction plan for a single factory.
  """

  alias DarkTesting.Factories.Options
  alias DarkTesting.Factories.Planner

  defstruct [
    :key,
    :name,
    mode: :build,
    assocs: [],
    lookup: [],
    mutations: [],
    params: %{}
  ]

  @typedoc """
  Struct representing a factory to be constructed
  """
  @type t() :: %__MODULE__{
          mode: mode(),
          key: key(),
          name: name(),
          assocs: assocs(),
          lookup: lookup(),
          mutations: mutations(),
          params: params()
        }

  @type mode() :: Planner.mode()
  @type key() :: atom()
  @type name() :: atom()
  @type assocs() :: [atom()]
  @type lookup() :: [atom()] | (() -> any) | (map() -> any)
  @type mutations() :: [atom()]
  @type params() :: %{required(atom()) => any()}
  @type quoted_params() :: {:%{}, Keyword.t(), Keyword.t()}
  @type quoted_lookup() :: {:&, Keyword.t(), Keyword.t()}

  @type shorthand() :: list_shorthand() | macro_shorthand()

  @type list_shorthand() ::
          t()
          | key()
          | {key(), t()}
          | {key(), name()}
          | {key(), params()}
          | {key(), mutations()}
          | {key(), {name()}}
          | {key(), {name(), params()}}
          | {key(), {name(), mutations()}}
          | {key(), {name(), mutations(), params()}}
          | {key(), {name(), mutations(), assocs()}}
          | {key(), {name(), mutations(), assocs(), params()}}
          | {key(), {mutations()}}
          | {key(), {mutations(), params()}}
          | {key(), {mutations(), assocs()}}
          | {key(), {mutations(), assocs(), params()}}

  @type macro_shorthand() ::
          [key(), ...]
          | [key() | name(), ...]
          | [key() | [macro_opts(), ...]]

  @type macro_opts() ::
          {:from, [key() | prefix_list(), ...]}
          | {:with, mutations()}
          | {:params, params() | quoted_params()}
          | {:lookup, lookup() | quoted_lookup()}

  @type prefix_list() :: [key() | {prefix :: key(), prefix_list()}, ...]

  @modes Planner.modes()

  @doc """
  Creates a struct to represent factory creation.
  """
  @spec new(key(), name(), assocs(), mutations(), params(), lookup(), mode()) :: t()
  def new(key, name, assocs, mutations, params, lookup, mode \\ :build)
      when is_atom(key) and
             is_atom(name) and
             is_list(assocs) and
             (is_function(lookup, 0) or is_function(lookup, 1) or is_list(lookup)) and
             is_list(mutations) and
             is_map(params) and
             mode in @modes do
    validate_assocs!(assocs)
    validate_mutations!(assocs)

    %__MODULE__{
      key: key,
      name: name,
      assocs: assocs,
      lookup: lookup,
      mutations: mutations,
      params: params,
      mode: mode
    }
  end

  defp validate_assocs!(assocs) when is_list(assocs) do
    non_atom_assocs = Enum.reject(assocs, &is_atom/1)

    unless non_atom_assocs == [] do
      raise ArgumentError, "invalid assocs: #{inspect(non_atom_assocs)}"
    end
  end

  defp validate_mutations!(mutations) when is_list(mutations) do
    non_atom_mutations = Enum.reject(mutations, &is_atom/1)

    unless non_atom_mutations == [] do
      raise ArgumentError, "invalid mutations: #{inspect(non_atom_mutations)}"
    end
  end

  def shorthand_mode(shorthand, mode, env \\ __ENV__) when mode in @modes do
    %{shorthand(shorthand, env) | mode: mode}
  end

  @doc """
  Creates shortands for `.new/6`.

  ## Struct Examples

      iex> shorthand(%FactoryShorthand{key: :key, name: :name, mutations: [:mutation], assocs: [:assoc], params: %{params: 1}})
      %FactoryShorthand{key: :key, name: :name, mutations: [:mutation], assocs: [:assoc], params: %{params: 1}}

  ## List Examples

      iex> shorthand(:key)
      %FactoryShorthand{key: :key, name: :key}

      iex> shorthand({:key, %FactoryShorthand{name: :name, mutations: [:mutation], assocs: [:assoc], params: %{params: 1}}})
      %FactoryShorthand{key: :key, name: :name, mutations: [:mutation], assocs: [:assoc], params: %{params: 1}}

      iex> shorthand({:key, %FactoryShorthand{mutations: [:mutation], assocs: [:assoc], params: %{params: 1}}})
      %FactoryShorthand{key: :key, name: :key, mutations: [:mutation], assocs: [:assoc], params: %{params: 1}}

      iex> shorthand({:key, :name})
      %FactoryShorthand{key: :key, name: :name}

      iex> shorthand({:name, %{params: 1}})
      %FactoryShorthand{key: :name, name: :name, params: %{params: 1}}

      iex> shorthand({:name, [:mutation]})
      %FactoryShorthand{key: :name, name: :name, mutations: [:mutation]}

      iex> shorthand({:key, {:name}})
      %FactoryShorthand{key: :key, name: :name}

      iex> shorthand({:key, {:name, %{params: 1}}})
      %FactoryShorthand{key: :key, name: :name, params: %{params: 1}}

      iex> shorthand({:key, {:name, [:mutation]}})
      %FactoryShorthand{key: :key, name: :name, mutations: [:mutation]}

      iex> shorthand({:key, {:name, [:mutation], %{params: 1}}})
      %FactoryShorthand{key: :key, name: :name, mutations: [:mutation], params: %{params: 1}}

      iex> shorthand({:key, {:name, [:mutation], [:assoc]}})
      %FactoryShorthand{key: :key, name: :name, mutations: [:mutation], assocs: [:assoc]}

      iex> shorthand({:key, {:name, [:mutation], [:assoc], %{params: 1}}})
      %FactoryShorthand{key: :key, name: :name, mutations: [:mutation], assocs: [:assoc], params: %{params: 1}}

      iex> shorthand({:key, {[:mutation]}})
      %FactoryShorthand{key: :key, name: :key, mutations: [:mutation]}

      iex> shorthand({:key, {[:mutation], %{params: 1}}})
      %FactoryShorthand{key: :key, name: :key, mutations: [:mutation], params: %{params: 1}}

      iex> shorthand({:key, {[:mutation], [:assoc]}})
      %FactoryShorthand{key: :key, name: :key, mutations: [:mutation], assocs: [:assoc]}

      iex> shorthand({:key, {[:mutation], [:assoc], %{params: 1}}})
      %FactoryShorthand{key: :key, name: :key, mutations: [:mutation], assocs: [:assoc], params: %{params: 1}}

  ## Macro Examples

      iex> shorthand([:key])
      %FactoryShorthand{key: :key, name: :key}

      iex> shorthand([:key, :name])
      %FactoryShorthand{key: :key, name: :name}

      iex> shorthand([:key, :name, %{params: 1}])
      %FactoryShorthand{key: :key, name: :name, params: %{params: 1}}

      iex> shorthand([:key, :name, {:%{}, [], [params: 1]}])
      %FactoryShorthand{key: :key, name: :name, params: %{params: 1}}

      iex> shorthand([:key, with: [:mutation]])
      %FactoryShorthand{key: :key, name: :key, mutations: [:mutation]}

      iex> shorthand([:key, from: [:assoc]])
      %FactoryShorthand{key: :key, name: :key, assocs: [:assoc]}

      iex> shorthand([:key, from: [prefix: :assoc]])
      %FactoryShorthand{key: :key, name: :key, assocs: [:prefix_assoc]}

      iex> shorthand([:key, from: [:assoc, prefix: :assoc]])
      %FactoryShorthand{key: :key, name: :key, assocs: [:assoc, :prefix_assoc]}

      iex> shorthand([:key, with: [:mutation]])
      %FactoryShorthand{key: :key, name: :key, mutations: [:mutation]}

      iex> shorthand([:key, from: [:assoc], with: [:mutation]])
      %FactoryShorthand{key: :key, name: :key, assocs: [:assoc], mutations: [:mutation]}

      iex> shorthand([:key, with: [:mutation], from: [:assoc]])
      %FactoryShorthand{key: :key, name: :key, assocs: [:assoc], mutations: [:mutation]}

      iex> shorthand([:key, :name, with: [:mutation]])
      %FactoryShorthand{key: :key, name: :name, mutations: [:mutation]}

      iex> shorthand([:key, :name, with: [prefix: :mutation]])
      %FactoryShorthand{key: :key, name: :name, mutations: [:prefix_mutation]}

      iex> shorthand([:key, :name, with: [:mutation, prefix: :mutation]])
      %FactoryShorthand{key: :key, name: :name, mutations: [:mutation, :prefix_mutation]}

      # iex> shorthand([:key, :name, with: [:mutation], params: %{params: 1}])
      # %FactoryShorthand{key: :key, name: :name, mutations: [:mutation], params: %{params: 1}}

      # iex> shorthand([:key, :name, with: [:mutation], params: {:%{}, [], [params: 1]}])
      # %FactoryShorthand{key: :key, name: :name, mutations: [:mutation], params: %{params: 1}}
  """
  @spec shorthand(shorthand(), any()) :: t()
  def shorthand(key, env \\ __ENV__)

  def shorthand(
        %__MODULE__{
          key: key,
          name: name,
          assocs: assocs,
          lookup: lookup,
          mutations: mutations,
          params: params,
          mode: mode
        },
        _env
      )
      when is_atom(key) and
             is_atom(name) and
             is_list(assocs) and
             (is_function(lookup, 0) or is_function(lookup, 1) or is_list(lookup)) and
             is_list(mutations) and
             is_map(params) and
             mode in @modes do
    new(key, name, assocs, mutations, params, lookup, mode)
  end

  # List

  def shorthand(key, _env) when is_atom(key) do
    new(key, key, [], [], %{}, [])
  end

  def shorthand(
        {key,
         %__MODULE__{
           name: nil,
           mutations: mutations,
           assocs: assocs,
           lookup: lookup,
           params: params,
           mode: mode
         }},
        _env
      )
      when is_atom(key) and
             is_list(assocs) and
             (is_function(lookup, 0) or is_function(lookup, 1) or is_list(lookup)) and
             is_list(mutations) and
             is_map(params) and
             mode in @modes do
    new(key, key, assocs, mutations, params, lookup, mode)
  end

  def shorthand(
        {key,
         %__MODULE__{
           name: name,
           mutations: mutations,
           assocs: assocs,
           lookup: lookup,
           params: params,
           mode: mode
         }},
        _env
      )
      when is_atom(key) and
             is_atom(name) and
             is_list(assocs) and
             (is_function(lookup, 0) or is_function(lookup, 1) or is_list(lookup)) and
             is_list(mutations) and
             is_map(params) and
             mode in @modes do
    new(key, name, assocs, mutations, params, lookup, mode)
  end

  def shorthand({key, name}, _env) when is_atom(key) and is_atom(name) do
    new(key, name, [], [], %{}, [])
  end

  def shorthand({key, params}, _env) when is_atom(key) and is_map(params) do
    new(key, key, [], [], params, [])
  end

  def shorthand({key, mutations}, _env) when is_atom(key) and is_list(mutations) do
    new(key, key, [], mutations, %{}, [])
  end

  def shorthand({key, {name}}, _env) when is_atom(key) and is_atom(name) do
    new(key, name, [], [], %{}, [])
  end

  def shorthand({key, {name, params}}, _env)
      when is_atom(key) and
             is_atom(name) and
             is_map(params) do
    new(key, name, [], [], params, [])
  end

  def shorthand({key, {name, mutations}}, _env)
      when is_atom(key) and
             is_atom(name) and
             is_list(mutations) do
    new(key, name, [], mutations, %{}, [])
  end

  def shorthand({key, {name, mutations, params}}, _env)
      when is_atom(key) and
             is_atom(name) and
             is_list(mutations) and
             is_map(params) do
    new(key, name, [], mutations, params, [])
  end

  def shorthand({key, {name, mutations, assocs}}, _env)
      when is_atom(key) and
             is_atom(name) and
             is_list(assocs) and
             is_list(mutations) do
    new(key, name, assocs, mutations, %{}, [])
  end

  def shorthand({key, {name, mutations, assocs, params}}, _env)
      when is_atom(key) and
             is_atom(name) and
             is_list(assocs) and
             is_list(mutations) and
             is_map(params) do
    new(key, name, assocs, mutations, params, [])
  end

  def shorthand({key, {mutations}}, _env)
      when is_atom(key) and
             is_list(mutations) do
    new(key, key, [], mutations, %{}, [])
  end

  def shorthand({key, {mutations, params}}, _env)
      when is_atom(key) and
             is_list(mutations) and
             is_map(params) do
    new(key, key, [], mutations, params, [])
  end

  def shorthand({key, {mutations, assocs}}, _env)
      when is_atom(key) and
             is_list(assocs) and
             is_list(mutations) do
    new(key, key, assocs, mutations, %{}, [])
  end

  def shorthand({key, {mutations, assocs, params}}, _env)
      when is_atom(key) and
             is_list(assocs) and
             is_list(mutations) and
             is_map(params) do
    new(key, key, assocs, mutations, params, [])
  end

  def shorthand({key, {mutations, assocs, params, lookup}}, _env)
      when is_atom(key) and
             is_list(assocs) and
             (is_function(lookup, 0) or is_function(lookup, 1) or is_list(lookup)) and
             is_list(mutations) and
             is_map(params) do
    new(key, key, assocs, mutations, params, lookup)
  end

  # Macros

  def shorthand([key | [name | opts]], env) when is_atom(key) and is_atom(name) do
    opts = Options.expand(opts, env)
    new(key, name, opts.assocs, opts.mutations, opts.params, opts.lookup)
  end

  def shorthand([key | opts], env) when is_atom(key) do
    opts = Options.expand(opts, env)
    new(key, key, opts.assocs, opts.mutations, opts.params, opts.lookup)
  end
end
