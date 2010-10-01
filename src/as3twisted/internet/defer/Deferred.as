package as3twisted.internet.defer
{
import as3twisted.internet.defer.AlreadyCalledError;
import as3twisted.flash.failure.Failure;
import as3twisted.flash.util.arrayToString;
/**
 * This is a callback which will be put off until later.
 *
 * <p>Why do we want this? Well, in cases where a function in a
 * network client program would block until it gets a result, for
 * Twisted it should not block. Instead, it should return a
 * <code>Deferred</code>.</p>
 *
 * <p>This can be implemented for protocols that run over the network
 * by writing an asynchronous protocol for
 * <code>as3twisted.internet</code>.</p>
 *
 * <p>For more information about Deferreds, see 
 * http://twistedmatrix.com/projects/core/documentation/howto/defer.html</p>
 *
 * <p>When creating a Deferred, you may provide a canceller function,
 * which will be called by <code>d.cancel()</code> to let you do any
 * clean-up necessary if the user decides not to wait for the deferred
 * to complete.</p>
 */
public class Deferred {

    /** @default faluse */
    public var called:Boolean = false;
    /** @dafault 0 */
    public var paused:int = 0;
    public var result:*; // can be undefined
    /** @default null */
    public var chainedTo:Deferred = null;
    public var callbacks:Array;

    private var _runningCallbacks:Boolean = false;
    private var _suppressAlreadyCalled:Boolean = false;
    private var _canceller:Function;

    public function Deferred(canceller:Function=null) {
        this.callbacks = new Array();
        this._canceller = canceller;
    }

    public function toString():String {
        var a:Array = [];
        a.push("Deferred")
        a.push("called=" + this.called);
        a.push("paused=" + this.paused);
        if (this.result is Array) {
            a.push("result=" + arrayToString(this.result));
        } else {
            a.push("result=" + this.result);
        }
        a.push("chainedTo=" + this.chainedTo);
        a.push("callbacks=" + arrayToString(this.callbacks));
        return "[" + a.join(" ") + "]";
    }

    private function passthru(arg:*):* {
        return arg;
    }

    /**
     * Add a pair of callbacks (success and error) to this
     * <code>Deferred</code>.
     *
     * <p>These will be executed when the 'master' callback is run.</p>
     */
    public function addCallbacks(callback:Function, errback:Function=null, callbackArgs:Array=null, errbackArgs:Array=null):Deferred {
        if (callback == null) {
            throw new TypeError("callback must not be null");
        }
	    if (errback == null) errback = passthru;
        if (callbackArgs == null) callbackArgs = [];
        if (errbackArgs == null) errbackArgs = [];
        this.callbacks.push([[callback, callbackArgs], [errback, errbackArgs]]);
        if (this.called) {
            this._runCallbacks();
        }
        return this;
    }
        
    /**
     * Convenience method for adding just a callback.
     *
     * @see #addCallbacks()
     */
    public function addCallback(callback:Function, ...args:Array):Deferred {
        return this.addCallbacks(callback, null, args);
    }

    /**
     * Convenience method for adding just an errback.
     *
     * @see #addCallbacks()
     */
    public function addErrback(errback:Function, ...args:Array):Deferred {
        return this.addCallbacks(passthru, errback, null, args);
    }

    /**
     * Convenience method for adding a single callable as both a callback
     * and an errback.
     *
     * @see #addCallbacks()
     */
    public function addBoth(callback:Function, ...args:Array):Deferred {
        return this.addCallbacks(callback, callback, args, args);
    }

    /**
     * Chain another <code>Deferred</code> to this
     * <code>Deferred</code>.
     *
     * This method adds callbacks to this <code>Deferred</code> to
     * call <code>d</code>'s callback or errback, as appropriate. It
     * is merely a shorthand way of performing the following::
     *
     * <listing>this.addCallbacks(d.callback, d.errback)</listing>
     *
     * <p>When you chain a deferred <code>d2</code> to another
     * deferred <code>d1</code> with
     * <code>d1.chainDeferred(d2)</code>, you are making
     * <code>d2</code> participate in the callback chain of
     * <code>d1</code>. Thus any event that fires d1 will also fire
     * <code>d2</code>.  However, the converse is not
     * <code>true</code>; if <code>d2</code> is fired <code>d1</code>
     * will not be affected.</p>
     */
    public function chainDeferred(d:Deferred):Deferred {
        d.chainedTo = this;
        return this.addCallbacks(d.callback, d.errback);
    }

    /**
     * Run all success callbacks that have been added to this
     * <code>Deferred</code>.
     *
     * <p>Each callback will have its result passed as the first
     * argument to the next; this way, the callbacks act as a
     * 'processing chain'.  If the success-callback returns a
     * <code>Failure</code> or throws an <code>Error</code>,
     * processing will continue on the *error* callback chain.  If a
     * callback (or errback) returns another <code>Deferred</code>,
     * this <code>Deferred</code> will be chained to it (and further
     * callbacks will not run until that <code>Deferred</code> has a
     * result).</p>
     *
     * @see as3twisted.flash.failure.Failure
     */
    public function callback(result:*):void {
        this._startRunCallbacks(result);
    }

    /**
     * Run all error callbacks that have been added to this
     * <code>Deferred</code>.
     *
     * <p>Each callback will have its result passed as the first
     * argument to the next; this way, the callbacks act as a
     * 'processing chain'. Also, if the error-callback returns a
     * non-Failure or doesn't throw an <code>Error</code>, processing
     * will continue on the *success*-callback chain.</p>
     *
     * <p>If the argument that's passed to me is not a
     * <code>Failure</code> instance, it will be embedded in one. If
     * no argument is passed, a <code>Failure</code> instance will be
     * created based on the current traceback stack.</p>
     *
     * @see as3twisted.flash.failure.Failure
     */
    public function errback(fail:*):void {
        if (fail is Failure) {
            this._startRunCallbacks(fail);
        } else {
            this._startRunCallbacks(new Failure(fail));
        }
    }

    /**
     * Stop processing on a <code>Deferred</code> until
     * <code>unpause()</code> is called.
     *
     * @see #unpause()
     */
    public function pause():void {
        this.paused += 1;
    }

    /**
     * Process all callbacks made since <code>pause()</code> was
     * called.
     *
     * @see #pause()
     */
    public function unpause():void {
        this.paused -= 1;
        if (this.paused) return;
        if (this.called) this._runCallbacks();
    }

    /**
     * Cancel this <code>Deferred</code>.
     *
     * <p>If the <code>Deferred</code> has not yet had its
     * <code>errback</code> or <code>callback</code> method invoked,
     * call the canceller function provided to the constructor. If
     * that function does not invoke <code>callback</code> or
     * <code>errback</code>, or if no canceller function was provided,
     * errback with <code>CancelledError</code>.</p>
     *
     * <p>If this <code>Deferred</code> is waiting on another
     * <code>Deferred</code>, forward the cancellation to the other
     * <code>Deferred</code>.</p>
     *
     * @see CancelledError
     */
    public function cancel():void {
        if (!this.called) {
            var canceller:Function = this._canceller;
            if (canceller != null) {
                canceller.apply(this);
            } else {
                // Arrange to eat the callback that will eventually be fired
                // since there was no real canceller.
                this._suppressAlreadyCalled = true;
            }
            if (!this.called) {
                // There was no canceller, or the canceller didn't call
                // callback or errback.
                this.errback(new Failure(new CancelledError()));
            }
        } else if (this.result is Deferred) {
            this.result.cancel();
        }
    }

    private function _startRunCallbacks(result:*):void {
        if (this.called) {
            if (this._suppressAlreadyCalled) {
                this._suppressAlreadyCalled = false;
                return;
            }
            throw new AlreadyCalledError();
        }
        this.called = true;
        this.result = result;
        this._runCallbacks();
    }

    private function _runCallbacks():void {
        // Don't recursively run callbacks
        if (this._runningCallbacks) return;       
        this.chainedTo = null;
        if (!this.paused) {
            while (this.callbacks.length) {
                var item:Array = this.callbacks.shift();
                item = item[int(this.result is Failure)];
                var callback:Function = item[0];
                var args:Array = item[1];
                try {
                    this._runningCallbacks = true;
                    try {
                        args = [this.result].concat(args)
                        this.result = callback.apply(null, args);
                    } finally {
                        this._runningCallbacks = false;
                    }
                    if (this.result is Deferred) {
                        this.pause();
                        this.chainedTo = this.result;
                        this.result.addBoth(this._continue);
                        break;
                    }
                } catch (error:*) {
                    this.result = new Failure(error);
                }
            }
        }
    }

    private function _continue(result:*):void {
        this.result = result;
        this.unpause();
    }
}
}