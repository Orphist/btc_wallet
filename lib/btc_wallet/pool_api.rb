require_relative 'pool_api/responses'
require_relative 'pool_api/connection'
require_relative 'pool_api/client'

module BtcWallet
  module PoolApi
    autoload :Responses, 'btc_wallet/pool_api/responses'
    autoload :Connection, 'btc_wallet/pool_api/connection'
    autoload :Client, 'btc_wallet/pool_api/client'
  end
end
