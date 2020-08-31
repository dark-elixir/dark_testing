defmodule DarkTesting.Factories.Options do
  @moduledoc """
  Parser for list or macro builders
  """

  alias DarkMatter.PrefixLists

  def expand(opts, env \\ __ENV__) when is_list(opts) do
    opts
    |> Enum.flat_map(&do_expand(env, &1))
    |> Enum.into(%{params: %{}, mutations: [], assocs: [], lookup: []})
  end

  defp do_expand(env, params) when is_list(params) do
    Enum.flat_map(params, &do_expand(env, &1))
  end

  defp do_expand(_env, params) when is_map(params) do
    [{:params, params}]
  end

  defp do_expand(env, {:%{}, _, _} = quoted_map) do
    [{:params, expand_params_as_map(env, quoted_map)}]
  end

  defp do_expand(env, {:params, {:%{}, _, _} = quoted_map}) do
    [{:params, expand_params_as_map(env, quoted_map)}]
  end

  defp do_expand(_env, {:params, params}) when is_map(params) do
    [{:params, params}]
  end

  defp do_expand(env, {:with, {:%{}, _, _} = quoted_map}) do
    [{:with, expand_params_as_map(env, quoted_map)}]
  end

  defp do_expand(env, {:as, {:&, _, _} = quoted_fun}) do
    [{:lookup, expand_params_as_fun(env, quoted_fun)}]
  end

  defp do_expand(env, {:as, {:fn, _, _} = quoted_fun}) do
    [{:lookup, expand_params_as_fun(env, quoted_fun)}]
  end

  defp do_expand(env, {:as, list}) do
    [{:lookup, expand_params_as_list(env, list)}]
  end

  defp do_expand(env, {:assocs, list}) do
    [{:assocs, expand_prefix_list(env, list)}]
  end

  defp do_expand(env, {:from, list}) do
    [{:assocs, expand_prefix_list(env, list)}]
  end

  defp do_expand(env, {:with, list}) do
    [{:mutations, expand_prefix_list(env, list)}]
  end

  defp expand_prefix_list(env, quoted) do
    quoted
    |> eval_expand(env)
    # |> Macro.escape()
    |> PrefixLists.expand()
  end

  defp expand_params_as_map(env, quoted) do
    quoted
    |> eval_expand(env)
    # |> Macro.escape()
    |> Enum.into(%{})
  end

  defp expand_params_as_list(env, quoted) do
    quoted
    |> eval_expand(env)
    |> Enum.into([])
  end

  defp expand_params_as_fun(env, quoted) do
    quoted
    |> eval_expand(env)
  end

  defp eval_expand(quoted, env, binding \\ []) do
    {val, _} =
      quoted
      |> Macro.expand(env)
      |> Code.eval_quoted(binding, env)

    val
  end
end
