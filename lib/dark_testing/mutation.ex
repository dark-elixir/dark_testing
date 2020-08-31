defmodule DarkTesting.Mutation do
  @moduledoc """
  Mutation assertion helpers
  """

  defstruct [
    :name,
    json: %{},
    atom_params: %{},
    string_params: %{},
    params: %{},
    matcher: %{}
  ]

  @typedoc """
  Struct to represent a mutation created with a factory
  """
  @type t() :: %__MODULE__{
          # key: key(),
          name: atom(),
          json: %{required(String.t()) => any()},
          atom_params: %{required(atom()) => any()},
          string_params: %{required(String.t()) => any()},
          params: %{required(atom()) => any()},
          matcher: %{required(atom()) => any()}
        }

  @type name() :: atom()
  @type json :: %{required(String.t()) => any()}
  @type params :: %{required(atom()) => any()}
  @type matcher :: %{required(atom()) => any()}

  @doc """
  Build a mutation struct
  """
  @spec build(module(), name :: atom()) :: t()
  def build(factory, name) when is_atom(name) do
    params = build_mutation(factory, name)

    %__MODULE__{
      name: name,
      json: DarkTesting.jsonify(params),
      atom_params: DarkTesting.jsonify(params, keys: false),
      string_params: DarkTesting.jsonify(params, keys: true),
      params: params,
      matcher: get_matcher(factory, name)
    }
  end

  def build_mutation(factory, name, params \\ %{}, method \\ :build)
      when is_atom(name) and (is_list(params) or is_map(params)) and is_atom(method) do
    Kernel.apply(factory, method, [mutation_key(name), params])
  end

  def get_matcher(factory, name) when is_atom(name) do
    if function_exported?(factory, matcher_key(name), 0) do
      Kernel.apply(factory, matcher_key(name), [])
    else
      %{}
    end
  end

  defp matcher_key(name) when is_atom(name), do: :"#{name}_mutation_matchers"
  defp mutation_key(name) when is_atom(name), do: :"#{name}_mutation"
  # defp mutation_factory_key(name) when is_atom(name), do: :"#{name}_mutation_factory"
end
