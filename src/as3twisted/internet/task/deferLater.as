package as3twisted.internet.task {

import flash.utils.Timer;
import flash.events.TimerEvent;

import as3twisted.internet.defer.Deferred;
import as3twisted.internet.defer.maybeDeferred;
import as3twisted.flash.failure.Failure;

/**
 * Call the given function after a certain period of time has passed.
 *
 * @param delay The number of seconds to wait before calling the function.
 *
 * @param closure The function to call after the delay.
 *
 * @param args The arguments to pass the function.
 *
 * @return A deferred that fires with the result of the callable when the
 * specified time has elapsed.
 */
public function deferLater(delay:Number, closure:Function, ...args:Array):Deferred {

    function handler(e:TimerEvent):void {

        function cb(result:*):void {
            deferred.callback(result);
        }

        function eb(failure:Failure):void {
            deferred.errback(failure);
        }

        var d:Deferred = maybeDeferred.apply(null, [closure].concat(args));
        d.addCallback(cb);
        d.addErrback(eb);
        timer.removeEventListener(TimerEvent.TIMER, handler);
    }

    function canceller():void {
        if (timer.running) {
            timer.stop();
            timer.removeEventListener(TimerEvent.TIMER, handler);
        }
    }

    var deferred:Deferred = new Deferred(canceller);
    var timer:Timer = new Timer(delay*1000, 1);
    timer.addEventListener(TimerEvent.TIMER, handler);
    timer.start();
    return deferred;
}
}
