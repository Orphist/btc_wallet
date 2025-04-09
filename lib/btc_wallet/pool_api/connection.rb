require 'faraday'
require 'faraday_middleware-request-retry'
require 'faraday_middleware'
require 'logger'

module BtcWallet
  module PoolApi
    class Connection
      attr_reader :connection

      def initialize(conn_options)
        @connection = build_connection(conn_options[:base_url], conn_options[:options])
      end

      private

      def build_connection(base_url, options)
        retry_period = options.delete(:retry_period) || 30
        logger = Logger.new($stdout, level: ENV.fetch('LOGGER_LEVEL', :error))
        Faraday.new(base_url, options) do |conn|
          conn.response :json
          conn.response :logger, logger, bodies: true
          conn.use FaradayMiddleware::Request::Retry, logger: logger, retry_after: retry_period
          conn.use FaradayMiddleware::FollowRedirects
          conn.request :multipart
          conn.request :url_encoded
        end
      end
    end
  end
end
