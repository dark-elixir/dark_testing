defmodule DarkTesting.Mutations do
  @moduledoc """
  Mutation assertion helpers
  """

  alias DarkMatter.PrefixLists
  alias DarkTesting.Mutation
  alias DarkTesting.Mutations

  defstruct mutations: [],
            selected: [],
            override_params: %{},
            params: %{},
            atom_params: %{},
            string_params: %{},
            json: %{},
            matcher: %{}

  defmacro __using__(opts \\ []) do
    factory = Keyword.get(opts, :factory, __CALLER__.module)

    quote do
      def put_with(factory_name, mutation_or_mutations, params \\ %{}) do
        Mutations.put_with(unquote(factory), factory_name, mutation_or_mutations, params)
      end

      def put_list_with(factory_name, mutation_or_mutations, params \\ %{}) do
        Mutations.put_list_with(unquote(factory), factory_name, mutation_or_mutations, params)
      end

      def build_mutation(name_or_names, override_params \\ %{}) do
        Mutations.build_mutation(unquote(factory), name_or_names, override_params)
      end

      def build_with(factory_name, mutation_or_mutations, params \\ %{}) do
        Mutations.build_with(unquote(factory), factory_name, mutation_or_mutations, params)
      end

      def insert_with(factory_name, mutation_or_mutations, params \\ %{}) do
        Mutations.insert_with(unquote(factory), factory_name, mutation_or_mutations, params)
      end

      def with_mutations(struct, mutations, params \\ %{}) do
        Mutations.with_mutations(unquote(factory), struct, mutations, params)
      end

      def mutation_params_for(factory_name, mutation_or_mutations, params \\ %{}) do
        Mutations.mutation_params_for(
          unquote(factory),
          factory_name,
          mutation_or_mutations,
          params
        )
      end

      def mutation_string_params_for(factory_name, mutation_or_mutations, params \\ %{}) do
        Mutations.mutation_string_params_for(
          unquote(factory),
          factory_name,
          mutation_or_mutations,
          params
        )
      end
    end
  end

  def build_mutation(factory, names, override_params \\ %{}) do
    %__MODULE__{
      mutations: Enum.map(List.wrap(names), &Mutation.build(factory, &1)),
      override_params: Enum.into(override_params, %{})
    }
    |> select_mutations(:all)
  end

  def filter_by_opts(keys, unspecified) when is_list(keys) and unspecified in [nil, [], %{}] do
    keys
  end

  def filter_by_opts(keys, key) when is_list(keys) and is_atom(key) do
    filter_by_opts(keys, only: [key])
  end

  def filter_by_opts(keys, [key | _] = opts) when is_list(keys) and is_atom(key) do
    filter_by_opts(keys, only: opts)
  end

  def filter_by_opts(keys, [{key, _} | _] = opts) when is_atom(key) do
    filter_by_opts(keys, Enum.into(opts, %{}))
  end

  def filter_by_opts(keys, %{only: only}) when is_list(keys) and is_atom(only) do
    for key <- keys, key in [only], do: key
  end

  def filter_by_opts(keys, %{only: [key | _] = only})
      when is_list(keys) and is_atom(key) do
    for key <- keys, key in only, do: key
  end

  def filter_by_opts(keys, %{except: except}) when is_list(keys) and is_atom(except) do
    for key <- keys, key not in [except], do: key
  end

  def filter_by_opts(keys, %{except: [key | _] = except})
      when is_list(keys) and is_atom(key) do
    for key <- keys, key not in except, do: key
  end

  def select(%__MODULE__{mutations: mutations} = struct, opts \\ []) when is_list(mutations) do
    keys = Enum.map(mutations, & &1.name)
    select_mutations(struct, filter_by_opts(keys, opts))
  end

  def select_mutations(%__MODULE__{mutations: mutations} = struct, selected)
      when selected in [:all, nil, []] do
    select_mutations(struct, Enum.map(mutations, & &1.name))
  end

  def select_mutations(%__MODULE__{mutations: mutations} = struct, selected)
      when is_list(selected) do
    struct =
      for %{name: name, params: params, matcher: matcher} <- mutations,
          name in selected,
          reduce: %{struct | selected: [], matcher: %{}} do
        acc ->
          %{
            acc
            | selected: acc.selected ++ [name],
              params: Map.merge(acc.params, params),
              matcher: Map.merge(acc.matcher, matcher)
          }
      end

    params = Map.merge(struct.params, struct.override_params)

    json = DarkTesting.jsonify(params)
    atom_params = json
    string_params = DarkTesting.stringify(params)

    %{
      struct
      | params: params,
        json: json,
        atom_params: atom_params,
        string_params: string_params
    }
  end

  def put_with(_factory, _factory_name, _mutation_or_mutations, params \\ %{}) do
    case Map.values(params) do
      [val] -> val
    end
  end

  def put_list_with(_factory, _factory_name, _mutation_or_mutations, params \\ %{}) do
    # result =
    #   case mutation_or_mutations do
    #     mutations when is_list(mutations) ->
    #       for mutation <- mutations, do: compose_mutations(factory, mutation)

    #     _ ->
    #       struct = %{}

    #       factory
    #       |> with_mutations(struct, List.wrap(mutation_or_mutations), params)
    #   end

    # IO.inspect(
    #   factory: factory,
    #   factory_name: factory_name,
    #   mutation_or_mutations: mutation_or_mutations,
    #   params: params,
    #   result: result
    # )

    # result
    # [params]
    Map.values(params)
  end

  def mutation_params_for(factory, factory_name, prefix_mutations, params \\ %{}) do
    factory
    |> compose_mutations(PrefixLists.expand([{factory_name, prefix_mutations}]))
    |> Map.merge(params)
    |> DarkTesting.jsonify()
  end

  def mutation_atom_params_for(factory, factory_name, prefix_mutations, params \\ %{}) do
    mutation_params_for(factory, factory_name, prefix_mutations, params)
  end

  def mutation_string_params_for(factory, factory_name, prefix_mutations, params \\ %{}) do
    factory
    |> compose_mutations(PrefixLists.expand([{factory_name, prefix_mutations}]))
    |> Map.merge(params)
    |> DarkTesting.stringify()
  end

  def build_with(factory, factory_name, mutation_or_mutations, params \\ %{}) do
    struct =
      if is_atom(factory_name) do
        factory.build(factory_name)
      else
        factory_name
      end

    mutations =
      mutation_or_mutations
      |> List.wrap()
      |> PrefixLists.expand()

    factory
    |> with_mutations(struct, mutations, params)
  end

  def insert_with(factory, factory_name, mutation_or_mutations, params \\ %{}) do
    mutations =
      mutation_or_mutations
      |> List.wrap()
      |> PrefixLists.expand()

    factory
    |> build_with(factory_name, mutations, params)
    |> factory.insert()
  end

  def with_mutations(factory, struct, mutations, params \\ %{}) do
    struct
    |> DarkTesting.struct_merge(compose_mutations(factory, mutations))
    |> DarkTesting.struct_merge(params)
  end

  def compose_mutations(factory, mutations, opts \\ []) when is_list(mutations) do
    method = Keyword.get(opts, :method, :build)
    params = Keyword.get(opts, :params, %{})

    for mutation <- mutations, reduce: %{} do
      acc -> Map.merge(acc, Mutation.build_mutation(factory, mutation, params, method))
    end
  end
end
