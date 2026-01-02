pub const JSString = struct {};
pub const JSNumber = struct {};

pub const JSObject = struct {};

pub const JSArray = struct {
    values: []JSValue,
};

pub const JSValue = union (enum) {
    number: JSNumber,
    string: JSString,
    array: JSArray,
    object: JSObject,
};
