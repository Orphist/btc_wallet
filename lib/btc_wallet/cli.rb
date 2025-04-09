# frozen_string_literal: true

require "thor"
require 'json'
require 'digest'
require "bitcoin"
require "readline"
require "btc_wallet"

module BtcWallet
  class CLI < Thor
    check_unknown_options!
    package_name "BtcWallet"

    class_option :verbose, type: :boolean, aliases: "-v"

    class_option :file_path, type: :string, default: BtcWallet.config[:key_file_name], required: true,
                 aliases: "-f", desc: "Path to private key file"
    class_option :network, type: :string, default: BtcWallet.config[:network], required: true, aliases: "-n",
                 desc: "Network type, e.g. :signet", enum: %w(signet testnet mainnet regtest)

    desc "generate", "generate private key file"
    def generate
      begin
        file_path_name = File.expand_path(options[:file_path])
        if File.exist?(file_path_name)
          puts "File name #{file_path_name} already taken! Use existed privkey or set other file name for new privkey."
        else
          Bitcoin.chain_params = options[:network]
          key = Bitcoin::Key.generate
          FileUtils.mkdir_p(File.dirname(file_path_name)) unless Dir.exists?(File.dirname(file_path_name))
          File.open(file_path_name, "w") do |f|
            f.write(key.to_wif)
          end
          puts "CLI:priv_key saved to file #{file_path_name}"
        end
      rescue => e
        puts "CLI:Exception:#{e}"
      end
    end

    desc "balance", "get balance for address from private key file"
    def balance
      begin
        file_path_name = File.expand_path(options[:file_path])
        key = load_priv_key(file_path_name, options[:network])
        if key
          address = key.to_addr
          balance = PoolApi::Client.new.getbalance(address)
          puts "✩₊˚.⋆ address '#{key.to_addr}' balance: #{balance}"
        else
          puts "Address for private key file #{file_path_name} not exists, use 'generate' command first"
        end
      rescue => e
        puts "CLI:Exception:#{e}"
      end
    end

    option :address, type: :string, required: true, aliases: "-a", desc: "address to send coins"
    option :amount, type: :numeric, required: true, aliases: "-m", desc: "amount of satoshi to send"
    desc "send", "send amount to address from addr of private key file"
    def send
      begin
        file_path_name = File.expand_path(options[:file_path])
        if File.exist?(file_path_name)
          puts "CLI:file_path_name #{file_path_name} w/priv_key loaded"
          result = BtcWallet::Tx.new(options[:address], options[:amount], file_path_name).call
          puts "✩₊˚.⋆ tx: #{result}"
        else
          puts "File name #{file_path_name} - should be generated first!"
        end
      rescue => e
        puts "CLI:Exception: tx send(#{[[:address], options[:amount]].join(',')}) error=#{e}"
      end
    end

    no_commands do
      def load_priv_key(file_path_name, network)
        puts "CLI:file_path_name #{file_path_name}"

        if File.exist?(file_path_name)
          Bitcoin.chain_params = network
          Bitcoin::Key.from_wif(File.open(file_path_name, "r").readlines.first)
        else
          puts "File name #{file_path_name} - should be generated first!"
        end
      end
    end
  end

end