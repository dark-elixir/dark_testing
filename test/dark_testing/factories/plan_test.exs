defmodule DarkTesting.Factories.PlanTest do
  @moduledoc """
  Test for query `DarkTesting.Factories.Plan`.
  """

  use ExUnit.Case, async: true
  alias DarkTesting.Factories.FactoryShorthand
  alias DarkTesting.Factories.Plan
  doctest DarkTesting.Factories.Plan, import: true

  @cases [
    [],
    [user: [:user_register_by_funding_app, :user_approve]],
    [
      broker_org: [:broker_org_registered, :broker_org_confirmed],
      deal: {[:deal_submitted_by_email, :deal_preprocessed], [:broker_org]}
    ],
    [
      :user,
      broker_org: {[:broker_org_registered, :broker_org_confirmed], [:user], %{name: "Name"}},
      deal: {[:deal_submitted_by_email, :deal_preprocessed], [:broker_org]}
    ],
    [invalid: {[], [:missing]}]
  ]

  describe ".cast_factory_shorthands/1" do
    @expected [
      [],
      [
        %FactoryShorthand{
          key: :user,
          name: :user,
          mutations: [:user_register_by_funding_app, :user_approve]
        }
      ],
      [
        %FactoryShorthand{
          key: :broker_org,
          mutations: [
            :broker_org_registered,
            :broker_org_confirmed
          ],
          name: :broker_org,
          params: %{}
        },
        %FactoryShorthand{
          assocs: [:broker_org],
          key: :deal,
          mutations: [:deal_submitted_by_email, :deal_preprocessed],
          name: :deal
        }
      ],
      [
        %FactoryShorthand{
          assocs: [],
          key: :user,
          mode: :build,
          mutations: [],
          name: :user,
          params: %{}
        },
        %FactoryShorthand{
          assocs: [:user],
          key: :broker_org,
          mode: :build,
          mutations: [:broker_org_registered, :broker_org_confirmed],
          name: :broker_org,
          params: %{name: "Name"}
        },
        %FactoryShorthand{
          assocs: [:broker_org],
          key: :deal,
          mode: :build,
          mutations: [
            :deal_submitted_by_email,
            :deal_preprocessed
          ],
          name: :deal,
          params: %{}
        }
      ],
      [
        %FactoryShorthand{
          assocs: [:missing],
          key: :invalid,
          mode: :build,
          mutations: [],
          name: :invalid,
          params: %{}
        }
      ]
    ]
    for {given, expected} <- Enum.zip(@cases, @expected) do
      test "given #{inspect(given)}" do
        assert Plan.cast_factory_shorthands(unquote(Macro.escape(given))) ==
                 unquote(Macro.escape(expected))
      end
    end
  end

  # describe ".valid?/1" do
  #   @expected [
  #     true,
  #     true,
  #     true,
  #     true,
  #     false
  #   ]
  #   for {given, expected} <- Enum.zip(@cases, @expected) do
  #     test "given #{inspect(given)}" do
  #       plan = Plan.cast_factory_shorthands(unquote(Macro.escape(given)))
  #       assert Plan.valid?(plan) == unquote(expected)
  #     end
  #   end
  # end
end
