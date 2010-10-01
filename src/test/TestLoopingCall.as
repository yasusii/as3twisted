package test 
{

import flash.events.TimerEvent;
import flash.errors.IllegalOperationError;
import org.flexunit.Assert;
import as3twisted.internet.defer.Deferred;
import as3twisted.flash.failure.Failure;
import as3twisted.internet.task.LoopingCall;

public class TestLoopingCall {

    [Before]
    public function setUp():void {
    }

    [After]
    public function tearDown():void {
    }

    [Test]
    public function testBasicFunction():void {
        var L:Array = [];
        var theResult:Array = []

        function foo(a:String, b:String, c:String="C", d:String="D"):void {
            L.push([a, b, c, d]);
        }

        function saveResult(result:LoopingCall):void {
            theResult.push(result);
        }

        var lc:LoopingCall = new LoopingCall(foo, "a", "b", "c");
        var d:Deferred = lc.start(10);
        d.addCallback(saveResult);

        for (var i:int = 0; i < 3; i++) {
            lc.timer.dispatchEvent(new TimerEvent(TimerEvent.TIMER));
        }

        Assert.assertEquals(3, L.length);
        for each(var a:Array in L) {
            Assert.assertEquals(4, a.length);
            Assert.assertEquals("a", a[0]);
            Assert.assertEquals("b", a[1]);
            Assert.assertEquals("c", a[2]);
            Assert.assertEquals("D", a[3]);
        }

        lc.stop()
        Assert.assertEquals(1, theResult.length);
        Assert.assertTrue(theResult[0] === lc);
    }

    [Test]
    public function testToString():void {
        function foo(...args):void {
        }
        var lc:LoopingCall = new LoopingCall(foo, "a", "b", "c");
        Assert.assertEquals("[LoopingCall func=function Function() {} args=[a, b, c] running=false deferred=null timer=null]", lc.toString());
    }

    [Test]
    public function testFunctionRaisesError():void {

        var theResult:Array = [];

        function foo():void {
            throw new TypeError("Bang!");
        }

        function eb(failure:Failure):void {
            theResult.push(failure);
        }


        var lc:LoopingCall = new LoopingCall(foo);
        var d:Deferred = lc.start(10);
        d.addErrback(eb);
        lc.timer.dispatchEvent(new TimerEvent(TimerEvent.TIMER));
        Assert.assertEquals(1, theResult.length);
        Assert.assertEquals("Bang!", theResult[0].value.message);
    }

    [Test]
    public function testMultipleStart():void {

        function foo():void {
            throw new TypeError("This should not be called");
        }
        var lc:LoopingCall = new LoopingCall(foo);
        lc.start(10);
        try {
            lc.start(10);
            throw new Error("No error occured");
        } catch(e:Error) {
            Assert.assertTrue(e is IllegalOperationError);
        }
    }

    [Test]
    public function testMultipleStop():void {

        function foo():void {
            Assert.fail("This should not be called");
        }
        var lc:LoopingCall = new LoopingCall(foo);
        lc.start(10);
        lc.stop();
        try {
            lc.stop();
            Assert.fail("No error occured");
        } catch(e:Error) {
            Assert.assertTrue(e is IllegalOperationError);
        }
    }
}
}