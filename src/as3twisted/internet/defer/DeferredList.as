package as3twisted.internet.defer 
{
import as3twisted.internet.defer.Deferred;
import as3twisted.internet.defer.AlreadyCalledError;
import as3twisted.internet.defer.FirstError;
import as3twisted.flash.failure.Failure;
import as3twisted.flash.util.arrayToString;
/**
 * I combine a group of deferreds into one callback.
 *
 * <p>I track a list of <code>Deferred</code>s for their callbacks,
 * and make a single callback when they have all completed, a array of
 * [success, result] arrays, 'success' being a boolean.</p>
 *
 * <p>Note that you can still use a <code>Deferred</code> after
 * putting it in a DeferredList.  For example, you can suppress
 * 'Unhandled error in Deferred' messages by adding errbacks to the
 * Deferreds *after* putting them in the DeferredList, as a
 * DeferredList won't swallow the errors.  (Although a more convenient
 * way to do this is simply to set the <code>consumeErrors</code>
 * flag)</p>
 */
public class DeferredList extends Deferred {

    public static const SUCCESS:Boolean = true;
    public static const FAILURE:Boolean = false;

    /** A flag indicating that only one callback needs to be fired for
     * me to call my callback */
    public var fireOnOneCallback:Boolean;
    /** A flag indicating that only one errback needs to be fired for
     * me to call my errback */
    public var fireOnOneErrback:Boolean;
    /** A flag indicating that any errors thrown in the original
     * deferreds should be consumed by this
     * <code>DeferredList</code>. */
    public var consumeErrors:Boolean;
    public var resultList:Array;
    /** @default 0 */
    public var finishedCount:int = 0;

    /**
     * Initialize a <code>DeferredList</code>
     *
     * @param deferredList An array of <code>Deferred</code>s
     *
     * @param fireOnOneCallback A flag indicating that only one
     * callback needs to be fired for me to call my callback
     *
     * @param fireOnOneErrback A flag indicating that only one errback
     * needs to be fired for me to call my errback
     *
     * @param consumeErrors A flag indicating that any errors thrown
     * in the original deferreds should be consumed by this
     * <code>DeferredList</code>.  This is useful to prevent spurious
     * warnings being logged.
     *
     * @see Deferred
     */
    public function DeferredList(
        deferredList:Array, fireOnOneCallback:Boolean=false,
        fireOnOneErrback:Boolean=false, consumeErrors:Boolean=false) {

                                 
        this.resultList = new Array(deferredList.length);
        super();
        if ((deferredList.length == 0) && (!fireOnOneCallback)) {
            this.callback(this.resultList);
        }
        this.fireOnOneCallback = fireOnOneCallback;
        this.fireOnOneErrback = fireOnOneErrback;
        this.consumeErrors = consumeErrors;

        for (var index:int=0; index < deferredList.length; index++) {
            deferredList[index].addCallbacks(this._cbDeferred, this._cbDeferred, [index, SUCCESS], [index, FAILURE]);
        }
    }

    override public function toString():String {
        var a:Array = [];
        a.push("DeferredList")
        a.push("called=" + this.called);
        a.push("paused=" + this.paused);
        if (this.result is Array) {
            a.push("result=" + arrayToString(this.result));
        } else {
            a.push("result=" + this.result);
        }
        a.push("chainedTo=" + this.chainedTo);
        a.push("callbacks=" + arrayToString(this.callbacks));
        a.push("fireOnOneCallback=" + this.fireOnOneCallback);
        a.push("fireOnOneErrback=" + this.fireOnOneErrback);
        a.push("resultList=" + arrayToString(this.resultList));
        a.push("consumeErrors=" + this.consumeErrors);
        a.push("finishedCount=" + this.finishedCount);
        return "[" + a.join(" ") + "]";
    }

    private function _cbDeferred(result:*, index:int, succeeded:Boolean):* {
        this.resultList[index] = [succeeded, result];
        this.finishedCount += 1;
        if (!this.called) {
            if ((succeeded == SUCCESS) && (this.fireOnOneCallback)) {
                this.callback([result, index]);
            } else if ((succeeded == FAILURE) && (this.fireOnOneErrback)) {
                this.errback(new Failure(new FirstError(result, index)));
            } else if (this.finishedCount == this.resultList.length) {
                this.callback(this.resultList);
            }
        }
        if ((succeeded == FAILURE) && this.consumeErrors) {
            result = null;
        }
        return result;
    }
}
}