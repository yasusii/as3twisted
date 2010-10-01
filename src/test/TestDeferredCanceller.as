package test 
{
import org.flexunit.Assert;
import as3twisted.internet.defer.Deferred;
import as3twisted.internet.defer.CancelledError;
import as3twisted.internet.defer.AlreadyCalledError;

public class TestDeferredCanceller {

    public var callbackResults:*;
    public var errbackResults:*;
    public var callback2Results:*;
    public var cancellerCallCount:int;

    [Before]
    public function setUp():void {
        this.callbackResults = null;
        this.callback2Results = null;
        this.errbackResults = null;
        this.cancellerCallCount = 0;
    }

    [After]
    public function tearDown():void {
        // Sanity check that the canceller was called at most once.
        Assert.assertTrue(
            (this.cancellerCallCount == 0) || (this.cancellerCallCount == 1));
    }

    private function _callback(data:*):* {
        this.callbackResults = data;
        return data;
    }

    private function _callback2(data:*):void {
        this.callback2Results = data;
    }

    private function _errback(data:*):void {
        this.errbackResults = data;
    }

    /**
     * A Deferred without a canceller must errback with a
     * CancelledError and not callback.
     */
    [Test]
    public function testNoCanceller():void {
        var d:Deferred = new Deferred();
        d.addCallbacks(this._callback, this._errback);
        d.cancel();
        Assert.assertTrue(this.errbackResults.type === CancelledError);
        Assert.assertTrue(this.callbackResults == null);
    }

    /**
     * A Deferred without a canceller, when cancelled must allow a
     * single extra call to callback, and raise AlreadyCalledError if
     * callbacked or errbacked thereafter.
     */
    [Test]
    public function testRaisesAfterCancelAndCallback():void {
        var d:Deferred = new Deferred();
        d.addCallbacks(this._callback, this._errback);
        d.cancel();

        // A single extra callback should be swallowed.
        d.callback(null)

        // But a second call to callback or errback is not.
        try {
            d.callback(null);
            Assert.fail("this should not be called");
        } catch (e:*) {
            Assert.assertTrue(e is AlreadyCalledError);
        }

        try {
            d.errback(new Error());
            Assert.fail("this should not be called");
        } catch (e:*) {
            Assert.assertTrue(e is AlreadyCalledError);
        }
    }

    /**
     * A Deferred without a canceller, when cancelled must allow a
     * single extra call to errback, and raise AlreadyCalledError if
     * callbacked or errbacked thereafter.
     */
    public function TestRaisesAfterCancelAndErrback():void {
        var d:Deferred = new Deferred();
        d.addCallbacks(this._callback, this._errback);
        d.cancel();

        // A single extra errback should be swallowed.
        d.errback(new Error());

        // But a second call to callback or errback is not.
        try {
            d.callback(null);
            Assert.fail("this should not be called");
        } catch (e:*) {
            Assert.assertTrue(e is AlreadyCalledError);
        }

        try {
            d.errback(new Error());
            Assert.fail("this should not be called");
        } catch (e:*) {
            Assert.assertTrue(e is AlreadyCalledError);
        }
    }

    /**
     * A Deferred without a canceller, when cancelled and then
     * callbacked, ignores multiple cancels thereafter.
     */
    [Test]
    public function TestNoCancellerMultipleCancelsAfterCancelAndCallback():void {
        var d:Deferred = new Deferred();
        d.addCallbacks(this._callback, this._errback);
        d.cancel();
        var currentFailure:* = this.errbackResults;
        // One callback will be ignored
        d.callback(null);
        // Cancel should have no effect.
        d.cancel();
        Assert.assertTrue(currentFailure === this.errbackResults);
    }

    /**
     * A Deferred without a canceller, when cancelled and then
     * errbacked, ignores multiple cancels thereafter.
     */
    public function TestNoCancellerMultipleCancelsAfterCancelAndErrback():void {
        var d:Deferred = new Deferred();
        d.addCallbacks(this._callback, this._errback);
        d.cancel();
        Assert.assertTrue(this.errbackResults.type === CancelledError);
        var currentFailure:* = this.errbackResults;
        // One errback will be ignored
        d.errback(new Error());
        // I.e., we should still have a CancelledError.
        Assert.assertTrue(this.errbackResults.type === CancelledError);
        d.cancel();
        Assert.assertTrue(currentFailure === this.errbackResults);
    }

    /**
     * Calling cancel multiple times on a deferred with no canceller
     * results in a CancelledError. Subsequent calls to cancel do not
     * cause an error.
     */
    [Test]
    public function TestNoCancellerMultipleCancel():void {
        var d:Deferred = new Deferred();
        d.addCallbacks(this._callback, this._errback);
        d.cancel();
        Assert.assertTrue(this.errbackResults.type === CancelledError);
        var currentFailure:* = this.errbackResults;
        d.cancel();
        Assert.assertTrue(currentFailure === this.errbackResults);
    }

    /**
     * Verify that calling cancel multiple times on a deferred with a
     * canceller that does not errback results in a
     * CancelledError and that subsequent calls to cancel do not
     * cause an error and that after all that, the canceller was only
     * called once.
     */
    [Test]
    public function TestCancellerMultipleCancel():void {

        function cancel():void {
            cancellerCallCount += 1;
        }
        var d:Deferred = new Deferred(cancel);
        d.addCallbacks(this._callback, this._errback);
        d.cancel();
        Assert.assertTrue(this.errbackResults.type === CancelledError);
        var currentFailure:* = this.errbackResults;
        d.cancel();
        Assert.assertTrue(currentFailure === this.errbackResults);
        Assert.assertEquals(1, this.cancellerCallCount);
    }

    /**
     * Verify that a Deferred calls its specified canceller when it is
     * cancelled, and that further call/errbacks raise
     * AlreadyCalledError.
     */
    [Test]
    public function TestSimpleCanceller():void {

        function cancel():void {
            cancellerCallCount += 1;
        }

        var d:Deferred = new Deferred(cancel);
        d.addCallbacks(this._callback, this._errback);
        d.cancel();
        Assert.assertEquals(1, this.cancellerCallCount);
        Assert.assertTrue(this.errbackResults.type === CancelledError);

        // Test that further call/errbacks are *not* swallowed
        try {
            d.callback(null);
            Assert.fail("this should not be called");
        } catch (e:*) {
            Assert.assertTrue(e is AlreadyCalledError);
        }

        try {
            d.errback(new Error());
            Assert.fail("this should not be called");
        } catch (e:*) {
            Assert.assertTrue(e is AlreadyCalledError);
        }
    }

    /**
     * Verify that a canceller is given the correct deferred argument.
     */
    [Test]
    public function TestCancellerArg():void {

        function cancel():void  {
            Assert.assertTrue(this === d);
        }

        var d:Deferred = new Deferred(cancel);
        d.addCallbacks(this._callback, this._errback);
        d.cancel();
    }

    /**
     * Test that cancelling a deferred after it has been callbacked does
     * not cause an error.
     */
    [Test]
    public function TestCancelAfterCallback():void {

        function cancel():void {
            cancellerCallCount += 1;
            this.errback(new Error());
        }

        var d:Deferred = new Deferred(cancel);
        d.addCallbacks(this._callback, this._errback);
        d.callback("biff!");
        d.cancel();
        Assert.assertEquals(0, this.cancellerCallCount);
        Assert.assertEquals(null, this.errbackResults);
        Assert.assertEquals("biff!", this.callbackResults);
    }

    /**
     * Test that cancelling a Deferred after it has been errbacked does
     * not result in a CancelledError.
     */
    [Test]
    public function TestCancelAfterErrback():void {
        
        function cancel():void {
            cancellerCallCount += 1;
            this.errback(new Error());
        }

        var d:Deferred = new Deferred(cancel);
        d.addCallbacks(this._callback, this._errback);
        d.errback(new TypeError());
        d.cancel();
        Assert.assertEquals(0, this.cancellerCallCount);
        Assert.assertTrue(this.errbackResults.type === TypeError);
        Assert.assertEquals(null, this.callbackResults);
    }

    /**
     * Test a canceller which errbacks its deferred.
     */
    [Test]
    public function TestCancellerThatErrbacks():void {

        function cancel():void {
            cancellerCallCount += 1;
            this.errback(new TypeError());
        }

        var d:Deferred = new Deferred(cancel);
        d.addCallbacks(this._callback, this._errback);
        d.cancel();
        Assert.assertEquals(1, this.cancellerCallCount);
        Assert.assertTrue(this.errbackResults.type === TypeError);
    }

    /**
     * Test a canceller which calls its deferred.
     */
    [Test]
    public function TestCancellerThatCallbacks():void {

        function cancel():void {
            cancellerCallCount += 1;
            this.callback("hello!");
        }

        var d:Deferred = new Deferred(cancel);
        d.addCallbacks(this._callback, this._errback);
        d.cancel();
        Assert.assertEquals(1, this.cancellerCallCount);
        Assert.assertEquals("hello!", this.callbackResults);
        Assert.assertEquals(null, this.errbackResults);
    }

    /**
     * Verify that a Deferred, a, which is waiting on another
     * Deferred, b, returned from one of its callbacks, will propagate
     * CancelledError when a is cancelled.
     */
    [Test]
    public function TestCancelNestedDeferred():void {

        function innerCancel():void {
            cancellerCallCount += 1;
        }

        function cancel():void {
            Assert.fail();
        }

        var b:Deferred = new Deferred(innerCancel);
        var a:Deferred = new Deferred(cancel);
        a.callback(null);
        a.addCallback(function (ignore:*):Deferred {return b});
        a.cancel();
        a.addCallbacks(this._callback, this._errback);
        // The cancel count should be one (the cancellation done by B)
        Assert.assertEquals(1, this.cancellerCallCount);
        // B's canceller didn't errback, so defer.py will have called errback
        // with a CancelledError.
        Assert.assertTrue(this.errbackResults.type === CancelledError);
    }
}
}
