module pump_fun::event {
    use sui::event;

    use std::string::{ String};

    public struct PublishEvent has copy, drop {
        sender: address,
        uuid: String
    }
    
    public fun publish_event(sender: address, uuid: String) {
        event::emit(PublishEvent {
            sender: sender,
            uuid: uuid
        });
    }
}