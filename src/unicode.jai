utf8_character_count :: (str: string) -> s64 {
    chars := 0;
    bytes := 0;
    while (bytes < str.count) {
        bytes += character_byte_size(str[0]);
        chars += 1;
    }
    
    return chars;
}

character_byte_size :: inline (ch: u8) -> u8 {
    return 1 + trailingBytesForUTF8[ch];
}

// @Cleanup: Shorter name
seek_left_one_utf8_character_byte_pos :: (s: string, _point: int) -> int {
    point := _point - 1;
    while point > 0 {
        c := s[point];
        if (192 & c) != 128  return point;
        point -= 1;
    }

    return 0;
}

// @Cleanup: Shorter name
seek_right_one_utf8_character_byte_pos :: (s: string, point: int) -> int {
    if point == s.count {
        return point;
    }
    return point + 1 + trailingBytesForUTF8[s[point]];
}

// @Cleanup: Naming
seek_left_utf8_until_alphanum :: (s: string, point: int, include_last_non_alphanum_char := true) -> int {
    while point {
        point = seek_left_one_utf8_character_byte_pos(s, point);
        // point = prev_char_byte_offset(s, point);
        if !is_alphanum(s[point]) {
            if !include_last_non_alphanum_char {
                point += character_byte_size(s[point]);
            }
            break;
        }
    }

    return point;
}

// @Cleanup Duplicated from the editor.jai
prev_char_byte_offset :: (str: string, start: s64) -> s64 {
    if start == 0 || !str return 0;
    assert(start >= 0 && start <= str.count, "str.count: % ; start: %", str.count, start);

    ptr := str.data + start;
    ptr -= 1;

    first_bit := ptr.* & 0x80;
    if first_bit == 0x0 return ptr - str.data; // 1 byte length char

    // Cursor (caret) movement is based on characters, not bytes - this issue should never occur!
    first_2bit := ptr.* & 0xc0;
    assert(first_2bit != 0xc0, "The start byte (str.data+start) is in the middle of a Unicode character.");
    assert(first_2bit == 0x80, "Invalid UTF-8"); // the first bit check happens above

    bytes := 1;
    while (ptr.* & 0xc0) == 0x80 && (ptr > str.data) {
        ptr -= 1;
        bytes += 1;
        assert(bytes <= 4, "Invalid UTF-8! We expect less than 5 bytes but we got %", bytes); // it's not totally correct
    }

    assert((ptr.* & 0xc0) == 0xc0, "No more characters are left, and we don't have the byte indicating the Unicode character's byte length.\n");

    return ptr - str.data;
}

#import "Unicode";
#if OS == .WINDOWS {
    #import "Windows_Utf8";
}