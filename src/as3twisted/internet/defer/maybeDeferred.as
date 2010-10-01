package as3twisted.internet.defer
{
import as3twisted.internet.defer.Deferred;
import as3twisted.internet.defer.succeed;
import as3twisted.internet.defer.fail;
import as3twisted.flash.failure.Failure;
/**
 * Invoke a function that may or may not return a <code>Deferred</code>.
 *
 * <p>Call the given function with the given arguments.  If the
 * returned object is a <code>Deferred</code>, return it.  If the
 * returned object is a <code>Failure</code>, wrap it with
 * <code>fail</code> and return it.  Otherwise, wrap it in
 * <code>succeed</code> and return it.  If an exception is raised,
 * convert it to a <code>Failure</code>, wrap it in <code>fail</code>,
 * and then return it.</p>
 *
 * @param f The function to invoke
 *
 * @param args The arguments to pass to <code>f</code>
 *
 * @return The result of the function call, wrapped in a
 * <code>Deferred</code> if necessary.
 *
 * @see as3twisted.internet.defer#fail()
 * @see as3twisted.internet.defer#succeed()
 * @see as3twisted.flash.failure.Failure
 */
public function maybeDeferred(f:Function, ...args:Array):Deferred {
    try {
        var result:* = f.apply(null, args);
    } catch (e:*) {
        return fail(new Failure(e));
    }
    if (result is Deferred) {
        return result;
    } else if (result is Failure) {
        return fail(result);
    } else {
        return succeed(result);
    }
}
}