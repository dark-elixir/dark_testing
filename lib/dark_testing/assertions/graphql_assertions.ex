with {:module, _module} <- Code.ensure_compiled(Absinthe) do
  defmodule DarkTesting.Assertions.GraphqlAssertions do
    @moduledoc """
    Graphql assertion helpers
    """

    import ExUnit.Assertions

    @type graphql_result() :: {:ok, Absinthe.result_t()}

    @type assert_errors_opts() :: %{
            optional(:omit) => [error_field :: String.t()],
            optional(:wrap_list?) => boolean()
          }

    @spec assert_errors(graphql_result(), assert_errors_opts()) :: nil | [map()]
    def assert_errors(resp, opts \\ %{}) when is_tuple(resp) and is_map(opts) do
      wrap_list? = Map.get(opts, :wrap_list?, true)

      assert match?({:ok, result} when is_map(result), resp)
      {:ok, result} = resp

      errors =
        if wrap_list? do
          List.wrap(result[:errors])
        else
          result[:errors]
        end

      normalize_errors(errors, opts)
    end

    @spec normalize_errors(any(), assert_errors_opts()) :: any()
    defp normalize_errors(errors, opts) when is_list(errors) and is_map(opts) do
      Enum.map(errors, &normalize_errors(&1, opts))
    end

    defp normalize_errors(error, opts) when is_map(error) and is_map(opts) do
      omit = Map.get(opts, :omit, ["location"])
      Map.drop(error, omit)
    end

    defp normalize_errors(any, opts) when is_map(opts) do
      any
    end
  end
end
