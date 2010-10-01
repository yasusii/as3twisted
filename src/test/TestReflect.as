package test 
{
import org.flexunit.Assert;
import flash.errors.*;
import as3twisted.flash.Reflect;

public class TestReflect {

    [Before]
    public function setUp():void {
    }

    [After]
    public function tearDown():void {
    }

    [Test]
    public function testIsClass():void {
        var result:Boolean;
        result = Reflect.isClass(String);
        Assert.assertEquals(true, result);
        result = Reflect.isClass("");
        Assert.assertEquals(false, result);
        result = Reflect.isClass(null);
        Assert.assertEquals(false, result);
    }

    [Test]
    public function testIsSubClass():void {
        var result:Boolean;
        result = Reflect.isSubClass(EOFError, EOFError);
        Assert.assertEquals(true, result);
        result = Reflect.isSubClass(EOFError, IOError);
        Assert.assertEquals(true, result);
        result = Reflect.isSubClass(IOError, EOFError);
        Assert.assertEquals(false, result);
    }

    [Test]
    public function testIsDynamic():void {
        var result:Boolean;
        result = Reflect.isDynamic(Error);
        Assert.assertEquals(true, result);
        result = Reflect.isDynamic(new Error());
        Assert.assertEquals(true, result);
        // All Classes are dynamic
        result = Reflect.isDynamic("spam");
        Assert.assertEquals(false, result);
        result = Reflect.isDynamic("spam");
        Assert.assertEquals(false, result);
    }

    [Test]
    public function testGetClass():void {
        var result:Class;
        result = Reflect.getClass("spam");
        Assert.assertEquals(String, result);
        result = Reflect.getClass(String);
        Assert.assertEquals(String, result);
    }

    [Test]
    public function testAllYourBase():void {
        var result:Array;
        result = Reflect.allYourBase(EOFError);
        Assert.assertEquals("[class IOError],[class Error]", result.join());
        result = Reflect.allYourBase(EOFError, Error);
        Assert.assertEquals("[class IOError]", result.join());
    }
}
}