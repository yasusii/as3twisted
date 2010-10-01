package as3twisted.internet.defer {

import as3twisted.internet.defer.Deferred;
import as3twisted.internet.defer.DeferredList;

/**
 * Returns list with result of given <code>Deferred</code>s.
 *
 * <p>This builds on <code>DeferredList</code> but is useful since you
 * don't need to parse the result for success/failure.</p>
 *
 * @param deferredList A array of <code>Deferred</code>s
 *
 * @see as3twisted.internet.defer.Deferred
 * @see as3twisted.internet.defer.DeferredList
 */
public function gatherResults(deferredList:Array):Deferred {

    function _parseDListResult(resultList:Array):Array {
        var a:Array = [];
        for each (var item:* in resultList) {
            a.push(item[1]);
        }
        return a;
    }

    var d:Deferred = new DeferredList(deferredList, false, true);
    d.addCallback(_parseDListResult);
    return d;
}
}