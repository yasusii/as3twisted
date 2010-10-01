package test 
{
import as3twisted.internet.defer.Deferred;
import as3twisted.internet.defer.AlreadyCalledError;
import as3twisted.flash.failure.Failure;
import org.flexunit.Assert;

public class TestAlreadyCalled {

    private function _callback(...args):* {
        return null;
    }

    private function _errback(...args):* {
        return null;
    }

    private function _call_1(d:Deferred):void {
        d.callback("hello");
    }

    private function _call_2(d:Deferred):void {
        d.callback("twice");
    }

    private function _err_1(d:Deferred):void {
        d.errback(new Failure(new TypeError()));
    }

    private function _err_2(d:Deferred):void {
        d.errback(new Failure(new TypeError()));
    }

    [Test]
    public function testAlreadyCalled_CC():void {
        var d:Deferred = new Deferred();
        d.addCallback(this._callback);
        d.addCallbacks(this._callback, this._errback);
        this._call_1(d);
        try {
            this._call_2(d);
            Assert.fail("this should not be called");
        } catch (e:*) {
            Assert.assertTrue(e is AlreadyCalledError);
        }
    }

    [Test]
    public function testAlreadyCalled_CE():void {
        var d:Deferred = new Deferred()
        d.addCallbacks(this._callback, this._errback)
        this._call_1(d)
        try {
            this._err_2(d);
            Assert.fail("this should not be called");
        } catch (e:*) {
            Assert.assertTrue(e is AlreadyCalledError);
        }
    }

    [Test]
    public function testAlreadyCalled_EE():void {
        var d:Deferred = new Deferred()
        d.addCallbacks(this._callback, this._errback)
        this._err_1(d)
        try {
            this._err_2(d);
            Assert.fail("this should not be called");
        } catch (e:*) {
            Assert.assertTrue(e is AlreadyCalledError);
        }
    }

    [Test]
    public function testAlreadyCalled_EC():void {
        var d:Deferred = new Deferred()
        d.addCallbacks(this._callback, this._errback)
        this._err_1(d)
        try {
            this._call_2(d);
            Assert.fail("this should not be called");
        } catch (e:*) {
            Assert.assertTrue(e is AlreadyCalledError);
        }
    }
}
}
