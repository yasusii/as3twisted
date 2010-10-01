package as3twisted.internet.defer {

import flash.errors.IllegalOperationError;
import as3twisted.internet.defer.Deferred;
import as3twisted.internet.defer.maybeDeferred;

/**
 * Base class for DeferredLock/DeferredQueue
 *
 * @see DeferredLock
 * @see DeferredQueue
 */
public class ConcurrencyPrimitive {

    public var waiting:Array;

    public function ConcurrencyPrimitive() {
        this.waiting = [];
    }

    public function release():void {
        throw new IllegalOperationError(
            "this method should be overridden by subclasses.");
    }

    public function acquire():Deferred {
        throw new IllegalOperationError(
            "this method should be overridden by subclasses.");
    }

    private function _releaseAndReturn(r:*):* {
        this.release();
        return r;
    }

    /**
     * This method takes a function as its first argument and any
     * number of other positional arguments. When the lock or
     * semaphore is acquired, the function will be invoked with those
     * arguments.
     *
     * @param func The function which will be invoked when the lock
     * or semaphore is acquired.  This may return a
     * <code>Deferred</code>; if it does, the lock or semaphore won't
     * be released until that <code>Deferred</code> fires.
     *
     * @param args The arguments to pass the function.
     *
     * @return <code>Deferred</code> of function result.
     */
    public function run(func:Function, ...args:Array):Deferred {
        if (func == null) {
            throw new TypeError("func must not be null");
        }

        function execute(ignoreResult:*):Deferred {
            var d:Deferred = maybeDeferred.apply(null,
                                                 [func].concat(args));
            d.addBoth(_releaseAndReturn);
            return d;
        }
        var d:Deferred = this.acquire();
        d.addCallback(execute);
        return d;
    }
}
}