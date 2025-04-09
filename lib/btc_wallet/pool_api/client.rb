require 'faraday'
require 'faraday/request/url_encoded'

module BtcWallet
  module PoolApi
    class Client
      #client for https://mempool.space/signet/docs/api/rest

      extend  Dry::Initializer
      include Dry::Monads[:result, :maybe, :do, :try]

      param :api_base_path, type: Dry::Types['coercible.string'], default: proc { BtcWallet.api_base_path }

      # curl -sSL "https://mempool.space/signet/api/address/mg7Rdvyf4chScSH5GAVXWHJJHh2N2Cir3g"|jq
      def getbalance(address)
        response = yield Try { build_connection.get("address/#{address}") }.to_result
        PoolApi::Responses::AddressBalanceData.new(response.body).balance
      end

      # curl -sSL "https://mempool.space/signet/api/address/mg7Rdvyf4chScSH5GAVXWHJJHh2N2Cir3g/utxo"|jq
      # curl -sSL "https://mempool.space/signet/api/address/tb1psv6wgyyf226ka8dpsskrjun2kdgnfhhlxdl7l83srzqrh93manwsj3dg26/utxo"|jq
      def utxo(address)
        response = yield Try { build_connection.get("address/#{address}/utxo") }.to_result
        Success(response.body)
      end

      def send_tx(tx_hex)
        response = yield Try { build_connection.post("tx") do |request|
          request.body = tx_hex
        end }.to_result
        Success(response)
      end

      # curl -sSL "https://mempool.space/signet/api/v1/mining/blocks/fee-rates/24h"|jq
      def fee_rates(period = '24h')
        period = '24h' unless %w(24h 3d 1w 1m 3m 6m 1y 2y 3y).include? period
        response = yield Try { build_connection.get("v1/mining/blocks/fee-rates/#{period}") }.to_result
        Success(response.body)
      end

      private

      BASE_URL = 'https://mempool.space/'
      DEFAULT_HEADERS = {
        "Content-Type" => "application/json"
      }.freeze
      RETRY_PERIOD = 30

      private_constant :BASE_URL, :DEFAULT_HEADERS, :RETRY_PERIOD

      def build_connection
        ::BtcWallet::PoolApi::Connection.new(
          base_url: "#{BASE_URL}#{api_base_path}/api",
          options: {
            headers: DEFAULT_HEADERS,
            retry_period: RETRY_PERIOD,
          }
        ).connection
      end
    end
  end
end
