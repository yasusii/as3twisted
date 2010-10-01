package test 
{
import org.flexunit.Assert;
import as3twisted.internet.defer.Deferred;
import as3twisted.internet.defer.succeed;
import as3twisted.internet.defer.gatherResults;
import as3twisted.internet.defer.fail;
import as3twisted.internet.defer.maybeDeferred;
import as3twisted.internet.defer.DeferredList;
import as3twisted.flash.failure.Failure;

public class TestDeferred {

    public var callbackResults:Array;
    public var errbackResults:Array ;
    public var callback2Results:Array;

    private function _callback(...args):* {
        callbackResults = args;
        return args[0];
    }

    private function _callback2(...args):void {
        callback2Results = args;
    }

    private function _errback(...args):void {
        errbackResults = args;
    }

    [Before]
    public function setUp():void {
        this.callbackResults = null;
        this.callback2Results = null;
        this.errbackResults = null;
    }

    [Test]
    public function testDeferredToString():void {
        var d:Deferred = new Deferred();
        d.addCallback(this._callback);
        Assert.assertEquals("[Deferred called=false paused=0 result=undefined chainedTo=null callbacks=[[[function Function() {}, []], [function Function() {}, []]]]]", d.toString());
    }

    [Test]
    public function testCallbackWithoutArgs():void {
        var d:Deferred = new Deferred();
        d.addCallback(this._callback);
        d.callback("hello");
        Assert.assertEquals(null, this.errbackResults);
        Assert.assertEquals("hello", this.callbackResults.join());
    }

    [Test]
    public function testCallbackWithArgs():void {
        var d:Deferred = new Deferred();
        d.addCallback(this._callback, "world");
        d.callback("hello");
        Assert.assertEquals(null, this.errbackResults);
        Assert.assertEquals("hello,world", this.callbackResults.join());
    }

    [Test]
    public function testTwoCallbacks():void {
        var d:Deferred = new Deferred();
        d.addCallback(this._callback);
        d.addCallback(this._callback2);
        d.callback("hello");
        Assert.assertEquals(null, this.errbackResults);
        Assert.assertEquals("hello", this.callbackResults.join());
        Assert.assertEquals("hello", this.callback2Results.join());
    }

    [Test]
    public function testDeferredList():void {
        var defr1:Deferred = new Deferred();
        var defr2:Deferred = new Deferred();
        var defr3:Deferred = new Deferred();
        var dl:DeferredList = new DeferredList([defr1, defr2, defr3]);

        var dlResult:Array = [];

        function _cb(resultList:Array):void {
            dlResult = dlResult.concat(resultList);
        }

        dl.addCallbacks(_cb, _cb);
        defr1.callback("1");
        defr2.errback(new Error("2"));
        defr3.callback("3");
        Assert.assertEquals(DeferredList.SUCCESS+",1", dlResult[0].join());
        Assert.assertEquals(DeferredList.FAILURE, dlResult[1][0]);
        Assert.assertEquals("2", dlResult[1][1].value.message);
        Assert.assertEquals(DeferredList.SUCCESS+",3", dlResult[2].join());
    }

    [Test]
    public function testDeferredListToString():void {
        var defr1:Deferred = new Deferred();
        var dl:DeferredList = new DeferredList([defr1]);
        Assert.assertEquals("[DeferredList called=false paused=0 result=undefined chainedTo=null callbacks=[] fireOnOneCallback=false fireOnOneErrback=false resultList=[] consumeErrors=false finishedCount=0]", dl.toString());
    }

    [Test]
    public function testEmptyDeferredList():void {
        var dlResult:Array = [];

        function _cb(resultList:Array):void {
            dlResult.push(resultList);
        }

        var dl:DeferredList = new DeferredList([]);
        dl.addCallbacks(_cb);
        Assert.assertEquals(1, dlResult.length);
        Assert.assertTrue(dlResult[0] is Array);
        Assert.assertEquals(0, dlResult[0].length);

        dlResult = [];
        dl = new DeferredList([], true);
        dl.addCallbacks(_cb);
        Assert.assertEquals(0, dlResult.length);
    }

    [Test]
    public function testDeferredListFireOnOneError():void {
        var defr1:Deferred = new Deferred();
        var defr2:Deferred = new Deferred();
        var defr3:Deferred = new Deferred();
        var dl:DeferredList = new DeferredList(
            [defr1, defr2, defr3], false, true);
        var dlResult:Array = [];

        dl.addErrback(function (f:*):void {dlResult.push(f)});

        // fire one Deferred's callback, no result yet
        defr1.callback("1");
        Assert.assertEquals(0, dlResult.length);

        // fire one Deferred's errback -- now we have a result
        defr2.errback(Error("from def2"))
        Assert.assertEquals(1, dlResult.length);
    }

    [Test]
    public function testDeferredListDontConsumeErrors():void {
        var d:Deferred = new Deferred();
        var dl:DeferredList = new DeferredList([d]);

        var errorTrap:Array = [];
        d.addErrback(function (f:Failure):void {errorTrap.push(f)});

        var result:Array = [];
        dl.addCallback(function (r:*):void {result.push(r)});

        d.errback(new Error("Bang"));
        Assert.assertEquals("Bang", errorTrap[0].value.message);
        Assert.assertEquals(1, result.length);
        Assert.assertEquals("Bang", result[0][0][1].value.message);
    }

    [Test]
    public function testDeferredListConsumeErrors():void {
        var d:Deferred = new Deferred();
        var dl:DeferredList = new DeferredList([d], false, false, true);

        var errorTrap:Array = [];
        d.addErrback(function (f:Failure):void {errorTrap.push(f)});

        var result:Array = [];
        dl.addCallback(function (r:*):void {result.push(r)});

        d.errback(new Error("Bang"));
        Assert.assertEquals(0, errorTrap.length);
        Assert.assertEquals(1, result.length);
        Assert.assertEquals("Bang", result[0][0][1].value.message);
    }

    [Test]
    public function testDeferredListFireOnOneErrorWithAlreadyFiredDeferreds():void {
        // Create some deferreds, and errback one
        var d1:Deferred = new Deferred()
        var d2:Deferred = new Deferred()
        d1.errback(Error("Bang"));

        // *Then* build the DeferredList, with fireOnOneErrback=true
        var dList:DeferredList = new DeferredList([d1, d2], false, true);
        var result:Array = [];
        dList.addErrback(function (r:*):void {result.push(r)});
        Assert.assertEquals(1, result.length);
        d1.addErrback(function ():void {});  // Swallow error
    }

    [Test]
    public function testDeferredListWithAlreadyFiredDeferreds():void {
        // Create some deferreds, and err one, call the other
        var d1:Deferred = new Deferred()
        var d2:Deferred = new Deferred()
        d1.errback(Error("Bang"));
        d2.callback(2);

        // *Then* build the DeferredList
        var dList:DeferredList = new DeferredList([d1, d2]);

        var result:Array = [];
        dList.addCallback(function (r:*):void {result.push(r)});

        Assert.assertEquals(1, result.length);
        d1.addErrback(function ():void {});  // Swallow error
    }

    [Test]
    public function testImmediateSuccess():void {
        var result:Array = [];
        var d:Deferred = succeed("success");
        d.addCallback(function (r:*):void {result.push(r)});
        Assert.assertEquals(1, result.length);
        Assert.assertEquals("success", result[0]);
    }

    [Test]
    public function testImmediateFailure():void {
        var result:Array = [];
        var d:Deferred = fail(Error("fail"));
        d.addErrback(function (r:*):void {result.push(r)});
        Assert.assertEquals(1, result.length);
        Assert.assertEquals("fail", result[0].value.message);
    }

    [Test]
    public function testPausedFailure():void {
        var result:Array = [];
        var d:Deferred = fail(Error("fail"));
        d.pause();
        d.addErrback(function (e:*):void {result.push(e)});
        Assert.assertEquals(0, result.length);
        d.unpause();
        Assert.assertEquals(1, result.length);
        Assert.assertEquals("fail", result[0].value.message);
    }

    [Test]
    public function testCallbackErrors():void {
        var l:Array = [];
        var d:Deferred = new Deferred();
        d.addCallback(function ():void {throw new TypeError();});
        d.addErrback(function (e:Failure):void {l.push(e)});
        d.callback(1);
        Assert.assertTrue(l[0].value is TypeError);

        l = [];
        d = new Deferred();
        d.addCallback(function ():Failure {return new Failure(new TypeError());});
        d.addErrback(l.push);
        d.callback(1);
        Assert.assertTrue(l[0].value is TypeError);
    }

    [Test]
    public function testUnpauseBeforeCallback():void {
        var d:Deferred = new Deferred();
        d.pause();
        d.addCallback(this._callback);
        d.unpause();
    }

    [Test]
    public function testReturnDeferred():void {
        var d:Deferred = new Deferred();
        var d2:Deferred = new Deferred();
        d2.pause();
        d.addCallback(function (r:*):Deferred {return d2});
        d.addCallback(this._callback);
        d.callback(1);
        Assert.assertEquals(null, this.callbackResults);
        d2.callback(2);
        Assert.assertEquals(null, this.callbackResults);
        d2.unpause();
        Assert.assertEquals(2, this.callbackResults[0]);
    }

    [Test]
    public function testGatherResults():void {
        // test successful list of deferreds
        var result:Array = [];
        var d:Deferred = gatherResults(
            [succeed(1), succeed(2)]);
        d.addCallback(function (r:*):void {result.push(r)});

        Assert.assertEquals("1,2", result.join());

        // test failing list of deferreds
        result = []
        d = gatherResults(
            [succeed(1), fail(Error("Bang"))]);
        d.addErrback(function (r:*):void {result.push(r)});
        Assert.assertEquals(1, result.length);
        Assert.assertTrue(result[0] is Failure);
    }

    /**
     * maybeDeferred should retrieve the result of a synchronous
     * function and pass it to its resulting L{defer.Deferred}.
     */
    [Test]
    public function testMaybeDeferredSync():void {
        var S:Array = [];
        var E:Array = [];

        function _cb(x:int):int {
            return x + 5;
        }
        var d:Deferred = maybeDeferred(_cb, 10);
        d.addCallbacks(
            function (r:*):void {S.push(r)},
            function (e:*):void {E.push(e)});
        Assert.assertEquals(0, E.length);
        Assert.assertEquals(1, S.length);
        Assert.assertEquals(15, S[0]);
    }

    /**
     * maybeDeferred should catch exception raised by a synchronous
     * function and errback its resulting Deferred with it.
     */
    [Test]
    public function testMaybeDeferredSyncError():void {
        var S:Array = [];
        var E:Array = [];

        function _cb(x:int):int {
            throw new TypeError("Bang");
        }
        var d:Deferred = maybeDeferred(_cb, 10);
        d.addCallbacks(
            function (r:*):void {S.push(r)},
            function (e:*):void {E.push(e)});
        Assert.assertEquals(0, S.length);
        Assert.assertEquals(1, E.length);
        Assert.assertTrue(E[0].value is TypeError);
    }

    [Test]
    public function testMaybeDeferredAsync():void {
        var d:Deferred = new Deferred();
        var d2:Deferred = maybeDeferred(
            function ():Deferred {return d});
        d.callback("Success");

        function _cb(result:*):void {
            Assert.assertEquals("Success", result);
        }
        d2.addCallback(_cb);
    }

    /**
     * maybeDeferred should let Deferred instance pass by so that
     * Failure returned by the original instance is the same.
     */
    [Test]
    public function testMaybeDeferredAsyncError():void {
        var d:Deferred = new Deferred();
        var d2:Deferred = maybeDeferred(
            function ():Deferred {return d});
        d.errback(new Failure(new TypeError("Bang")));
        
        function _eb(error:*):void {
            Assert.assertTrue(error.value is TypeError);
        }
        d2.addErrback(_eb);
    }

    /**
     * A callback added to a Deferred by a callback on that Deferred
     * should be added to the end of the callback chain.
     */
    [Test]
    public function testReentrantRunCallbacks():void {
        var d:Deferred = new Deferred();
        var called:Array = [];

        function callback3(result:*):void {
            called.push(3);
        }
        function callback2(result:*):void {
            called.push(2);
        }
        function callback1(result:*):void {
            called.push(1);
            d.addCallbacks(callback3);
        }
        d.addCallback(callback1);
        d.addCallback(callback2);
        d.callback(null);
        Assert.assertEquals("1,2,3", called.join());
    }

    /**
     * A callback added to a Deferred by a callback on that Deferred
     * should not be executed until the running callback returns.
     */
    [Test]
    public function TestNonReentrantCallbacks():void {
        var d:Deferred = new Deferred();
        var called:Array = [];

        function callback2(result:*):void {
            called.push(2);
        }
        function callback1(result:*):void {
            called.push(1);
            d.addCallback(callback2);
        }
        d.addCallback(callback1);
        d.callback(null);
        Assert.assertEquals("1,2", called.join());
    }

    /**
     * After an exception is raised by a callback which was added to a
     * Deferred by a callback on that Deferred, the Deferred should
     * call the first errback with a Failure wrapping that exception.
     */
    [Test]
    public function testReentrantRunCallbacksWithFailure():void {
        var message:String = "callback raised exception";
        var d:Deferred = new Deferred();

        function callback2(result:*):void {
            throw new TypeError(message);
        }
        function callback1(result:*):void {
            d.addCallback(callback2);
        }
        d.addCallback(callback1);
        d.callback(null);

        function _eb(e:Failure):void {
            Assert.assertTrue(e.value is TypeError);
        }

        d.addErrback(_eb);

        function cbFailed(e:*):void {
            Assert.assertEquals(message, e.value.message);
        }
        d.addCallback(cbFailed);
    }

    /**
     * If a first Deferred with a result is returned from a callback on a
     * second Deferred, the result of the second Deferred becomes the
     * result of the first Deferred and the result of the first Deferred
     * becomes null.
     */
    [Test]
    public function testSynchronousImplicitChain():void {
        var result:Object = new Object();
        var first:Deferred = succeed(result);
        var second:Deferred = new Deferred();
        second.addCallback(function (ign:*):Deferred {return first});
        second.callback(null);

        var results:Array = [];
        var cb:Function = function (r:*):void {results.push(r)}
        first.addCallback(cb);
        Assert.assertTrue(results[0] == null);
        second.addCallback(cb);
        Assert.assertTrue(results[1] === result);
    }

    /**
     * If a first Deferred without a result is returned from a callback on
     * a second Deferred, the result of the second Deferred becomes the
     * result of the first Deferred as soon as the first Deferred has
     * one and the result of the first Deferred becomes null.
     */
    public function testAsynchronousImplicitChain():void {
        var first:Deferred = new Deferred();
        var second:Deferred = new Deferred();
        second.addCallback(function (ign:*):Deferred {return first});
        second.callback(null);

        var firstResult:Array = [];
        first.addCallback(function (r:*):void {firstResult.push(r)});
        var secondResult:Array = [];
        second.addCallback(function (r:*):void {secondResult.push(r)});

        Assert.assertEquals(0, firstResult.length);
        Assert.assertEquals(0, secondResult.length);

        var result:Object = new Object();
        first.callback(result);

        Assert.assertEquals(1, firstResult);
        Assert.assertEquals(null, firstResult[0]);
        Assert.assertEquals(1, secondResult);
        Assert.assertTrue(secondResult[0] === result);
    }

    /**
     * If a first Deferred with a Failure result is returned from a
     * callback on a second Deferred, the first Deferred's result is
     * converted to null and no unhandled error is logged when it is
     * garbage collected.
     */
    [Test]
    public function testSynchronousImplicitErrorChain():void {
        var first:Deferred = fail(
            new TypeError("First Deferred's Failure"));
        var second:Deferred = new Deferred();
        second.addCallback(function (ign:*):Deferred {return first});

        function _eb(e:Failure):void {
            Assert.assertTrue(e.value is TypeError);
        }
        second.addErrback(_eb);

        second.callback(null);
        var firstResult:Array = [];
        first.addCallback(function (r:*):void {firstResult.push(r)});
        Assert.assertEquals(1, firstResult.length);
        Assert.assertEquals(null, firstResult[0]);
    }

    /**
    * Let a and b be two Deferreds.
    *
    * <p>If a has no result and is returned from a callback on b then when
    * a fails, b's result becomes the Failure that was a's result,
    * the result of a becomes null so that no unhandled error is logged
    * when it is garbage collected.</p>
    */
    [Test]
    public function TestAsynchronousImplicitErrorChain():void {
        var first:Deferred = new Deferred();
        var second:Deferred = new Deferred();
        second.addCallback(function (ign:*):Deferred {return first});
        second.callback(null);
        
        function _eb(e:*):void {
            Assert.assertTrue(e.value is TypeError);
        }
        second.addErrback(_eb);
        
        var firstResults:Array = [];
        first.addCallback(function (r:*):void {firstResults.push(r)});
        var secondResults:Array = [];
        second.addCallback(function (r:*):void {secondResults.push(r)});

        Assert.assertEquals(0, firstResults.length);
        Assert.assertEquals(0, secondResults.length);

        first.errback(new TypeError("First Deferred's Failure"));

        Assert.assertEquals(1, firstResults.length);
        Assert.assertEquals(null, firstResults[0]);
        Assert.assertEquals(1, secondResults.length);
    }

    /**
     * Deferred chaining is transitive.

     * In other words, let A, B, and C be Deferreds.  If C is returned from a
     * callback on B and B is returned from a callback on A then when C fires,
     * A fires.
     */
    [Test]
    public function TestDoubleAsynchronousImplicitChaining():void {
        var first:Deferred = new Deferred();
        var second:Deferred = new Deferred();
        second.addCallback(function (ign:*):Deferred {return first});
        var third:Deferred = new Deferred();
        third.addCallback(function (ign:*):Deferred {return second});

        var thirdResult:Array = [];
        third.addCallback(function (r:*):void {thirdResult.push(r)});

        var result:Object = new Object();
        // After this, second is waiting for first to tell it to continue.
        second.callback(null);
        // And after this, third is waiting for second to tell it to continue.
        third.callback(null);

        // Still waiting
        Assert.assertEquals(0, thirdResult);

        // This will tell second to continue which will tell third to continue.
        first.callback(result);
        Assert.assertEquals(1, thirdResult.length);
        Assert.assertTrue(thirdResult[0] === result);
    }

    /**
     * Deferreds can have callbacks that themselves return Deferreds.
     * When these "inner" Deferreds fire (even asynchronously), the
     * callback chain continues.
     */
    [Test]
    public function TestNestedAsynchronousChainedDeferreds():void {
        var results:Array = [];
        var failures:Array = [];

        // A Deferred returned in the inner callback.
        var inner:Deferred = new Deferred();

        var eb:Function = function (e:*):void {failures.push(e)};

        function cb(result:*):Deferred {
            results.push(["start-of-cb", result]);
            var d:Deferred = succeed("inner");

            function firstCallback(result:*):Deferred {
                results.push(["firstCallback", "inner"]);
                // Return a Deferred that definitely has not fired yet, so we
                // can fire the Deferreds out of order.
                return inner;
            }

            function secondCallback(result:String):String {
                results.push(["secondCallback", result]);
                result += result
                return result;
            }

            d.addCallback(firstCallback);
            d.addCallback(secondCallback);
            d.addErrback(eb);
            return d;
        }

        // Create a synchronous Deferred that has a callback 'cb' that returns
        // a Deferred 'd' that has fired but is now waiting on an unfired
        // Deferred 'inner'.
        var outer:Deferred = succeed("outer");
        outer.addCallback(cb);
        outer.addCallback(function (r:*):void {results.push(r)});
        // At this point, the callback 'cb' has been entered, and the first
        // callback of 'd' has been called.
        Assert.assertEquals(2, results.length);
        Assert.assertEquals("start-of-cb,outer", results[0].join());
        Assert.assertEquals("firstCallback,inner", results[1].join());

        // Once the inner Deferred is fired, processing of the outer Deferred's
        // callback chain continues.
        inner.callback("orange");

        // Make sure there are no errors.
        inner.addErrback(eb);
        outer.addErrback(eb);
        Assert.assertEquals(0, failures.length);

        Assert.assertEquals(4, results.length);
        Assert.assertEquals("start-of-cb,outer", results[0].join());
        Assert.assertEquals("firstCallback,inner", results[1].join());
        Assert.assertEquals("secondCallback,orange", results[2].join());
        Assert.assertEquals("orangeorange", results[3]);
    }

    /**
     * Deferreds can have callbacks that themselves return Deferreds.
     * These Deferreds can have other callbacks added before they are
     * returned, which subtly changes the callback chain. When these "inner"
     * Deferreds fire (even asynchronously), the outer callback chain
     * continues.
     */
    [Test]
    public function TestNestedAsynchronousChainedDeferredsWithExtraCallbacks():void {
        var results:Array = [];
        var failures:Array = [];

        // A Deferred returned in the inner callback after a callback is
        // added explicitly and directly to it.
        var inner:Deferred = new Deferred();

        function eb(e:*):void {
            failures.push(e);
        }

        function cb(result:*):Deferred {
            results.push(["start-of-cb", result]);
            var d:Deferred = succeed("inner");

            function firstCallback(ignored:*):Deferred {
                results.push(["firstCallback", ignored]);
                // Return a Deferred that definitely has not fired yet with a
                // result-transforming callback so we can fire the Deferreds
                // out of order and see how the callback affects the ultimate
                // results.
                return inner.addCallback(function (x:*):Array {return [x];});
            }

            function secondCallback(result:Array):Array {
                results.push(["secondCallback", result]);
                return [result, result];
            }

            d.addCallback(firstCallback);
            d.addCallback(secondCallback);
            d.addErrback(eb);
            return d
        }

        // Create a synchronous Deferred that has a callback 'cb' that returns
        // a Deferred 'd' that has fired but is now waiting on an unfired
        // Deferred 'inner'.
        var outer:Deferred = succeed("outer");
        outer.addCallback(cb);
        outer.addCallback(function (r:*):void {results.push(r);});
        // At this point, the callback "cb" has been entered, and the first
        // callback of "d" has been called.
        Assert.assertEquals(2, results.length);
        Assert.assertEquals("start-of-cb,outer", results[0].join());
        Assert.assertEquals("firstCallback,inner", results[1].join());

        // Once the inner Deferred is fired, processing of the outer Deferred's
        // callback chain continues.
        inner.callback("withers");

        // Make sure there are no errors.
        outer.addErrback(eb);
        inner.addErrback(eb);
        Assert.assertEquals(0, failures.length);

        Assert.assertEquals(4, results.length);
        Assert.assertEquals("start-of-cb,outer", results[0].join());
        Assert.assertEquals("firstCallback,inner", results[1].join());
        Assert.assertEquals("secondCallback,withers", results[2].join());
        Assert.assertEquals("withers,withers", results[3].join());
    }

    /**
     * When we chain a Deferred, that chaining is recorded explicitly.
     */
    [Test]
    public function TestChainDeferredRecordsExplicitChain():void {
        var a:Deferred = new Deferred();
        var b:Deferred = new Deferred();
        b.chainDeferred(a)
        Assert.assertTrue(a.chainedTo === b);
    }
}
}
