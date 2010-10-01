package test 
{

import mx.rpc.remoting.RemoteObject;
import org.flexunit.Assert;

import as3twisted.internet.defer.Deferred;
import as3twisted.flash.failure.Failure;
import as3twisted.mx.rpc.remoting.AMFProxy;

public class TestAMFProxy {

    public var ro:RemoteObject;
    private var _done:Boolean;

    private function errorFail(failure:Failure):void {
        if (failure is Failure) {
            failure.throwError();
        } else {
            throw failure;
        }
    }

    [Before]
    public function setUp():void {
        this._done = false;
        this.ro = new RemoteObject("Service1");
        this.ro.endpoint = "/amf";
    }

    [Test]
    public function testToString():void {
        var proxy:AMFProxy = new AMFProxy(this.ro);
        Assert.assertEquals('[AMFProxy remoteObject=[RemoteObject  destination="Service1" channelSet="null"]]', proxy.toString());
    }

    [Test]
    public function testAMFProxyWithoutArgs():void {
        var proxy:AMFProxy = new AMFProxy(this.ro);
        var d:Deferred = proxy.hello();

        function _cb(result:*):void {
            Assert.assertTrue(result is String);
            Assert.assertEquals("Hello!", result);
        }
        d.addCallback(_cb);
        d.addErrback(errorFail);
    }

    [Test]
    public function testAMFProxyWithArgs():void {
        var proxy:AMFProxy = new AMFProxy(this.ro);
        var d:Deferred = proxy.add(3, 5);

        function _cb(result:*):void {
            Assert.assertTrue(result is Number);
            Assert.assertEquals(8, result);
        }
        d.addCallback(_cb);
        d.addErrback(errorFail);
    }

    [Test]
    public function testAMFProxyWithTooManyArgs():void {
        var proxy:AMFProxy = new AMFProxy(this.ro);
        var d:Deferred = proxy.add(3, 5, 8, 9);

        function _cb(result:*):void {
            Assert.fail("this should not be called");
        }

        d.addCallback(_cb);
        d.addErrback(errorFail);
    }
}
}
