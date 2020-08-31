defmodule DarkTesting do
  @moduledoc """
  Documentation for `DarkTesting`.
  """

  def jsonify(params, opts \\ []) do
    module = Application.get_env(:dark_testing, :jsonify_library, DarkTesting.Enums)

    # module = Application.get_env(:dark_testing, :jsonify_library, Iteraptor)
    Kernel.apply(module, :jsonify, [params, opts])
  end

  def stringify(params, opts \\ []) do
    module = Application.get_env(:dark_testing, :jsonify_library, DarkTesting.Enums)

    # module = Application.get_env(:dark_testing, :jsonify_library, Iteraptor)
    Kernel.apply(module, :stringify, [params, opts])
  end

  @doc """
  Maintains keys while merging structs
  """
  @spec struct_merge(struct() | map(), struct() | map()) :: struct() | map()
  def struct_merge(struct, params) do
    Map.merge(struct, Map.take(params, Map.keys(struct)))
  end
end
