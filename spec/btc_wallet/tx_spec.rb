require "btc_wallet/tx"
require 'spec_helper'

RSpec.describe ::BtcWallet::Tx, :aggregate_faliures do
  let(:doubled_tx) { instance_double(described_class) }
  let(:client_connection) { ::BtcWallet::PoolApi::Connection }
  let(:doubled_client) { instance_double(::BtcWallet::PoolApi::Client) }
  let(:p2pkh_addr) { "mg7Rdvyf4chScSH5GAVXWHJJHh2N2Cir3g" }
  let(:send_amount) { 4_000 }
  let(:params) { [p2pkh_addr, send_amount] }
  let(:priv_key) { ::Bitcoin::Key.from_wif("cSHN1Ls5eLFhbBuoPmByESoweZcojJJKq2uk9spiTZDjg7ifSJCH") }

  let(:utxo_payload) { fixture_file('utxo_addr1.json') }
  let(:utxo_result) { instance_double('Dry::Validation::Result', failure?: false, value!: utxo_payload) }

  let(:fee_rates_payload) { fixture_file('fee_rates_24h.json') }
  let(:fee_rates_result) { instance_double('Dry::Validation::Result', failure?: false, value!: fee_rates_payload) }
  let(:fee_rates_default_result) { instance_double('Dry::Validation::Result', failure?: true, value!: 1_000) }

  let(:tx_send_result) { instance_double('Dry::Validation::Result', failure?: false, value!: "tx_hash") }

  def failed_response(msg)
    instance_double('Dry::Validation::Result', failure?: true, value!: msg)
  end

  subject { described_class.new(*params).call }

  before do
    Bitcoin.chain_params = BtcWallet.config[:network]
    allow(::Bitcoin::Key).to receive(:from_wif).and_return(priv_key)
    allow(::BtcWallet::PoolApi::Client).to receive(:new).with(any_args).and_return(doubled_client)
    allow(doubled_client).to receive(:utxo).with(p2pkh_addr).and_return(utxo_result)
    allow(doubled_client).to receive(:fee_rates).with(no_args).and_return(fee_rates_result)
    allow(doubled_client).to receive(:send_tx).with(any_args).and_return(tx_send_result)
  end

  it "all goes right - ret tx_hash" do
    expect(doubled_client).to receive(:utxo).with(p2pkh_addr).and_return(utxo_result)
    expect(doubled_client).to receive(:fee_rates).with(no_args).and_return(fee_rates_result)
    expect(doubled_client).to receive(:send_tx).with(any_args).and_return(tx_send_result)

    expect(subject).to be_success
  end

  context "when send_tx some failed" do
    context "stage privkey failed" do
      before do
        allow(::Bitcoin::Key).to receive(:from_wif).and_raise(StandardError, "error privkey")
      end

      it "send_tx failed" do
        expect(doubled_client).not_to receive(:utxo)
        expect(doubled_client).not_to receive(:fee_rates)
        expect(doubled_client).not_to receive(:send_tx)

        expect { subject }.to raise_error("error privkey")
      end
    end

    context "utxo fetch failed" do
      before do
        allow(doubled_client).to receive(:utxo).with(p2pkh_addr).and_return(failed_response("UTXO fetching error"))
      end

      it "send_tx failed" do
        expect(doubled_client).not_to receive(:fee_rates)
        expect(doubled_client).not_to receive(:send_tx)

        expect(subject.failure).to eq("UTXO fetching error")
      end
    end

    context "fee_rates fetch failed" do
      before do
        allow(client_connection).to receive(:new).with(any_args).and_raise(StandardError, "fee rates fetch error 400")
      end

      it "takes default fee, send_tx ok" do
        expect(doubled_client).to receive(:fee_rates).with(no_args).and_return(fee_rates_default_result)
        expect(doubled_client).to receive(:send_tx).with(any_args).and_return(tx_send_result)

        subject
      end
    end

    context "UTXO Insufficient Funds" do
      let(:send_amount) { 444_000 }

      it "takes default fee, send_tx fail" do
        result = subject
        expect(result.failure).to eq("UTXO Insufficient Funds error")
        expect(result).to be_failure
      end
    end

    context "dust amount" do
      let(:send_amount) { 500 }

      it "takes default fee, send_tx fail" do
        result = subject
        expect(result.failure).to eq("Dust amount error")
        expect(result).to be_failure
      end
    end
  end
end