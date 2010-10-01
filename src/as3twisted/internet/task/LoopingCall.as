package as3twisted.internet.task {

import flash.utils.Timer;
import flash.events.TimerEvent;
import flash.errors.IllegalOperationError;
import as3twisted.internet.defer.Deferred;
import as3twisted.internet.defer.maybeDeferred;
import as3twisted.flash.failure.Failure;
import as3twisted.flash.util.arrayToString;

/**
 * Call a function repeatedly.
 *
 * If the function returns a deferred, rescheduling will not take
 * place until the deferred has fired. The result value is ignored.
 *
 */
public class LoopingCall {

    /** The function to call. */
    public var func:Function;
    /** A array of arguments to pass the function. */
    public var args:Array;
    public var running:Boolean = false;
    public var deferred:Deferred = null;
    public var timer:Timer = null;

    public function LoopingCall(func:Function, ...args:Array) {
        this.func = func;
        this.args = args;
    }

    public function toString():String {
        var a:Array = [];
        a.push("LoopingCall");
        a.push("func=" + this.func);
        a.push("args=" + arrayToString(this.args));
        a.push("running=" + this.running);
        a.push("deferred=" + this.deferred);
        a.push("timer=" + this.timer);
        return "[" + a.join(" ") + "]";
    }

    /**
     * Start running function every interval seconds.
     *
     * @param interval The number of seconds between calls.  May be
     * less than one.
     *
     * @return A Deferred whose callback will be invoked with
     * <code>LoopingCall</code> when <code>stop()</code> method is
     * called, or whose errback will be invoked when the function
     * raises an exception or returned a deferred that has its errback
     * invoked.
     */
    public function start(interval:Number):Deferred {
        if (this.running) {
            throw new IllegalOperationError(
                "Tried to start an already running LoopingCall.");
        }
        if (isNaN(interval) || (interval < 0)) {
            throw new TypeError("interval must be >= 0");
        }
        this.running = true;
        this.deferred = new Deferred();
        this.timer = new Timer(interval*1000, 0);
        this.timer.addEventListener(TimerEvent.TIMER, this._timerHandler);
        this.timer.addEventListener(
            TimerEvent.TIMER_COMPLETE, this._cleanupHandlers);
        this.timer.start();
        return this.deferred;
    }

    private function _timerHandler(e:TimerEvent):void {

        function cb(result:*):void {
            if (!running) {
                var d:Deferred = deferred;
                deferred = null;
                d.callback(this);
            }
        }

        function eb(failure:Failure):void {
            running = false;
            timer.stop();
            _cleanupHandlers(null);
            var d:Deferred = deferred;
            deferred = null;
            d.errback(failure);
        }

        var d:Deferred = maybeDeferred.apply(
            null, [func].concat(args));
        d.addCallback(cb);
        d.addErrback(eb);
    }

    private function _cleanupHandlers(e:TimerEvent):void {
        this.timer.removeEventListener(TimerEvent.TIMER, this._timerHandler);
        this.timer.removeEventListener(
            TimerEvent.TIMER_COMPLETE, this._cleanupHandlers);
    }

    /**
     * Stop running function.
     */
    public function stop():void {
        if (!this.running) {
            throw new IllegalOperationError(
                "Tried to stop a LoopingCall that was not running.");
        }
        this.running = false;
        this.timer.stop();
        this._cleanupHandlers(null);
        var d:Deferred = this.deferred;
        this.deferred = null;
        d.callback(this);
    }
}
}
