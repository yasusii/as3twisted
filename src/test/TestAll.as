package test
{

[Suite]
[RunWith("org.flexunit.runners.Suite")]
public class TestAll {

    public var test1:TestReflect;
    public var test2:TestFailure;
    public var test3:TestDeferred;
    public var test4:TestAlreadyCalled;
    public var test5:TestDeferredCanceller;
    public var test6:TestDeferredII;
    public var test7:TestOtherPrimitives;
    public var test8:TestLoopingCall;
    public var test9:TestUtil;
    public var test10:TestDeferredResponder;
    public var test20:TestAMFProxy;
}
}
