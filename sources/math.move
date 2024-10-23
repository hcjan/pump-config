module cetus_fun::math {
    use sui::math::{sqrt, pow};
    
    const COEFFICIENT: u64 = 31622776601683;
    const PRECISION: u64 = 1_000_000_000;


    const MAX_SUI_TO_RAISE: u64 = 1_000_000_000; // 1,000,000 SUI (in MIST)

    /// Calculate the amount of tokens that can be bought with a given amount of SUI
    /// @param sold_amount: The amount of tokens already sold
    /// @param sui_amount: The amount of SUI to be spent on buying tokens
    /// @return The amount of tokens that can be bought
    public fun calculate_buy_amount(sui_raised_amount: u64, sui_amount: u64): u64 {
        COEFFICIENT * (sqrt(sui_amount + sui_raised_amount) - sqrt(sui_raised_amount)) 
    }

    /// Calculate the amount of SUI that can be received by selling a given amount of tokens
    /// @param sold_amount: The amount of tokens already sold (before this sale)
    /// @param token_amount: The amount of tokens to be sold
    /// @return The amount of SUI that can be received
    public fun calculate_sui_amount(current_sui_amount: u64, sold_token_amount: u64, token_amount_to_sell: u64): u64 {
        let sui_amount_after_sell = pow(((sold_token_amount - token_amount_to_sell) * PRECISION / COEFFICIENT),2) / PRECISION / PRECISION;
        current_sui_amount - sui_amount_after_sell
    }

    /// Calculate the current price of the token in SUI
    /// @param sold_amount: The amount of tokens already sold
    /// @return The current price of the token in SUI
    public fun get_token_price(sold_amount: u64): u64 {
        let base_price = 100; // 100 SUI per 1 token initially
        let price_increase_rate = 1; // Price increases by 1 SUI per 1000 tokens sold

        base_price + (sold_amount / 1000) * price_increase_rate
    }

    public fun get_max_sui_to_raise(): u64{
        MAX_SUI_TO_RAISE
    }
}   