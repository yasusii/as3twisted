package as3twisted.internet.defer
{
/**
 * This error is thrown by default when a <code>Deferred</code> is
 * cancelled.
 *
 * @see Deferred
 */
public class CancelledError extends Error {

	public function CancelledError(message:String="") {
	    super(message);
        this.name = "CancelledError";
	}
}
}