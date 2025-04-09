module BtcWallet
  module Fee
    FEE_DEFAULT = 1_000
    FEE_DUST_LIMIT = 546
    FEE_RECENT_BLOCKS_DEPTH = 200
    FEE_TOP_PERCENTILE = 25

    def get_fee(inputs_num, outputs_num)
      tx_size = 148 * inputs_num + 34 * outputs_num + 10
      (1 + tx_size / 1_000) * fee_rate
    end

    def dust?(amount)
      amount < FEE_DUST_LIMIT
    end

    private

    def fee_rate
      return @fee_rate if defined? @fee_rate

      fee_rates = PoolApi::Client.new.fee_rates
      return @fee_rate = FEE_DEFAULT if fee_rates.failure?

      recent_fee_rate = select_fees_75percentile(fee_rates.value!)
      top_precentile_qty = (recent_fee_rate.count * FEE_TOP_PERCENTILE/100.0).ceil
      @fee_rate = recent_fee_rate.sort[-top_precentile_qty..-1].sum/top_precentile_qty
    end

    def select_fees_75percentile(fee_rates_list)
      strart_idx = [FEE_RECENT_BLOCKS_DEPTH, fee_rates_list.count].min
      fee_rates_list.sort_by {|r| r["timestamp"]}.map {|rates| rates['avgFee_75']}[-strart_idx..-1]
    end
  end
end