package as3twisted.internet.defer
{
import as3twisted.internet.defer.Deferred;
/**
 * Return a <code>Deferred</code> that has already had
 * <code>.callback(result)</code> called.
 *
 * <p>This is useful when you're writing synchronous code to an
 * asynchronous interface: i.e., some code is calling you expecting a
 * <code>Deferred</code> result, but you don't actually need to do
 * anything asynchronous. Just return
 * <code>as3twisted.internet.defer.succeed(theResult)</code>.</p>
 *
 * @param result: The result to give to the <code>Deferred</code>'s
 * 'callback'
 *
 * @see as3twisted.internet.defer#fail()
 */
public function succeed(result:*):Deferred {
    var d:Deferred = new Deferred();
    d.callback(result);
    return d;
}
}