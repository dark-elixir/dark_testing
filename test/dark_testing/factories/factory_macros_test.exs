defmodule DarkTesting.Factories.FactoryMacrosTest do
  @moduledoc """
  Test for query `DarkTesting.Factories.FactoryMacros`.
  """

  use ExUnit.Case, async: true
  alias DarkTesting.Factories.FactoryMacros
  alias DarkTesting.Factories.FactoryShorthand
  alias DarkTesting.Factories.MutationShorthand
  doctest DarkTesting.Factories.FactoryMacros, import: true

  def example_block do
    quote location: :keep do
      build(:user, :random_user, with: [user: [:register_by_funding_app, :email_confirm]])
      build(:bank_statement_month_1, :bank_statement, %{institution: "BoA"})
      build(:bank_statement_month_2, :bank_statement, params: %{institution: "Chase"})
      build(:bank_statement_month_3, :bank_statement)
      build(:bank_statements, from: [bank_statement: [:month_1, :month_2, :month_3]])

      build(:bank_statement_mos1, :bank_statement)
      build(:bank_statement_mos1, :bank_statement)
      mutation :user_register, [:user_register_by_funding_app, :user_update_email]
      mutation(:user_update)
      mutation :user_short, %{custom: true, short: true}
      mutation(:user_complex, [:user_custom], %{custom: true, complex: true})

      mutation(:user_complex, [:user_custom], params: %{custom: true, complex: true, params: true})
    end
  end

  # def example_block_put do
  #   quote location: :keep do
  #     build(:user, :random_user, with: [user: [:register_by_funding_app, :email_confirm]])
  #     put :user_id, from: [user: :id]
  #   end
  # end

  describe ".cast/1" do
    test "given valid :with mutations" do
      block =
        quote location: :keep do
          build(:user, with: [user: [:register_by_funding_app, :email_confirm]])
        end

      assert {factories, []} = FactoryMacros.cast(block)

      assert factories == [
               %FactoryShorthand{
                 key: :user,
                 name: :user,
                 mutations: [:user_register_by_funding_app, :user_email_confirm]
               }
             ]
    end

    test "given valid :from assocs" do
      block =
        quote location: :keep do
          build(:bank_statements, from: [bank_statement: [:month_1, :month_2, :month_3]])
        end

      assert {factories, []} = FactoryMacros.cast(block)

      assert factories == [
               %FactoryShorthand{
                 assocs: [
                   :bank_statement_month_1,
                   :bank_statement_month_2,
                   :bank_statement_month_3
                 ],
                 key: :bank_statements,
                 name: :bank_statements
               }
             ]
    end

    test "given valid :put with :as key lookup" do
      block =
        quote location: :keep do
          build(:user)
          put(:user_id, as: [:user, :id])
        end

      assert {factories, []} = FactoryMacros.cast(block)

      assert factories == [
               %FactoryShorthand{
                 mode: :build,
                 key: :user,
                 name: :user
               },
               %FactoryShorthand{
                 mode: :put,
                 key: :user_id,
                 name: :user_id,
                 lookup: [:user, :id]
               }
             ]
    end

    test "given valid :put with :as key lookup with fun/0" do
      block =
        quote location: :keep do
          build(:user)
          put(:user_id, as: fn -> 1 end)
        end

      assert {factories, []} = FactoryMacros.cast(block)
      assert [build_user, put_user_id] = factories

      assert build_user ==
               %FactoryShorthand{
                 mode: :build,
                 key: :user,
                 name: :user
               }

      assert put_user_id ==
               %FactoryShorthand{
                 mode: :put,
                 key: :user_id,
                 name: :user_id,
                 lookup: put_user_id.lookup
               }

      assert is_function(put_user_id.lookup, 0)
    end

    test "given valid :put with :as key lookup with fun/1" do
      block =
        quote location: :keep do
          build(:user)
          put(:user_id, as: & &1.user.id)
        end

      assert {factories, []} = FactoryMacros.cast(block)
      assert [build_user, put_user_id] = factories

      assert build_user ==
               %FactoryShorthand{
                 mode: :build,
                 key: :user,
                 name: :user
               }

      assert put_user_id ==
               %FactoryShorthand{
                 mode: :put,
                 key: :user_id,
                 name: :user_id,
                 lookup: put_user_id.lookup
               }

      assert is_function(put_user_id.lookup, 1)
    end

    test "given valid :example_block" do
      assert {factories, mutations} = FactoryMacros.cast(example_block())

      assert factories == [
               %FactoryShorthand{
                 key: :user,
                 name: :random_user,
                 mutations: [:user_register_by_funding_app, :user_email_confirm]
               },
               %FactoryShorthand{
                 key: :bank_statement_month_1,
                 name: :bank_statement,
                 params: %{institution: "BoA"}
               },
               %FactoryShorthand{
                 key: :bank_statement_month_2,
                 name: :bank_statement,
                 params: %{institution: "Chase"}
               },
               %FactoryShorthand{
                 key: :bank_statement_month_3,
                 name: :bank_statement
               },
               %FactoryShorthand{
                 assocs: [
                   :bank_statement_month_1,
                   :bank_statement_month_2,
                   :bank_statement_month_3
                 ],
                 key: :bank_statements,
                 name: :bank_statements
               },
               %FactoryShorthand{
                 key: :bank_statement_mos1,
                 name: :bank_statement
               },
               %FactoryShorthand{
                 key: :bank_statement_mos1,
                 name: :bank_statement
               }
             ]

      assert mutations == [
               %MutationShorthand{
                 key: :user_register,
                 mutations: [:user_register_by_funding_app, :user_update_email]
               },
               %MutationShorthand{
                 key: :user_update,
                 mutations: [:user_update]
               },
               %MutationShorthand{
                 key: :user_short,
                 mutations: [:user_short],
                 params: %{custom: true, short: true}
               },
               %MutationShorthand{
                 key: :user_complex,
                 mutations: [:user_custom],
                 params: %{custom: true, complex: true}
               },
               %MutationShorthand{
                 key: :user_complex,
                 mutations: [:user_custom],
                 params: %{complex: true, custom: true, params: true}
               }
             ]
    end

    #   test "given valid :example_block_put" do
    #     assert {factories, mutations} = FactoryMacros.cast(example_block_put())
    #     assert factories == []
    #     assert mutations == []
    # end
  end
end
