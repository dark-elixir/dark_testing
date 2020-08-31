defmodule DarkTesting.SetupTags do
  @moduledoc """
  Setup Tags for `ExUnit`.
  """

  alias DarkTesting.Factories.FactoryShorthand
  alias DarkTesting.Factories.MutationShorthand
  alias DarkTesting.Factories.Plan
  alias DarkTesting.Factories.Planner

  @typedoc """
  Tags provided by `ExUnit` and modified by the registered attributes
  """
  @type ex_unit_tags() :: %{
          optional(:registered) => %{
            optional(:module_factories) => [FactoryShorthand.shorthand()],
            optional(:module_mutations) => [MutationShorthand.shorthand()],
            optional(:describe_factories) => [FactoryShorthand.shorthand()],
            optional(:describe_mutations) => [MutationShorthand.shorthand()],
            optional(:factories) => [FactoryShorthand.shorthand()],
            optional(:mutations) => [MutationShorthand.shorthand()],
            optional(:callbacks) => [Planner.callback()]
          }
        }

  defmacro __using__(opts \\ []) do
    factory = Keyword.fetch!(opts, :factory)

    quote do
      import DarkTesting.Factories.FactoryMacros,
        only: [
          module_factory: 1,
          describe_factory: 1,
          factory: 1,
          module_factory: 2,
          describe_factory: 2,
          factory: 2
        ]

      ExUnit.Case.register_module_attribute(__MODULE__, :module_factories, accumulate: true)
      ExUnit.Case.register_module_attribute(__MODULE__, :module_mutations, accumulate: true)
      ExUnit.Case.register_describe_attribute(__MODULE__, :describe_factories, accumulate: true)
      ExUnit.Case.register_describe_attribute(__MODULE__, :describe_mutations, accumulate: true)
      ExUnit.Case.register_attribute(__MODULE__, :factories, accumulate: false)
      ExUnit.Case.register_attribute(__MODULE__, :mutations, accumulate: false)
      ExUnit.Case.register_attribute(__MODULE__, :callbacks, accumulate: false)

      setup tags do
        DarkTesting.SetupTags.run_setup(unquote(Macro.escape(__CALLER__)), unquote(factory), tags)
      end
    end
  end

  @doc """
  Runner for `ExUnit` `tags`.
  """
  @spec run_setup(any(), Planner.factory(), ex_unit_tags()) :: Planner.context()
  def run_setup(caller, factory, tags) when is_atom(factory) and is_map(tags) do
    [factories, mutations, callbacks, opts] = parse_registered_tags(tags)

    case execute(caller, factory, factories, mutations, callbacks, opts) do
      :ignore -> tags
      {:ok, context} -> warn_on_merge_conflict(tags, context)
      {:error, errors} -> raise_setup_tags_error(errors)
    end
  end

  defp parse_registered_tags(%{registered: registered}) do
    module_factories = Map.get(registered, :module_factories) || []
    module_mutations = Map.get(registered, :module_mutations) || []
    describe_factories = Map.get(registered, :describe_factories) || []
    describe_mutations = Map.get(registered, :describe_mutations) || []
    test_factories = Map.get(registered, :factories) || []
    test_mutations = Map.get(registered, :mutations) || []
    callbacks = Map.get(registered, :callbacks) || []

    factories = List.flatten(module_factories ++ describe_factories ++ test_factories)
    mutations = List.flatten(module_mutations ++ describe_mutations ++ test_mutations)
    opts = %{}
    [factories, mutations, callbacks, opts]
  end

  @doc """
  Executes a `DarkTesting.Factories.Planner` plan.
  """
  @spec execute(
          caller :: any(),
          Planner.factory(),
          [FactoryShorthand.shorthand()],
          [MutationShorthand.shorthand()],
          [Planner.callback()],
          Planner.opts()
        ) ::
          {:ok, map()} | Plan.error_result() | :ignore
  def execute(_caller, _factory, [], [], [], _opts), do: :ignore

  def execute(caller, factory, factories, mutations, callbacks, opts)
      when is_atom(factory) and
             is_list(factories) and
             is_list(mutations) and
             is_list(callbacks) and
             is_map(opts) do
    with {:ok, %Plan{} = plan} <- Plan.build(factory, factories, caller),
         {:ok, %Plan{} = plan} <- Planner.apply_callbacks(factory, plan, callbacks),
         {:ok, factories} <- Planner.execute(factory, plan, opts),
         {:ok, mutations} <- Planner.build_mutations(factory, factories, mutations) do
      context =
        %{factories: factories, mutations: mutations}
        |> warn_on_merge_conflict(factories)
        |> warn_on_merge_conflict(mutations)

      {:ok, context}
    end
  end

  def intersection_list(left, right) do
    left
    |> MapSet.new()
    |> MapSet.intersection(MapSet.new(right))
    |> MapSet.to_list()
  end

  def intersection_list(left, right, fun) when is_function(fun, 1) do
    intersection_list(fun.(left), fun.(right))
  end

  @spec warn_on_merge_conflict(map(), map()) :: map()
  defp warn_on_merge_conflict(left, right) do
    overlapping_keys = intersection_list(left, right, &Map.keys/1)

    unless overlapping_keys == [] do
      raise_setup_tags_error(overlapping_keys)
    end

    Map.merge(left, right)
    # DeepMerge.deep_merge(left, right)
  end

  @spec raise_setup_tags_error([String.t()]) :: no_return()
  defp raise_setup_tags_error(errors) when is_list(errors) do
    raise ArgumentError, """
    [SetupTags]

    #{"\t" <> Enum.join(errors, "\n\t")}
    """
  end
end
