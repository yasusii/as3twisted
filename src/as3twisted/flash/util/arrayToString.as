package as3twisted.flash.util {

public function arrayToString(array:Array):String {
    if (array == null) return "null";

    var result:Array = [];

    for each (var item:* in array) {
        var s:String;
        if (item is String) {
            s = item;
        } else if (item is Array) {
            s = arrayToString(item);
        } else {
            s = String(item);
        }
        result.push(s);
    }
    return "[" + result.join(", ") + "]";        
}
}