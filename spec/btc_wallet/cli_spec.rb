require "btc_wallet/cli"

RSpec.describe ::BtcWallet::CLI do
  let(:file_path) { "./spec/tmp/test_priv_key_file" }
  let(:file_pathname) { File.expand_path(file_path) }

  after do
    File.delete(file_pathname) if File.exist?(file_pathname)
  end

  def command(options = {}, usage)
    options.each do |key, value|
      options[key] = Thor::Option.parse(key, value)
    end

    @command ||= Thor::Command.new("generate", "apply", "plumbers", nil, usage, options)
  end

  describe "#formatted_usage" do
    it "ok" do
      object = Struct.new(:namespace, :arguments).new("Usage", [])
      expect(command({}, ['generate --file_path ./spec/tmp/test_priv_key_file']).formatted_usage(object)).to eq("Usage:generate --file_path ./spec/tmp/test_priv_key_file")
    end
  end

  context "#generate" do
    it "when priv_key file does not exist - displays a message" do
      expect do
        described_class.new.invoke(:generate, [], { file_path: file_path })
      end.to output(
                      a_string_including("priv_key saved")
                   ).to_stdout
    end

    it "when priv_key file does already exist - displays a message" do
      allow(::Bitcoin::Key).to receive(:from_wif).and_return(:priv_key)
      FileUtils.touch(file_pathname)
      expect do
        described_class.new.invoke(:generate, [], { file_path: file_path })
      end.to output(
                      a_string_including("File name #{file_pathname} already taken")
                   ).to_stdout
    end
  end

  context "when the priv_key file exists" do
    let(:doubled_tx) { instance_double(::BtcWallet::Tx) }
    let(:success_tx_hash) { "success_tx_hash" }

    before do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:delete).and_return(true)
      allow(::Bitcoin::Key).to receive(:from_wif).and_return(:priv_key)
      allow(::BtcWallet::Tx).to receive(:new).with(any_args).and_return(doubled_tx)
    end

    context "#send tx success" do
      it "displays a message" do
        expect(doubled_tx).to receive(:call).and_return(success_tx_hash)
        expect do
          described_class.new.invoke(:send, [], { address: :correct_address, amount: 1_000 })
        end.to output(
                        a_string_including("tx: success_tx_hash")
                     ).to_stdout
      end
    end

    context "#send tx failed" do
      it "displays a message" do
        expect(doubled_tx).to receive(:call).and_raise(StandardError, "error sending")
        expect do
          described_class.new.invoke(:send, [], { address: :correct_address, amount: 1_000 })
        end.to output(
                        a_string_including("error sending")
                     ).to_stdout
      end
    end
  end

  context "#balance" do
    let(:doubled_client) { instance_double(::BtcWallet::PoolApi::Client) }
    let(:balance_payload) { { confirmed_balance: 42_000, unconfirmed_balance: 20_000 } }
    let(:priv_key_object) { OpenStruct.new(to_addr: "btc_addr1") }

    before do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:delete).and_return(true)
      allow(::Bitcoin::Key).to receive(:from_wif).and_return(priv_key_object)
      allow(::BtcWallet::PoolApi::Client).to receive(:new).with(any_args).and_return(doubled_client)
    end

    it "dust - displays a message" do
      allow(doubled_client).to receive(:getbalance).with(any_args).and_raise(StandardError, "failed")
      expect do
        described_class.new.invoke(:balance, [], { })
      end.to output(
                      a_string_including("failed")
                   ).to_stdout
    end

    it "does already exist - displays a message" do
      expect(doubled_client).to receive(:getbalance).with(any_args).and_return(balance_payload)
      expect do
        described_class.new.invoke(:balance, [], { })
      end.to output(
                      a_string_including("address 'btc_addr1' balance:")
                   ).to_stdout
    end
  end
end