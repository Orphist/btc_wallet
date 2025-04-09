require "bitcoin"
require "dry-initializer"
require "dry-monads"
require "dry-types"
require_relative 'btc_wallet/fee'
require_relative 'btc_wallet/pool_api'
require_relative 'btc_wallet/tx'

module BtcWallet

  autoload :Fee, 'btc_wallet/fee'
  autoload :Tx, 'btc_wallet/tx'
  autoload :PoolApi, 'btc_wallet/pool_api'

  class << self
    attr_accessor :config

    def config
      @config ||= {
          network: ENV.fetch('BITCOIN_NETWORK', :signet),
          key_file_name: File.join(ENV.fetch('WALLET_DATA_DIR', "~/.bitcoinrb"),
                                   ENV.fetch('WALLET_KEY_FILE', "btc_wallet_pkey"))
      }
    end

    def api_base_path
      config[:network]
    end
  end
end
