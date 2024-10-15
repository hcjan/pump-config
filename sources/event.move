module pump_fun::event {
    use sui::event;

    use std::string::{ String};

    public struct PublishEvent has copy, drop {
        sender: address,
        uuid: String,
        token_info_id: address
    }
    
    public fun publish_event(sender: address, uuid: String, token_info_id: address) {
        event::emit(PublishEvent {
            sender: sender,
            uuid: uuid,
            token_info_id: token_info_id
        });
    }
}