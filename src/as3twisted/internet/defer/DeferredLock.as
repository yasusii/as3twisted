package as3twisted.internet.defer {

import flash.errors.IllegalOperationError;
import as3twisted.internet.defer.Deferred;
import as3twisted.internet.defer.ConcurrencyPrimitive;
import as3twisted.flash.util.arrayToString;

/**
 * A lock for event driven systems.
 */

public class DeferredLock extends ConcurrencyPrimitive {

    /**
     * <code>true</code> when this Lock has been acquired,
     * <code>false</code> at all other times.  Do not change this
     * value, but it is useful to examine for the equivalent of a
     * "non-blocking" acquisition.
     @default false
     */
    public var locked:Boolean = false;

    public function DeferredLock() {
        super();
    }

    public function toString():String {
        var a:Array = [];
        a.push("DeferredLock");
        a.push("locked=" + this.locked);
        a.push("waiting=" + arrayToString(this.waiting));
        return "[" + a.join(" ") + "]";
    }

    /**
     * Attempt to acquire the lock.  Returns a <code>Deferred</code>
     * that fires on lock acquisition with the
     * <code>DeferredLock</code> as the value.  If the lock is locked,
     * then the Deferred is placed at the end of a waiting list.
     *
     * @return a <code>Deferred</code> which fires on lock acquisition.
     */
    override public function acquire():Deferred {

        function _cancelAcquire():void {
            var index:int = waiting.indexOf(this);
            if (index >= 0) {
                waiting = [].concat(
                    waiting.slice(0, index), waiting.slice(index+1));
            }
        }

        var d:Deferred = new Deferred(_cancelAcquire);
        if (this.locked) {
            this.waiting.push(d);
        } else {
            this.locked = true;
            d.callback(this);
        }
        return d;
    }

    /**
     * Release the lock.  If there is a waiting list, then the first
     * <code>Deferred</code> in that waiting list will be called back.
     *
     * <p>Should be called by whomever did the <code>acquire()</code>
     * when the shared resource is free.</p>
     */
    override public function release():void {
        if (!this.locked) {
            throw new IllegalOperationError(
                "Tried to release an unlocked lock");
        }
        this.locked = false;
        if (this.waiting.length > 0) {
            // someone is waiting to acquire lock
            this.locked = true;
            var d:Deferred = this.waiting.shift();
            d.callback(this);
        }
    }
}
}