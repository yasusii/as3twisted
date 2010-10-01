package as3twisted.internet.defer
{

import as3twisted.flash.failure.Failure;

/**
 * First error to occur in a <code>DeferredList</code> if
 * <code>fireOnOneErrback</code> is set.
 *
 * @see DeferredList
 */

public class FirstError extends Error {

    /** The <code>Failure</code> that occurred. */
    public var subFailure:Failure;
    /** The index of the <code>Deferred</code> in the
     * <code>DeferredList</code> where it happened. */
    public var index:int;

    /**
     * Initialize a FirstError
     *
     * @param failure The <code>Failure</code> that occurred.
     *
     * @param index The index of the <code>Deferred</code> in the
     * <code>DeferredList</code> where it happened.
     *
     * @see Deferred
     * @see DeferredList
     * @see as3twisted.flash.failure.Failure
     */
    public function FirstError(failure:Failure, index:int) {
        super();
        this.name = "FirstError";
        this.subFailure = failure;
        this.index = index;        
    }
}
}