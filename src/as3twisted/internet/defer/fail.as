package as3twisted.internet.defer
{
import as3twisted.internet.defer.Deferred;

/**
 * Return a <code>Deferred</code> that has already had
 * <code>.errback(result)</code> called.
 *
 * @param result The same argument that <code>Deferred.errback</code>
 * takes.
 *
 * @see Deferred
 * @see as3twisted.internet.defer#succeed()
 */
public function fail(result:*=null):Deferred {
    var d:Deferred = new Deferred();
    d.errback(result);
    return d;
}
}