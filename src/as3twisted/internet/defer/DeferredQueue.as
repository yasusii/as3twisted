package as3twisted.internet.defer {

import as3twisted.internet.defer.Deferred;
import as3twisted.internet.defer.QueueOverflow;
import as3twisted.internet.defer.QueueUnderflow;
import as3twisted.internet.defer.succeed;

/**
 * An event driven queue.
 *
 * <p>Objects may be added as usual to this queue.  When an attempt is
 * made to retrieve an object when the queue is empty, a
 * <code>Deferred</code> is returned which will fire when an object
 * becomes available.</p>
 */
public class DeferredQueue {

    public var waiting:Array;
    public var pending:Array;

    /** The maximum number of objects to allow into the queue at a
     * time */
    public var size:int;
    /** The maximum number of <code>Deferred</code> gets to allow at
     * one time */
    public var backlog:int;

    /**
     * Initialize a DeferredQueue
     *
     * @param size The maximum number of objects to allow into the
     * queue at a time.  When an attempt to add a new object would
     * exceed this limit, <code>QueueOverflow</code> is raised
     * synchronously.  -1 for no limit.
     *
     * @param backlog The maximum number of <code>Deferred</code> gets
     * to allow at one time.  When an attempt is made to get an object
     * which would exceed this limit, <code>QueueUnderflow</code> is
     * raised synchronously.  -1 for no limit.
     *
     * @see QueueOverflow
     * @see QueueUnderflow
     */
    public function DeferredQueue(size:int=-1, backlog:int=-1) {
        this.waiting = [];
        this.pending = [];
        this.size = size;
        this.backlog = backlog;
    }

    /**
     * Add an object to this queue.
     *
     * @throws as3twisted.internet.defer.QueueOverflow Too many
     * objects are in this queue.
     */
    public function put(obj:*):void {
        if (this.waiting.length > 0) {
            var d:Deferred = this.waiting.shift();
            d.callback(obj);
        } else if ((this.size < 0) || (this.pending.length < this.size)) {
            this.pending.push(obj);
        } else {
            throw new QueueOverflow();
        }
    }    

    /**
     * Attempt to retrieve and remove an object from the queue.
     *
     * @return a <code>Deferred</code> which fires with the next
     * object available in the queue.
     *
     * @throws as3twisted.internet.defer.QueueUnderflow Too many (more
     * than <code>backlog</code>) <code>Deferred</code>s are already
     * waiting for an object from this queue.
     */

    public function get():Deferred {

        function _cancelGet():void {
            var index:int = waiting.indexOf(this);
            if (index >= 0) {
                waiting = [].concat(
                    waiting.slice(0, index), waiting.slice(index+1));
            }
        }

        if (this.pending.length > 0) {
            var obj:* = this.pending.shift();
            return succeed(obj);
        } else if ((this.backlog < 0) || (this.waiting.length < this.backlog)) {
            var d:Deferred = new Deferred(_cancelGet);
            this.waiting.push(d);
            return d;
        } else {
            throw new QueueUnderflow();
        }
    }
}
}