module pump_fun::config {

    use sui::event;

    /// Admin capability for managing fee config
    public struct AdminCap has key, store {
        id: UID
    }

    /// Config object to store fee-related information
    public struct FeeConfig has key {
        id: UID,
        fee_recipient: address,
        fee_rate: u64,
    }

    /// Event emitted when fee config is updated
    public struct FeeConfigUpdated has copy, drop {
        new_recipient: address,
        new_rate: u64,
    }


    /// Create and share the initial FeeConfig, and transfer AdminCap to the initializer
    fun init(ctx: &mut TxContext) {
        let admin_cap = AdminCap {
            id: object::new(ctx)
        };
        transfer::transfer(admin_cap, tx_context::sender(ctx));

        let fee_config = FeeConfig {
            id: object::new(ctx),
            fee_recipient: tx_context::sender(ctx),
            fee_rate: 1,
        };
        transfer::share_object(fee_config);
    }

    /// Get the current fee recipient address
    public fun fee_recipient(config: &FeeConfig): address {
        config.fee_recipient
    }

    /// Get the current fee rate
    public fun fee_rate(config: &FeeConfig): u64 {
        config.fee_rate
    }

    /// Update the fee configuration (only callable by the admin)
    entry fun update_fee_config(
        _: &AdminCap,
        config: &mut FeeConfig,
        new_recipient: address,
        new_rate: u64,
    ) {
        config.fee_recipient = new_recipient;
        config.fee_rate = new_rate;

        // Emit an event for the update
        event::emit(FeeConfigUpdated {
            new_recipient,
            new_rate,
        });
    }

  
}
