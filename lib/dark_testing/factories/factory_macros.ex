defmodule DarkTesting.Factories.FactoryMacros do
  @moduledoc """
  Macros to expand shorthands.
  """

  alias DarkTesting.Factories.FactoryShorthand
  alias DarkTesting.Factories.MutationShorthand
  alias DarkTesting.Factories.Planner

  alias DarkTesting.Factories.FactoryMacros

  @modes Planner.modes()

  defmacro module_factory(_opts \\ [], do: quoted_block) do
    {factories, mutations} = cast(quoted_block, __CALLER__)
    caller = __CALLER__.module

    quote location: :keep do
      FactoryMacros.put_nonempty_attribute(
        unquote(caller),
        :module_factories,
        unquote(Macro.escape(factories))
      )

      FactoryMacros.put_nonempty_attribute(
        unquote(caller),
        :module_mutations,
        unquote(Macro.escape(mutations))
      )
    end
  end

  defmacro describe_factory(_opts \\ [], do: quoted_block) do
    {factories, mutations} = cast(quoted_block, __CALLER__)
    caller = __CALLER__.module

    quote location: :keep do
      FactoryMacros.put_nonempty_attribute(
        unquote(caller),
        :describe_factories,
        unquote(Macro.escape(factories))
      )

      FactoryMacros.put_nonempty_attribute(
        unquote(caller),
        :describe_mutations,
        unquote(Macro.escape(mutations))
      )
    end
  end

  defmacro factory(_opts \\ [], do: quoted_block) do
    caller = __CALLER__.module
    {factories, mutations} = cast(quoted_block, __CALLER__)

    quote location: :keep do
      FactoryMacros.put_nonempty_attribute(
        unquote(caller),
        :factories,
        unquote(Macro.escape(factories))
      )

      FactoryMacros.put_nonempty_attribute(
        unquote(caller),
        :mutations,
        unquote(Macro.escape(mutations))
      )
    end
  end

  def put_nonempty_attribute(caller, attribute, entries) when is_atom(attribute) do
    unless entries == [] do
      Module.put_attribute(caller, attribute, entries)
    end
  end

  @doc """
  Cast a quoted block into a tuple of lists of:
   {`DarkTesting.Factories.FactoryShorthand`, `DarkTesting.Factories.MutationShorthand`}
  """
  def cast(quoted_block, env \\ __ENV__) do
    shorthands = do_cast(env, quoted_block)
    factories = Enum.filter(shorthands, &match?(%FactoryShorthand{}, &1))
    mutations = Enum.filter(shorthands, &match?(%MutationShorthand{}, &1))
    {factories, mutations}
  end

  defp do_cast(env, {:__block__, _meta, block_params}) when is_list(block_params) do
    Enum.flat_map(block_params, &do_cast(env, &1))
  end

  defp do_cast(env, {mode, _meta, params}) when mode in @modes and is_list(params) do
    [FactoryShorthand.shorthand_mode(params, mode, env)]
  end

  defp do_cast(env, {:mutation, _meta, params}) when is_list(params) do
    [MutationShorthand.shorthand(params, env)]
  end
end
