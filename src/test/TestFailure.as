package test 
{
import org.flexunit.Assert;
import flash.errors.*;
import as3twisted.flash.Reflect;
import as3twisted.flash.failure.Failure;

public class TestFailure {

    [Before]
    public function setUp():void {
    }

    [After]
    public function tearDown():void {
    }

    [Test]
    public function testMessageProperty():void {
        var f:Failure = new Failure(new EOFError());
        f.message = "Error Message";
        Assert.assertEquals("Error Message", f.message);
    }

    [Test]
    public function testGetName():void {
        var f:Failure = new Failure(new EOFError());
        Assert.assertEquals("Failure", f.name);
    } 

    [Test]
    public function testGetErrorID():void {
        var f:Failure = new Failure(new EOFError());
        Assert.assertEquals(0, f.errorID);
    }

    [Test]
    public function testToString():void {
        var f:Failure = new Failure(new EOFError());
        Assert.assertEquals("Failure", f.toString());
        f = new Failure(new EOFError("this is EOFError"));
        Assert.assertEquals("Failure: this is EOFError", f.toString());
    }

    [Test]
    public function testTestFailureAndTrap():void {
        try {
            throw new EOFError("this is EOFError");
        } catch (e:Error) {
            var f:Failure = new Failure(e);
        }
        var error:Class = f.trap(RangeError, IOError);
        Assert.assertEquals(EOFError, f.type);
        Assert.assertEquals(IOError, error);
    }

    [Test]
    public function testNotTrapped():void {
        try {
            try {
                throw new EOFError("this is EOFError");
            } catch (err:Error) {
                var f:Failure = new Failure(err);
            }
            f.trap(RangeError);
        } catch (e:*) {
            Assert.assertEquals(true, e is Failure);
        }
    }

    [Test]
    public function testExplictPass():void {
        var e:EOFError = new EOFError("this is EOFError");
        var f:Failure = new Failure(e);
        f.trap(EOFError);
        Assert.assertEquals(e, f.value);
    }
}
}