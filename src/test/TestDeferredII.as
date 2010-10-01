package test 
{
import as3twisted.internet.defer.DeferredList;
import org.flexunit.Assert;

public class TestDeferredII {

    public var callbackRan:int;

    [Before]
    public function setUp():void {
        this.callbackRan = 0;
    }

    /**
     * Testing empty DeferredList.
     */
    [Test]
    public function testDeferredListEmpty():void {
        var dl:DeferredList = new DeferredList([]);
        dl.addCallback(this._cb_empty);
    }

    private function _cb_empty(res:*):void {
        callbackRan = 1;
        Assert.assertTrue(res is Array);
        Assert.assertEquals(0, res.length);
    }

    [After]
    public function tearDown():void {
        Assert.assertEquals(1, this.callbackRan);
    }
}
}
