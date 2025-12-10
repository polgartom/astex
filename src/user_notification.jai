push_user_notification :: (text: string, level: User_Notification.Level, duration := 0.5) -> *User_Notification {
    it := array_add(*user_notifications);
    it.text = copy_string(text);
    it.level = level;
    it.duration = duration;
    it.started_at = frame_time64;
    
    return it;
}

user_notifications_update :: () {
    removes: [..] s64;
    removes.allocator = temp;
    
    if user_notifications.count > 0 {
        redraw_requested = true;
    }
    
    for * user_notifications {
        if it.hovered {
            it.hovered = false;
            it.started_at = frame_time64;
        }
    
        delta := frame_time64 - it.started_at;
        if delta >= it.duration || it.closed {
            array_add(*removes, it_index);
        }
    }
    
    for index: removes {
        array_ordered_remove_by_index(*user_notifications, index);
    }    
}

get_bg_color :: (level: User_Notification.Level) -> Vector4 {
    if level == {
        case .INFO;    return #run hex_to_vec4(0x4FC3F7ff);
        case .SUCCESS; return #run hex_to_vec4(0x43A047ff);
        case .WARNING; return #run hex_to_vec4(0xFB8C00ff);
        case .ERROR;   return #run hex_to_vec4(0xB00020ff);
    }
    
    return map_color_to_vec4(.TEXT_DEFAULT);
}

get_fg_color :: (level: User_Notification.Level) -> Vector4 {
    if level == {
        case .INFO;    return #run hex_to_vec4(0x00_00_00_00);
        case .SUCCESS; return #run hex_to_vec4(0x00_00_00_00);
        case .WARNING; return #run hex_to_vec4(0x00_00_00_00);
        case .ERROR;   return #run hex_to_vec4(0xFF_FF_FF_FF);
    }
    
    return map_color_to_vec4(.BACKGROUND2);
}

user_notifications: [..] User_Notification;

User_Notification :: struct {
    text: string;
    level: Level;
    started_at: float64;
    duration: float64;
    closed: bool;
    hovered: bool;
    
    Level :: enum u8 { INFO; SUCCESS; WARNING; ERROR; };
}
