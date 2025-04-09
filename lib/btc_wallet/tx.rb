module BtcWallet
  class Tx
    extend  Dry::Initializer
    include Dry::Monads[:result, :maybe, :do, :try]
    include ::BtcWallet::Fee

    attr_accessor :key, :tx

    param :to_address, type: Dry::Types['strict.string']
    param :amount, type: Dry::Types['strict.integer']
    param :file_path, type: Dry::Types['strict.string'], default: proc { BtcWallet.config[:key_file_name] }
    param :sender_addr_type, type: Dry::Types['strict.symbol'].enum(:p2pkh, :p2wpkh),
          default: proc { :p2pkh }

    def call
      yield prepare_tx
      yield build_tx
      send_tx
    end

    private

    def prepare_tx
      Bitcoin.chain_params = BtcWallet.config[:network]

      @key = yield load_priv_key
      yield utxos_list
      check_funds
    end

    def check_funds
      return Failure("Dust amount error") if dust?(amount)

      if (amount > total_unspent)
        Failure("UTXO Insufficient Funds error")
      else
        Success(true)
      end
    end

    def total_unspent
      return @total_unspent if defined? @total_unspent

      @total_unspent = utxos_list.value!.map { |utxo| utxo["value"] }.sum
    end

    def build_tx
      @tx = Bitcoin::Tx.new
      tx.version = 2
      build_tx_in
      build_tx_out
      sign_tx
      tx.valid? ? Success() : Failure()
    end

    def build_tx_in
      utxos_list.value!.each do |utxo|
        tx.in << Bitcoin::TxIn.new(out_point: Bitcoin::OutPoint.from_txid(utxo["txid"], utxo["vout"]))
      end
    end

    def build_tx_out
      tx.out << Bitcoin::TxOut.new(value: amount, script_pubkey: script_pubkey_receiver)
      build_change_out
    end

    def sign_tx
      utxos_list.value!.each_with_index do |utxo, tx_in_idx|
        send(sign_tx_input, tx, tx_in_idx, utxo["value"])
      end
    end

    def sign_tx_input
      "sign_#{sender_addr_type}"
    end

    def send_tx
      result = api_client.send_tx(tx.to_hex)
      if result.failure?
        Failure(result.failure)
      else
        Success(result.value!)
      end
    end

    def sign_p2pkh(tx, tx_in_idx, _amount)
      sig_hash = tx.sighash_for_input(tx_in_idx, script_pubkey_sender)
      signature = key.sign(sig_hash, false) + [Bitcoin::SIGHASH_TYPE[:all]].pack('C')
      tx.in[tx_in_idx].script_sig << signature
      tx.in[tx_in_idx].script_sig << key.pubkey.htb
    end

    def sign_p2wpkh(tx, tx_in_idx, amount)
      sig_hash = tx.sighash_for_input(tx_in_idx, script_pubkey_sender, sig_version: :witness_v0, amount: amount)
      signature = key.sign(sig_hash, false) + [Bitcoin::SIGHASH_TYPE[:all]].pack('C')
      tx.in[tx_in_idx].script_witness.stack << signature
      tx.in[tx_in_idx].script_witness.stack << key.pubkey.htb
    end

    def build_change_out
      change_amount = total_unspent - amount - calculated_fee
      puts total_unspent: total_unspent, amount: amount, fee_rate: fee_rate, change_amount: change_amount
      return if dust?(change_amount)

      # tx.out for change:
      tx_out = Bitcoin::TxOut.new(value: change_amount, script_pubkey: script_pubkey_change)
      return if tx_out.dust?

      tx.out << tx_out
    end

    def calculated_fee
      get_fee(tx.in.count, tx.out.count + 1) # 1 to_address + 1 for change
    end

    def script_pubkey_sender
      Bitcoin::Script.parse_from_addr(sender_address)
    end

    def script_pubkey_receiver
      Bitcoin::Script.parse_from_addr(to_address)
    end

    def script_pubkey_change
      Bitcoin::Script.parse_from_addr(change_address)
    end

    def load_priv_key
      file_path_name = File.expand_path(file_path)
      if File.exist?(file_path_name)
        Success(Bitcoin::Key.from_wif(File.open(file_path_name, "r").readlines.first))
      else
        Failure("TX:File name #{file_path_name} privkey error!")
      end
    end

    def utxos_list
      return @utxos_list if defined? @utxos_list

      result = api_client.utxo(sender_address)
      @utxos_list = if result.failure?
                         Failure("UTXO fetching error")
                       else
                         Success(result.value!)
                       end
    end

    def api_client
      return @api_client if defined? @api_client

      @api_client = BtcWallet::PoolApi::Client.new
    end

    def sender_address
      key.send "to_#{sender_addr_type}"
    end

    def change_address
      key.send "to_#{sender_addr_type}"
    end
  end
end