module BtcWallet
  module PoolApi
    module Responses
      class AddressBalanceData
        extend  Dry::Initializer

        param :response_body, type: Dry::Types['strict.hash']

        # extract data from response:
        # curl -sSL "https://pool.space/signet/api/address/mg7Rdvyf4chScSH5GAVXWHJJHh2N2Cir3g"|jq
        def balance
          chain_funded_txo_sum = response_body.dig("chain_stats", "funded_txo_sum")
          chain_spent_txo_sum = response_body.dig("chain_stats", "spent_txo_sum")
          confirmed_balance = chain_funded_txo_sum - chain_spent_txo_sum

          pool_spent_txo_sum = response_body.dig("mempool_stats", "spent_txo_sum")
          pool_funded_txo_sum = response_body.dig("mempool_stats", "funded_txo_sum")
          unconfirmed_balance = confirmed_balance + pool_funded_txo_sum - pool_spent_txo_sum

          {
            confirmed_balance: confirmed_balance,
            unconfirmed_balance: unconfirmed_balance
          }
        end
      end
    end
  end
end

