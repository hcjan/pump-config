module pump_fun::math {
    

    /// Calculate the amount of tokens that can be bought with a given amount of SUI
    /// @param sold_amount: The amount of tokens already sold
    /// @param sui_amount: The amount of SUI to be spent on buying tokens
    /// @return The amount of tokens that can be bought
    public fun calculate_buy_amount(sold_amount: u64, sui_amount: u64): u64 {
        // Assuming a simple linear pricing model
        // Price increases as more tokens are sold
        let base_price = 100; // 100 SUI per 1 token initially
        let price_increase_rate = 1; // Price increases by 1 SUI per 1000 tokens sold

        let current_price = base_price + (sold_amount / 1000) * price_increase_rate;
        
        sui_amount / current_price
    }

    /// Calculate the amount of SUI that can be received by selling a given amount of tokens
    /// @param sold_amount: The amount of tokens already sold (before this sale)
    /// @param token_amount: The amount of tokens to be sold
    /// @return The amount of SUI that can be received
    public fun calculate_sell_amount(sold_amount: u64, token_amount: u64): u64 {
        let base_price = 100; // 100 SUI per 1 token initially
        let price_increase_rate = 1; // Price increases by 1 SUI per 1000 tokens sold

        let start_price = base_price + (sold_amount / 1000) * price_increase_rate;
        let end_price = base_price + ((sold_amount + token_amount) / 1000) * price_increase_rate;

        // Calculate average price
        let avg_price = (start_price + end_price) / 2;

        token_amount * avg_price
    }

    /// Calculate the current price of the token in SUI
    /// @param sold_amount: The amount of tokens already sold
    /// @return The current price of the token in SUI
    public fun get_token_price(sold_amount: u64): u64 {
        let base_price = 100; // 100 SUI per 1 token initially
        let price_increase_rate = 1; // Price increases by 1 SUI per 1000 tokens sold

        base_price + (sold_amount / 1000) * price_increase_rate
    }
}   