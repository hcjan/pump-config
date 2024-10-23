module cetus_fun::swap {

    use std::string::{Self};
    use cetus_fun::config::{Self, FeeConfig};
    use cetus_fun::math::{calculate_buy_amount, calculate_sui_amount, get_token_price, get_max_sui_to_raise};
    use cetus_fun::event::{ publish_event};
    use sui::coin::{Self, Coin, CoinMetadata, get_symbol};
    use sui::balance::{Self, Balance};
    use sui::event::{Self};
    use sui::clock::{Clock, timestamp_ms};
    use sui::sui::SUI;
    use std::ascii::{String};

    use cetus_clmm::factory::{ Pools, create_pool_with_liquidity};
    use cetus_clmm::config::{ GlobalConfig};


    // Constant definitiona
    const INITIAL_SUPPLY: u64 = 1_000_000_000_000_000_000; 

    const TICK_SPACING: u32 = 2;
    const INITIAL_PRICE: u128 = 18446744073;
    const INITIAL_TICK_LOWER_IDX: u32 = 4294523660;
    const INITIAL_TICK_UPPER_IDX: u32 = 443636;
    const INITIAL_AMOUNT_A: u64 = 1;
    const INITIAL_AMOUNT_B: u64 = 1;


    // Error codes
    const EAlreadyListedOnDex: u64 = 0;
    const ENotEnoughBalance: u64 = 1;


   
    // Token information structure
    public struct TokenInfo<phantom T> has key {
        id: UID,
        balance: Balance<T>,
        sui_balance: Balance<SUI>,
        is_listed_on_dex: bool,
        creator: address,
        total_volume: u64,    
        metadata: CoinMetadata<T>
    }

    // Event emitted when a swap occurs
    public struct SwapEvent has copy, drop {
        token_info_id: ID,
        swapper: address,
        is_buy: bool,
        amountToken: u64,
        amountSui: u64,
        price: u64,
        ticker: String,
        time_stamp: u64
    }

    public struct ListToDex has copy, drop{
        token_info_id: ID
    }


   

   public fun initialize<T: drop>(
        coin: Coin<T>,
        metadata: CoinMetadata<T>,
        ctx: &mut TxContext
    ): ID {

        let token_info = TokenInfo<T> {
            id: object::new(ctx),
            balance: coin::into_balance(coin),
            sui_balance: balance::zero(),
            is_listed_on_dex: false,
            creator: tx_context::sender(ctx),
            total_volume: 0,
            metadata,
        };
        let token_info_id = object::id(&token_info);
        transfer::share_object(token_info);
        token_info_id
    }


    // User buys tokens
     entry fun buy_token<T>(
        token_info: &mut TokenInfo<T>,
        fee_config: &FeeConfig,
        payment: &mut Coin<SUI>,
        amount: u64,
        pools: &mut Pools,
        config: &GlobalConfig,  
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(!token_info.is_listed_on_dex, EAlreadyListedOnDex);
        let sui_amount = coin::value(payment);
        assert!(sui_amount >= amount, ENotEnoughBalance); // Ensure sufficient payment

        // Get fee percentage from config
        let fee_percentage = config::fee_rate(fee_config);

        // Calculate fee
        let can_buy_amount = get_max_sui_to_raise() - balance::value(&token_info.sui_balance);
        let fee = (amount * fee_percentage) / 10000;
        let mut sui_amount_after_fee = amount - fee;
        if(sui_amount_after_fee > can_buy_amount){
            sui_amount_after_fee = can_buy_amount;
        };


        // Calculate the number of tokens that can be purchased
        let mut token_user_buy_amount = calculate_buy_amount(balance::value(&token_info.sui_balance), sui_amount_after_fee);
        if(token_user_buy_amount > balance::value(&token_info.balance)){
            token_user_buy_amount = balance::value(&token_info.balance)
        };


        // Transfer sui_amount_after_fee to contract
        let sui_balance = coin::balance_mut(payment);
        balance::join(&mut token_info.sui_balance, balance::split(sui_balance, sui_amount_after_fee));

        // Transfer tokens to user
        let token_to_transfer = coin::take(&mut token_info.balance, token_user_buy_amount, ctx);
        transfer::public_transfer(token_to_transfer, tx_context::sender(ctx));

        // Transfer fee to admin
        let fee_coin = coin::take(coin::balance_mut(payment), fee, ctx);
        transfer::public_transfer(fee_coin, config::fee_recipient(fee_config));

        token_info.total_volume = token_info.total_volume + token_user_buy_amount + fee;

        emit_swap_event(object::id(token_info), tx_context::sender(ctx), true, token_user_buy_amount,  sui_amount_after_fee + fee, get_token_price(token_user_buy_amount), get_symbol(&token_info.metadata), timestamp_ms(clock));
        // Check if the SUI balance in TokenInfo is at least 1 SUI
        if (balance::value(&token_info.sui_balance) >= get_max_sui_to_raise()) { // 1 SUI = 1_000_000_000 MIST
            // Create new coins from the balances
            //TODO
            let coin_a = coin::from_balance(balance::split(&mut token_info.balance, INITIAL_AMOUNT_A), ctx);
            let coin_b = coin::from_balance(balance::split(&mut token_info.sui_balance, INITIAL_AMOUNT_B), ctx);

            // Create the pool with the correct coins
            create_pool(pools, config, fee_config, coin_a, coin_b, clock, ctx);
            token_info.is_listed_on_dex = true;
            event::emit(ListToDex {token_info_id: object::id(token_info)});
        }
     
    }


   
    // User sells tokens
    entry fun sell_token<T>(
        token_info: &mut TokenInfo<T>,
        fee_config: &FeeConfig,
        token: &mut Coin<T>,
        amount: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(!token_info.is_listed_on_dex, EAlreadyListedOnDex);
        let token_amount = coin::value(token);
        assert!(token_amount >= amount, ENotEnoughBalance); // Ensure user has enough tokens

        // Get fee percentage from config
        let fee_percentage = config::fee_rate(fee_config);

        // Calculate the amount of SUI to receive after selling
        let sold_amount = INITIAL_SUPPLY - balance::value(&token_info.balance);
        let sui_amount = calculate_sui_amount(balance::value(&token_info.sui_balance), sold_amount, amount);

        // Calculate fee
        let fee = (sui_amount * fee_percentage) / 10000;
        let sui_amount_after_fee = sui_amount - fee;

        // Ensure the contract has sufficient SUI balance
        assert!(balance::value(&token_info.sui_balance) >= sui_amount, 1);

        // Transfer tokens to contract
        let token_balance = coin::balance_mut(token);
        balance::join(&mut token_info.balance, balance::split(token_balance, amount));

        // Transfer SUI to user
        let sui_to_user = coin::take(&mut token_info.sui_balance, sui_amount_after_fee, ctx);
        transfer::public_transfer(sui_to_user, tx_context::sender(ctx));

        // Transfer fee to admin
        let fee_coin = coin::take(&mut token_info.sui_balance, fee, ctx);
        transfer::public_transfer(fee_coin, config::fee_recipient(fee_config));

        token_info.total_volume = token_info.total_volume + sui_amount;

        emit_swap_event(object::id(token_info), tx_context::sender(ctx), false, amount, sui_amount_after_fee, get_token_price(amount), get_symbol(&token_info.metadata), timestamp_ms(clock));
    }


     fun create_pool<T>(
        pools: &mut Pools,
        config: &GlobalConfig,
        fee_config: &FeeConfig,
        coin_a: Coin<T>,
        coin_b: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let (position, remaining_coin_a, remaining_coin_b) = create_pool_with_liquidity<T, SUI>(
            pools,
            config,
            TICK_SPACING,
            INITIAL_PRICE,
            string::utf8(b""),
            INITIAL_TICK_LOWER_IDX,
            INITIAL_TICK_UPPER_IDX,
            coin_a,
            coin_b,
            INITIAL_AMOUNT_A,
            INITIAL_AMOUNT_B,
            true,
            clock,
            ctx
        );
        
        //freeze
        transfer::public_freeze_object(position);
        
        // Handle remaining coins (you might want to transfer them back to the sender or add to some balance)
        if (coin::value(&remaining_coin_a) > 0) {
            transfer::public_transfer(remaining_coin_a, config::fee_recipient(fee_config));
        } else {
            coin::destroy_zero(remaining_coin_a);
        };
        
        if (coin::value(&remaining_coin_b) > 0) {
            transfer::public_transfer(remaining_coin_b, config::fee_recipient(fee_config));
        } else {
            coin::destroy_zero(remaining_coin_b);
        }
    }


     fun emit_swap_event(swap_id: ID, swapper: address, is_buy: bool, amountToken: u64, amountSui: u64, price: u64, ticker: String, time_stamp: u64) {
        event::emit(SwapEvent {
            token_info_id: swap_id,
            swapper,
            is_buy,
            amountToken,
            amountSui,
            price,
            ticker,
            time_stamp
        });
    }

   
}
