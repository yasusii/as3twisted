package as3twisted.mx.rpc
{
import mx.rpc.IResponder;
import mx.rpc.Fault;
import mx.rpc.events.ResultEvent;
import mx.rpc.events.FaultEvent;

import as3twisted.internet.defer.Deferred;

/**
 * An IResponder implementation for Deferred
 */
public class DeferredResponder implements IResponder {

    public var deferred:Deferred;

    public function DeferredResponder() {
        this.deferred = new Deferred();
    }

    public function toString():String {
        var a:Array = [];
        a.push("DeferredResponder")
        a.push("deferred=" + this.deferred);
        return "[" + a.join(" ") + "]";
    }

    /**
     * Receive ResultEvent and call
     * <code>this.deferred.callback()</code> with the result value.
     */
    public function result(data:Object):void {
        var result:Object;
        if (data is ResultEvent) {
            result = data.result;
        } else {
            result = data;
        }
        this.deferred.callback(result);
    }

    /**
     * Receive FaultEvent and call
     * <code>this.deferred.errback()</code> with the error instance.
     */
    public function fault(info:Object):void {
        var err:Error;
        if (info is FaultEvent) {
            err = info.fault;
        } else {
            err = new Error("Unknown Error: " + info);
        }
        this.deferred.errback(err);
    }
}
}