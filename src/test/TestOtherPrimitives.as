package test 
{

import flash.errors.IllegalOperationError;
import org.flexunit.Assert;
import as3twisted.internet.defer.Deferred;
import as3twisted.internet.defer.DeferredLock;
import as3twisted.internet.defer.DeferredSemaphore;
import as3twisted.internet.defer.DeferredQueue;
import as3twisted.internet.defer.CancelledError;
import as3twisted.internet.defer.QueueOverflow;
import as3twisted.internet.defer.QueueUnderflow;

public class TestOtherPrimitives {

    public var counter:int;

    [Before]
    public function setUp():void {
        this.counter = 0;
    }

    private function _incr(result:*):void {
        this.counter += 1;
    }

    [Test]
    public function testLock():void {
        var lock:DeferredLock = new DeferredLock();
        var d:Deferred;
        d = lock.acquire();
        d.addCallback(_incr);
        Assert.assertEquals(1, this.counter);

        d = lock.acquire();
        d.addCallback(_incr);
        Assert.assertEquals(true, lock.locked);
        Assert.assertEquals(1, this.counter);

        lock.release();
        Assert.assertEquals(true, lock.locked);
        Assert.assertEquals(2, this.counter);

        lock.release();
        Assert.assertEquals(false, lock.locked);
        Assert.assertEquals(2, this.counter);

        try {
            lock.run(null);
            Assert.fail("this should not be called");
        } catch (e:*) {
            Assert.assertTrue(e is TypeError);
        }

        var firstUnique:Object = new Object();
        var secondUnique:Object = new Object();

        var controlDeferred:Deferred = new Deferred();
        var result:Object;

        function helper(b:*):Deferred {
            result = b;
            return controlDeferred;
        }
        
        var resultDeferred:Deferred = lock.run(helper, firstUnique);
        Assert.assertEquals(true, lock.locked);
        Assert.assertTrue(result === firstUnique);

        resultDeferred.addCallback(function (x:*):void {result = x});

        d = lock.acquire();
        d.addCallback(_incr);
        Assert.assertEquals(true, lock.locked);
        Assert.assertEquals(2, this.counter);

        controlDeferred.callback(secondUnique);
        Assert.assertTrue(result === secondUnique);
        Assert.assertEquals(true, lock.locked);
        Assert.assertEquals(3, this.counter);

        d = lock.acquire();
        d.addBoth(function (x:*):void {result = x});
        d.cancel();
        Assert.assertTrue(result.type === CancelledError);

        lock.release();
        Assert.assertEquals(false, lock.locked);
    }

    [Test]
    public function TestDeferredLockToString():void {
        var lock:DeferredLock = new DeferredLock();
        lock.acquire();
        Assert.assertEquals("[DeferredLock locked=true waiting=[]]",
                            lock.toString());
    }

    /**
     * When canceling a Deferred from a DeferredLock that does not yet
     * have the lock (i.e., the Deferred has not fired), the cancel
     * should cause a CancelledError failure.
     */

    [Test]
    public function TestCancelLockBeforeAcquired():void {
        var lock:DeferredLock = new DeferredLock();
        lock.acquire();
        var d:Deferred = lock.acquire();

        function _eb(e:*):void {
            Assert.assertTrue(e.value is CancelledError);
        }

        d.addErrback(_eb);
        d.cancel();
    }

    [Test]
    public function TestSemaphore():void {
        var N:int = 13;
        var sem:DeferredSemaphore = new DeferredSemaphore(N);

        var controlDeferred:Deferred = new Deferred();
        var memo:*;

        function helper(arg:*):Deferred {
            memo = arg;
            return controlDeferred;
        }

        var results:Array = [];
        var uniqueObject:Object = new Object();
        var resultDeferred:Deferred = sem.run(helper, uniqueObject);
        resultDeferred.addCallback(function (r:*):void {results.push(r)});
        resultDeferred.addCallback(_incr);
        Assert.assertEquals(0, results.length);
        Assert.assertTrue(memo === uniqueObject);
        controlDeferred.callback(null);
        var item:* = results.shift();
        Assert.assertTrue(item == null);
        Assert.assertEquals(1, this.counter);

        this.counter = 0;
        var d:Deferred;
        var i:int;
        for (i = 1; i <= N; i++) {
            d = sem.acquire();
            d.addCallback(_incr);
            Assert.assertEquals(i, this.counter);
        }

        var success:Array = [];

        function fail(r:*):void {
            success.push(false)
        }

        function succeed(r:*):void {
            success.push(true);
        }

        d = sem.acquire();
        d.addCallbacks(fail, succeed);
        d.cancel();
        Assert.assertEquals(1, success.length);
        Assert.assertTrue(success[0]);

        d = sem.acquire();
        d.addCallback(_incr);
        Assert.assertEquals(N, this.counter);

        sem.release();
        Assert.assertEquals(N + 1, this.counter);

        for (i = 1; i <= N; i++) {
            sem.release();
            Assert.assertEquals(N + 1, this.counter);
        }
    }

    [Test]
    public function TestSemaphoreToString():void {
        var sem:DeferredSemaphore = new DeferredSemaphore(5);
        Assert.assertEquals("[DeferredSemaphore tokens=5 limit=5]",
                            sem.toString());
    }

    /**
     * If the token count passed to DeferredSemaphore is less than one
     * then TypeError is thrown.
     */
    [Test]
    public function TestSemaphoreInvalidTokens():void {
        try {
            new DeferredSemaphore(0);
            Assert.fail("this should not be called");
        } catch (e:*) {
            Assert.assertTrue(e is TypeError);
        }

        try {
            new DeferredSemaphore(-1);
            Assert.fail("this should not be called");
        } catch (e:*) {
            Assert.assertTrue(e is TypeError);
        }
    }

    /**
     * When canceling a Deferred from a DeferredSemaphore that
     * already has the semaphore, the cancel should have no effect.
     */
    [Test]
    public function TestCancelSemaphoreAfterAcquired():void {

        function _failOnErrback(_:*):void {
            Assert.fail("Unexpected errback call!");
        }

        var sem:DeferredSemaphore = new DeferredSemaphore(1);
        var d:Deferred = sem.acquire();
        d.addErrback(_failOnErrback);
        d.cancel();
    }

    /**
     * When canceling a Deferred from a DeferredSemaphore that does
     * not yet have the semaphore (i.e., the Deferred has not fired),
     * the cancel should cause a CancelledError failure.
     */
    [Test]
    public function TestCancelSemaphoreBeforeAcquired():void {
        var sem:DeferredSemaphore = new DeferredSemaphore(1);
        sem.acquire();
        var d:Deferred = sem.acquire();

        function _eb(e:*):void {
            Assert.assertTrue(e.type === CancelledError);
        }
        d.addErrback(_eb);
        d.cancel();
    }

    private function _range(...args):Array {
        if (args.length == 0) {
            throw new TypeError("_range expected at least 1 augument");
        } else if (args.length == 1) {
            return this._range1(args[0]);
        } else if (args.length == 2) {
            return this._range2(args[0], args[1]);
        } else {
            throw new TypeError("too many  auguments");
        }
    }

    private function _range1(stop:int):Array {
        var array:Array = [];
        for (var i:int = 0; i < stop; i++) {
            array.push(i);
        }
        return array;
    }

    private function _range2(start:int, stop:int):Array {
        var array:Array = [];
        for (var i:int = 0; i < stop; i++) {
            if (i >= start) array.push(i);
        }
        return array;
    }        

    [Test]
    public function TestQueue():void {
        var N:int = 2;
        var M:int = 2;

        var queue:DeferredQueue = new DeferredQueue(N, M);

        var gotten:Array = [];

        var i:int;
        var d:Deferred;
        var a:Array;

        for (i = 0; i < M; i++) {
            d = queue.get();
            d.addCallback(function (r:*):void {gotten.push(r)});
        }

        try {
            queue.get();
            Assert.fail("this should not be called");
        } catch (e:*) {
            Assert.assertTrue(e is QueueUnderflow);
        }

        for (i = 0; i < M; i++) {
            queue.put(i);
            a = this._range(i + 1);
            Assert.assertEquals(a.length, gotten.length);
            Assert.assertEquals(a.join(), gotten.join());
        }

        for (i = 0; i < N; i++) {
            queue.put(N + i);
            a = this._range(M);
            Assert.assertEquals(a.length, gotten.length);
            Assert.assertEquals(a.join(), gotten.join());
        }

        try {
            queue.put(null);
            Assert.fail("this should not be called");
        } catch (e:*) {
            Assert.assertTrue(e is QueueOverflow);
        }

        gotten = [];
        for (i = 0; i < N; i++) {
            d = queue.get();
            d.addCallback(function (r:*):void {gotten.push(r)});
            a = this._range(N, N + i + 1);
            Assert.assertEquals(a.length, gotten.length);
            Assert.assertEquals(a.join(), gotten.join());
        }

        queue = new DeferredQueue();
        gotten = [];
        for (i = 0; i < N; i++) {
            d = queue.get();
            d.addCallback(function (r:*):void {gotten.push(r)});
        }
        for (i = 0; i < N; i++) {
            queue.put(i);
        }
        a = this._range(N);
        Assert.assertEquals(a.length, gotten.length);
        Assert.assertEquals(a.join(), gotten.join());

        queue = new DeferredQueue(0);
        try {
            queue.put(null);
            Assert.fail("this should not be called");
        } catch (e:*) {
            Assert.assertTrue(e is QueueOverflow);
        }

        queue = new DeferredQueue(-1, 0);
        try {
            queue.get();
            Assert.fail("this should not be called");
        } catch (e:*) {
            Assert.assertTrue(e is QueueUnderflow);
        }

    }
    /**
     * When canceling a Deferred from a DeferredQueue that already has
     * a result, the cancel should have no effect.
     */
    [Test]
    public function TestCancelQueueAfterSynchronousGet():void {

        function _failOnErrback(_:*):void {
            Assert.fail("Unexpected errback call!");
        }

        var queue:DeferredQueue = new DeferredQueue();
        var d:Deferred = queue.get();
        d.addErrback(_failOnErrback);
        queue.put(null);
        d.cancel();
    }

    /**
     * When canceling a Deferred from a DeferredQueue that does not
     * have a result (i.e., the Deferred has not fired), the cancel
     * causes a CancelledError failure. If the queue has a result
     * later on, it doesn't try to fire the deferred.
     */
    [Test]
    public function TestCancelQueueAfterGet():void {
        var queue:DeferredQueue = new DeferredQueue();
        var d:Deferred = queue.get();

        function _eb(e:*):void {
            Assert.assertTrue(e.type === CancelledError);
        }
        d.addErrback(_eb);
        d.cancel();
        
        function _cb(ignore:*):void {
            // If the deferred is still linked with the deferred queue, it will
            // fail with an AlreadyCalledError
            function _assert(r:*):void {
                Assert.assertEquals(null, r);
            }

            queue.put(null);
            var defer:Deferred = queue.get();
            defer.addCallback(_assert);
        }
        d.addCallback(_cb);    
    }
}
}
