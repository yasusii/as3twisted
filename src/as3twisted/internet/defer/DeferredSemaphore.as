package as3twisted.internet.defer {

import as3twisted.internet.defer.Deferred;
import as3twisted.internet.defer.ConcurrencyPrimitive;
import  flash.errors.IllegalOperationError;

/**
 * A semaphore for event driven systems.
 */

public class DeferredSemaphore extends ConcurrencyPrimitive {

    /**
     * At most this many users may acquire this semaphore at once. */
    public var tokens:int;
    /**
     * The difference between <code>tokens</code> and the number of
     * users which have currently acquired this semaphore. */
    public var limit:int;

    /**
     * Initialize a DeferredSemaphore
     *
     * @param tokens At most this many users may acquire this
     * semaphore at once.
     */
    public function DeferredSemaphore(tokens:int) {
        super();
        if (tokens < 1) {
            throw new TypeError("DeferredSemaphore requires tokens >= 1");
        }
        this.tokens = tokens;
        this.limit = tokens;
    }

    public function toString():String {
        var a:Array = [];
        a.push("DeferredSemaphore");
        a.push("tokens=" + this.tokens);
        a.push("limit=" + this.limit);
        return "[" + a.join(" ") + "]";
    }

    /**
     * Attempt to acquire the token.
     *
     * @return a <code>Deferred</code> which fires on token acquisition.
     *
     * @see #release()
     */
    override public function acquire():Deferred {

        function _cancelAcquire():void {
            var index:int = waiting.indexOf(this);
            if (index >= 0) {
                waiting = [].concat(
                    waiting.slice(0, index), waiting.slice(index+1));
            }
        }

        if (this.tokens < 0) {
            throw new IllegalOperationError(
                "Internal inconsistency??  tokens should never be negative");
        }
        var d:Deferred = new Deferred(_cancelAcquire);
        if (this.tokens == 0) {
            this.waiting.push(d);
        } else {
            this.tokens -= 1;
            d.callback(this);
        }
        return d;
    }
        
    /**
     * Release the token.
     *
     * <p>Should be called by whoever did the <code>acquire()</code>
     * when the shared resource is free.</p>
     *
     * @see #acquire()
     */
    override public function release():void {
        if (this.tokens >= this.limit) {
            throw new IllegalOperationError(
                "Someone released me too many times: too many tokens!");
        }
        this.tokens += 1;
        if (this.waiting.length > 0) {
            // someone is waiting to acquire token
            this.tokens -= 1;
            var d:Deferred = this.waiting.shift();
            d.callback(this);
        }
    }
}
}