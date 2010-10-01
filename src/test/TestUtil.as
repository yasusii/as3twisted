package test 
{
import org.flexunit.Assert;

import as3twisted.flash.util.arrayToString;

public class TestUtil {

    [Test]
    public function testArrayToString():void {
        var a:Array = ["one", "two", "three"]
        Assert.assertEquals("[one, two, three]", arrayToString(a));
        a = ["one", ["two", ["three"]]]
        Assert.assertEquals("[one, [two, [three]]]", arrayToString(a));
        a = [true, false, null, NaN, undefined, Infinity];
        Assert.assertEquals("[true, false, null, NaN, undefined, Infinity]",
                            arrayToString(a));
        a = null;
        Assert.assertEquals("null", arrayToString(a));
    }

}
}
