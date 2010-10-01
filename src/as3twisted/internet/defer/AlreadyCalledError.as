package as3twisted.internet.defer
{
/**
 * Thrown if <code>Deferred</code>'s callback has already been called.
 *
 * @see Deferred
 */
public class AlreadyCalledError extends Error {

	public function AlreadyCalledError(message:String="") {
	    super(message);
        this.name = "AlreadyCalledError";
	}
}
}