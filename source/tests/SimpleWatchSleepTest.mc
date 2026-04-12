using Toybox.Test as Test;

// ─── isAwake lifecycle ────────────────────────────────────────────────────────

(:test)
function testIsAwakeTrueOnInit(logger) {
    var view = new SimpleWatchView();
    Test.assertMessage(view.isAwake,
        "isAwake must be true immediately after construction");
    return true;
}

(:test)
function testEnterSleepSetsAwakeFalse(logger) {
    var view = new SimpleWatchView();
    view.onEnterSleep();
    Test.assertMessage(!view.isAwake,
        "isAwake must be false after onEnterSleep()");
    return true;
}

(:test)
function testExitSleepSetsAwakeTrue(logger) {
    var view = new SimpleWatchView();
    view.onEnterSleep();
    view.onExitSleep();
    Test.assertMessage(view.isAwake,
        "isAwake must be true after onExitSleep()");
    return true;
}

(:test)
function testSleepWakeCycleRepeatable(logger) {
    var view = new SimpleWatchView();
    for (var i = 0; i < 3; i++) {
        view.onEnterSleep();
        Test.assertMessage(!view.isAwake,
            "Cycle " + i + ": must be false after onEnterSleep()");
        view.onExitSleep();
        Test.assertMessage(view.isAwake,
            "Cycle " + i + ": must be true after onExitSleep()");
    }
    return true;
}

(:test)
function testDoubleEnterSleepIdempotent(logger) {
    var view = new SimpleWatchView();
    view.onEnterSleep();
    view.onEnterSleep();
    Test.assertMessage(!view.isAwake,
        "isAwake must stay false after two consecutive onEnterSleep()");
    return true;
}

(:test)
function testDoubleExitSleepIdempotent(logger) {
    var view = new SimpleWatchView();
    view.onExitSleep();
    view.onExitSleep();
    Test.assertMessage(view.isAwake,
        "isAwake must stay true after two consecutive onExitSleep()");
    return true;
}

(:test)
function testIndependentViewInstances(logger) {
    var v1 = new SimpleWatchView();
    var v2 = new SimpleWatchView();
    v1.onEnterSleep();
    Test.assertMessage(!v1.isAwake, "v1 should be asleep");
    Test.assertMessage(v2.isAwake, "v2 state must be independent from v1");
    return true;
}

(:test)
function testGuardStateMatchesLifecycle(logger) {
    var view = new SimpleWatchView();
    Test.assertMessage(view.isAwake, "Guard: must be true before any call");
    view.onEnterSleep();
    Test.assertMessage(!view.isAwake, "Guard: must be false in sleep mode");
    view.onExitSleep();
    Test.assertMessage(view.isAwake, "Guard: must be true after wake");
    return true;
}

// ─── Constants sanity checks ──────────────────────────────────────────────────

(:test)
function testBatteryCriticalThresholdInRange(logger) {
    var view = new SimpleWatchView();
    Test.assertMessage(view.BATTERY_CRITICAL_THRESHOLD > 0.0,
        "BATTERY_CRITICAL_THRESHOLD must be > 0");
    Test.assertMessage(view.BATTERY_CRITICAL_THRESHOLD < 1.0,
        "BATTERY_CRITICAL_THRESHOLD must be < 1.0");
    return true;
}

(:test)
function testStepsMinThresholdInRange(logger) {
    var view = new SimpleWatchView();
    Test.assertMessage(view.STEPS_MIN_THRESHOLD >= 0.0,
        "STEPS_MIN_THRESHOLD must be >= 0");
    Test.assertMessage(view.STEPS_MIN_THRESHOLD < 1.0,
        "STEPS_MIN_THRESHOLD must be < 1.0");
    return true;
}

(:test)
function testHandPenWidthPositive(logger) {
    var view = new SimpleWatchView();
    Test.assertMessage(view.HAND_PEN_WIDTH > 0,
        "HAND_PEN_WIDTH must be positive");
    return true;
}

(:test)
function testHandTipRatiosInRange(logger) {
    var view = new SimpleWatchView();
    Test.assertMessage(view.HAND_TIP_RATIO > 0.0 && view.HAND_TIP_RATIO < 0.2,
        "HAND_TIP_RATIO must be a small positive fraction");
    Test.assertMessage(view.HAND_TIP_INNER_RATIO > 0.0
                       && view.HAND_TIP_INNER_RATIO < view.HAND_TIP_RATIO,
        "HAND_TIP_INNER_RATIO must be smaller than HAND_TIP_RATIO");
    return true;
}

(:test)
function testCenterCircleRatioInRange(logger) {
    var view = new SimpleWatchView();
    Test.assertMessage(view.CENTER_CIRCLE_RATIO > 0.0
                       && view.CENTER_CIRCLE_RATIO < 0.3,
        "CENTER_CIRCLE_RATIO must be a small positive fraction");
    return true;
}

(:test)
function testArcCapRatioInRange(logger) {
    var view = new SimpleWatchView();
    Test.assertMessage(view.ARC_CAP_RATIO > 0.0 && view.ARC_CAP_RATIO < 1.0,
        "ARC_CAP_RATIO must be in (0, 1)");
    return true;
}
