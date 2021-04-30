defmodule DarkTesting.Factories.MutationShorthand do
  @moduledoc """
  MutationShorthand assertion helpers
  """

  alias DarkTesting.Factories.Options

  defstruct [
    :key,
    lookup: [],
    assocs: [],
    mutations: [],
    params: %{}
  ]

  @typedoc """
  Struct representing a factory to be constructed
  """
  @type t() :: %__MODULE__{
          key: key(),
          assocs: assocs(),
          lookup: lookup(),
          mutations: mutations(),
          params: params()
        }

  @type key() :: atom()
  @type assocs() :: [atom()]
  @type lookup() :: [atom(), ...] | (() -> any()) | (map() -> any())
  @type mutations() :: [atom(), ...]
  @type params() :: %{required(atom()) => any()}

  @type shorthand() :: list_shorthand() | macro_shorthand()
  @type list_shorthand() ::
          t()
          | key()
          | {key()}
          | {key(), params()}
          | {key(), mutations()}
          | {key(), {params()}}
          | {key(), {mutations()}}
          | {key(), {mutations, params()}}

  @type macro_shorthand() ::
          [key()]
          | [key() | mutations(), ...]
          | [key() | mutations() | params(), ...]
          | [key() | mutations() | {:params, params()}, ...]
          | [key() | mutations() | {:lookup, lookup()}, ...]
          | [key() | mutations() | {:assocs, assocs()}, ...]

  @doc """
  Build a mutation struct
  """
  @spec new(key(), mutations(), assocs(), params(), lookup()) :: t()
  def new(key, [mutation | _] = mutations, assocs, params, lookup)
      when is_atom(key) and
             is_atom(mutation) and
             is_list(assocs) and
             is_map(params) and
             (is_list(lookup) or is_function(lookup, 0) or is_function(lookup, 1)) do
    %__MODULE__{
      key: key,
      mutations: mutations,
      lookup: lookup,
      assocs: assocs,
      params: params
    }
  end

  @doc """
  Creates shortands for `.new/6`.

  ## List Examples

      iex> shorthand(%MutationShorthand{key: :key, mutations: [:mutation], params: %{params: 1}})
      %MutationShorthand{key: :key, mutations: [:mutation], params: %{params: 1}}

      iex> shorthand(:key)
      %MutationShorthand{key: :key, mutations: [:key]}

  ## Macro Examples

      iex> shorthand([:key])
      %MutationShorthand{key: :key, mutations: [:key]}

      iex> shorthand([:key, [:mutation]])
      %MutationShorthand{key: :key, mutations: [:mutation]}

      iex> shorthand([:key, params: %{params: 1}])
      %MutationShorthand{key: :key, mutations: [:key], params: %{params: 1}}

      iex> shorthand([:key,  {:%{}, [], [params: 1]}])
      %MutationShorthand{key: :key, mutations: [:key], params: %{params: 1}}

      iex> shorthand([:key, [:mutation], params: %{params: 1}])
      %MutationShorthand{key: :key, mutations: [:mutation], params: %{params: 1}}
  """
  @spec shorthand(shorthand(), Macro.Env.t()) :: t()
  def shorthand(shorthand, env \\ __ENV__)

  def shorthand(
        %__MODULE__{
          key: key,
          mutations: [mutation | _] = mutations,
          assocs: assocs,
          params: params,
          lookup: lookup
        },
        _env
      )
      when is_atom(key) and
             is_atom(mutation) and
             is_list(assocs) and
             (is_list(lookup) or is_function(lookup, 0) or is_function(lookup, 1)) and
             is_map(params) do
    new(key, mutations, assocs, params, lookup)
  end

  # List

  def shorthand(key, _env) when is_atom(key) do
    new(key, [key], [], %{}, [])
  end

  def shorthand({key}, _env) when is_atom(key) do
    new(key, [key], [], %{}, [])
  end

  def shorthand({key, params}, _env) when is_atom(key) and is_map(params) do
    new(key, [key], [], params, [])
  end

  def shorthand({key, {params}}, _env) when is_atom(key) and is_map(params) do
    new(key, [key], [], params, [])
  end

  def shorthand({key, [mutation | _] = mutations}, _env)
      when is_atom(key) and is_atom(mutation) do
    new(key, mutations, [], %{}, [])
  end

  def shorthand({key, {[mutation | _] = mutations}}, _env)
      when is_atom(key) and is_atom(mutation) do
    new(key, mutations, [], %{}, [])
  end

  def shorthand({key, {[mutation | _] = mutations, params}}, _env)
      when is_atom(key) and is_atom(mutation) and is_map(params) do
    new(key, mutations, [], params, [])
  end

  # Macros

  def shorthand([key | [mutations | opts]], _env)
      when (is_atom(key) and is_atom(mutations)) or is_list(mutations) do
    opts = Options.expand(List.wrap(opts))
    new(key, List.wrap(mutations), opts.assocs, opts.params, opts.lookup)
  end

  def shorthand([key | opts], env) when is_atom(key) do
    opts = Options.expand(opts, env)
    new(key, [key], opts.assocs, opts.params, opts.lookup)
  end
end
