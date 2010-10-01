package as3twisted.flash
{
import flash.utils.*;

/**
 * Useful static methods for object reflection
 */
public class Reflect {

    /** Test if the object is a class or not */
    public static function isClass(obj:*):Boolean {
        var xml:XML = describeType(obj);
        return (xml.@base.toString() == "Class");
    }

    /** Test if <code>subClass</code> is a subclass of
     * <code>baseClass</code>
     */
    public static function isSubClass(subClass:Class, baseClass:Class):Boolean {
        var base:XML = describeType(baseClass);
        var sub:XML = describeType(subClass);
        if (base.@name == sub.@name) return true;

        for each (var elm:XML in sub.factory.extendsClass) {
            if (base.@name == elm.@type) return true;
        }
        return false;
    }

    /** Test if the object is dynamic or not */
    public static function isDynamic(obj:*):Boolean {
        // Return alawys true if obj is a class
        var xml:XML = describeType(obj);
        return (xml.@isDynamic.toString() == "true")
    }

    /** Get a class of the instance */
    public static function getClass(obj:*):Class {
        if (obj == null) throw TypeError("argument should be not null");
        var name:String = getQualifiedClassName(obj);
        var cls:Class = getDefinitionByName(name) as Class;
        return cls;
    }

    /** Get all the baseclass of the class
     *
     * <p>Traverse the class tree of all base classes that are
     * subclasses of baseClass, unless it is null, in which case all
     * bases will be added.</p>
     *
     * @param classObj A class to traverse
     *
     * @param baseClass The top of the baseclass tree.
     *
     * @return An array of the baseclasses
     */
    public static function allYourBase(classObj:Class, baseClass:Class=null):Array {
        if (classObj == null) {
            throw TypeError("argument classObj should be not null");
        }
        if (baseClass == null) baseClass = Object;

        var result:Array = [];
        var currentClass:Class = classObj;
        if (currentClass == baseClass) return result;

        var name:String;
        while (true) {
            name = getQualifiedSuperclassName(currentClass);
            if (name == null) return [];
            currentClass = getDefinitionByName(name) as Class;
            if (currentClass == baseClass) break;
            result.push(currentClass);
        }
        return result;
    }
}
}