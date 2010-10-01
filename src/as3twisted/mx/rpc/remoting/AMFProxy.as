package as3twisted.mx.rpc.remoting
{

import flash.utils.Proxy;
import flash.utils.flash_proxy;
import mx.rpc.remoting.RemoteObject;
import mx.rpc.remoting.Operation;
import mx.rpc.AsyncToken;

import as3twisted.internet.defer.Deferred;
import as3twisted.mx.rpc.DeferredResponder;

public dynamic class AMFProxy extends Proxy {

    public var remoteObject:RemoteObject;

    public function AMFProxy(remoteObject:RemoteObject) {
        this.remoteObject = remoteObject;
    }

    public function toString():String {
        var a:Array = [];
        a.push("AMFProxy")
        a.push("remoteObject=" + this.remoteObject);
        return "[" + a.join(" ") + "]";
    }

    override flash_proxy function callProperty(methodName:*, ...args:Array):* {
        return this._callProperty(methodName, args);
    }

    private function _callProperty(methodName:*, args:Array):* {
        var op:Operation = this.remoteObject[methodName];
        var token:AsyncToken = op.send.apply(null, args);
        var responder:DeferredResponder = new DeferredResponder();
        token.addResponder(responder);
        return responder.deferred;
    }

    override flash_proxy function getProperty(name:*):* {
        return function (...args:Array):* {
            return _callProperty.apply(null, [name].concat(args));
        }
    }
}
}