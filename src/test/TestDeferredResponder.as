package test 
{

import as3twisted.internet.defer.Deferred;
import as3twisted.mx.rpc.DeferredResponder;
import org.flexunit.Assert;

public class TestDeferredResponder {

    [Before]
    public function setUp():void {
    }

    [Test]
    public function testToString():void {
        var responder:DeferredResponder = new DeferredResponder();
        Assert.assertEquals("[DeferredResponder deferred=[Deferred called=false paused=0 result=undefined chainedTo=null callbacks=[]]]", responder.toString());
    }
}
}
