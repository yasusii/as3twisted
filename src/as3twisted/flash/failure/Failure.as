package as3twisted.flash.failure
{
import flash.utils.getQualifiedClassName;
import as3twisted.flash.Reflect;

/**
 * A basic abstraction for an error that has occurred.
 * 
 * <p>This is necessary because Flash's built-in error mechanisms are
 * inconvenient for asynchronous communication.</p>
 */
public class Failure {

    /** @default "Failure" */
    public var name:String = "Failure";
    /** The exception instance responsible for this failure. */
    public var value:*;
    /** The exception's class. */
    public var type:Class;
    /** An array of the parent classes of the exception's class. */
    public var parents:Array;
    private var _errorID:int = 0;
    private var _message:String = "";

    /**
     * Initialize a Failure
     *
     * @param exc_value The exception instance responsible for this
     * failure.
     */
    public function Failure(exc_value:*) {
        if (exc_value == null) {
            throw ArgumentError("argument should be not null");
        }

        if (exc_value is Failure) {
            for (var key:* in exc_value) {
                this[key] = exc_value[key];
            }
            return;
        }

	    this.value = exc_value;
        this.type = Reflect.getClass(this.value);
        if (this.value is Error) {
            var parentCs:Array = Reflect.allYourBase(this.type);

            function _getClassName(cls:Class, index:int, array:Array):String {
                return getQualifiedClassName(cls);
            }
            this.parents = parentCs.map(_getClassName);
            this.parents.push(getQualifiedClassName(this.type));
        } else {
            this.parents = [getQualifiedClassName(this.type)];
        }
    }

    public function get message():String {
        var msg:String;
        try {
            if (this.value.message == undefined) {
                msg = this._message;
            } else {
                msg = this.value.message;
            }
        } catch (e:ReferenceError) {
            msg = this._message;
        }
        return msg;
    }

    public function set message(message:String):void {
        try {
            if (this.value.message == undefined) {
                this._message = message;
            } else {
                this.value.message = message;
            }
        } catch (e:ReferenceError) {
            this._message = message;
        }
    }

    public function get errorID():int {
        var id:int;
        try {
            if (this.value.errorID == undefined) {
                id = this._errorID;
            } else {
                id = this.value.errorID;
            }
        } catch (e:ReferenceError) {
            id = this._errorID;
        }
        return id;
    }

    public function set errorID(id:int):void {
        try {
            if (this.value.errorID == undefined) {
                this._errorID = id;
            } else {
                this.value.errorID = id;
            }
        } catch (e:ReferenceError) {
            this._errorID = id;
        }
    }

    /** Get the original exception's traceback */
    public function getStackTrace():String {
        var st:String;
        try {
            if (this.value.errorID == undefined) {
                st = null;
            } else {
                st = this.value.getStackTrace();
            }
        } catch (e:TypeError) {
            st = null;
        }
        return st;
    }

    public function toString():String {
        if (this.message) {
            return this.name + ": " + this.message;
        } else {
            return this.name;
        }
    }

    /**
     * Trap this failure if its type is in a predetermined list.
     *
     * <p>This allows you to trap a Failure in an error callback.  It will be
     * automatically re-raised if it is not a type that you expect.</p>
     *
     * <p>The reason for having this particular API is because it's very useful
     * in Deferred errback chains::</p>
     * <listing>
     * function _ebFoo(failure:Failure):void {
     *     var r:Class = failure.trap(Spam, Eggs);
     *     trace("The Failure is due to either Spam or Eggs!");
     *     if (r === Spam) {
     *         trace("Spam did it!");
     *     } else if (r === Eggs) {
     *         trace("Eggs did it!");
     *     }
     * }
     * </listing>
     * <p>If the failure is not a Spam or an Eggs, then the Failure
     * will be 'passed on' to the next errback.</p>
     */
    public function trap(...errorTypes:Array):Class {
        var error:Class = this.check.apply(this, errorTypes);
        if (error == null) throw this;
        return error;
    }

    /**
     * Check if this failure's type is in a predetermined list.
     * 
     * @param errorTypes Array of exception classes
     *
     * @return A class of the matching exception type, or null if no
     * match.
     */
    public function check(...errorTypes:Array):Class {
        for each (var error:* in errorTypes) {
            if (Reflect.isClass(error) && Reflect.isSubClass(error, Error)) {
                var name:String = getQualifiedClassName(error);
                if (this.parents.indexOf(name) >= 0) return error;
            } else {
                throw TypeError("arguments should be Error classes");
            }
        }
        return null;
    }

    /** Throw the original exception, preserving traceback */
    public function throwError():void {
        throw this.value;
    }

    /** Get a string of the exception which caused this Failure. */
    public function getErrorMessage():String {
        return this.value.message;
    }
}
}