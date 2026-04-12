using Toybox.Test as Test;
using Toybox.Math as Math;
using Toybox.Graphics as Gfx;
using Toybox.Application.Properties as Properties;

// ─── computeTimeData() ────────────────────────────────────────────────────────

(:test)
function testTimeDataDictionaryKeys(logger) {
    var data = new SimpleWatchView().computeTimeData();
    var keys = [:hour_angle, :minute_angle, :seconde_angle,
                :xyz_min, :xyz_hour, :stepsPercent,
                :color_sec, :battery, :dayDate];
    for (var i = 0; i < keys.size(); i++) {
        Test.assertMessage(data.hasKey(keys[i]),
            "computeTimeData() missing key: " + keys[i]);
    }
    return true;
}

// ─── Angle ranges ─────────────────────────────────────────────────────────────
// minute_angle = (min/60) * 2π - π/2  → [-π/2, 3π/2)
// hour_angle   = ((h%12 + min/60) / 12) * 2π - π/2
// seconde_angle same pattern

(:test)
function testMinuteAngleInRange(logger) {
    var data = new SimpleWatchView().computeTimeData();
    var a    = data[:minute_angle];
    Test.assertMessage(a >= -(Math.PI / 2.0) - 0.001
                       && a <= 3.0 * Math.PI / 2.0 + 0.001,
        "minute_angle out of range: " + a);
    return true;
}

(:test)
function testHourAngleInRange(logger) {
    var data = new SimpleWatchView().computeTimeData();
    var a    = data[:hour_angle];
    Test.assertMessage(a >= -(Math.PI / 2.0) - 0.001
                       && a <= 3.0 * Math.PI / 2.0 + 0.001,
        "hour_angle out of range: " + a);
    return true;
}

(:test)
function testSecondeAngleInRange(logger) {
    var data = new SimpleWatchView().computeTimeData();
    var a    = data[:seconde_angle];
    Test.assertMessage(a >= -(Math.PI / 2.0) - 0.001
                       && a <= 3.0 * Math.PI / 2.0 + 0.001,
        "seconde_angle out of range: " + a);
    return true;
}

// ─── xyz_min — integer [0, 59] ────────────────────────────────────────────────

(:test)
function testXyzMinInRange(logger) {
    var m = new SimpleWatchView().computeTimeData()[:xyz_min];
    Test.assertMessage(m >= 0 && m <= 59,
        "xyz_min must be in [0, 59], got: " + m);
    return true;
}

// ─── xyz_hour — [0.0, 1.0) ───────────────────────────────────────────────────

(:test)
function testXyzHourInRange(logger) {
    var h = new SimpleWatchView().computeTimeData()[:xyz_hour];
    Test.assertMessage(h >= 0.0 && h < 1.0 + 0.001,
        "xyz_hour must be in [0.0, 1.0), got: " + h);
    return true;
}

// ─── Battery — [0.0, 1.0] ────────────────────────────────────────────────────

(:test)
function testBatteryFractionInRange(logger) {
    var b = new SimpleWatchView().computeTimeData()[:battery];
    Test.assertMessage(b != null, "battery must not be null");
    Test.assertMessage(b >= 0.0 && b <= 1.0,
        "battery must be in [0.0, 1.0], got: " + b);
    return true;
}

// ─── stepsPercent — non-negative ─────────────────────────────────────────────

(:test)
function testStepsPercentNonNegative(logger) {
    var s = new SimpleWatchView().computeTimeData()[:stepsPercent];
    Test.assertMessage(s != null, "stepsPercent must not be null");
    Test.assertMessage(s >= 0.0,
        "stepsPercent must be >= 0.0, got: " + s);
    return true;
}

// ─── color_sec — COLOR_GREEN (goal met) or COLOR_BLUE (not met) ───────────────

(:test)
function testColorSecIsGreenOrBlue(logger) {
    var c = new SimpleWatchView().computeTimeData()[:color_sec];
    Test.assertMessage(c == Gfx.COLOR_GREEN || c == Gfx.COLOR_BLUE,
        "color_sec must be COLOR_GREEN or COLOR_BLUE, got: " + c);
    return true;
}

(:test)
function testColorSecInvariantWithSteps(logger) {
    var data = new SimpleWatchView().computeTimeData();
    var s    = data[:stepsPercent];
    var c    = data[:color_sec];
    if (s >= 1.0) {
        Test.assertEqualMessage(c, Gfx.COLOR_GREEN,
            "color_sec must be green when goal is met");
    } else {
        Test.assertEqualMessage(c, Gfx.COLOR_BLUE,
            "color_sec must be blue when goal is not met");
    }
    return true;
}

// ─── dayDate — [1, 31] ───────────────────────────────────────────────────────

(:test)
function testDayDateInRange(logger) {
    var d = new SimpleWatchView().computeTimeData()[:dayDate];
    Test.assertMessage(d >= 1 && d <= 31,
        "dayDate must be in [1, 31], got: " + d);
    return true;
}

// ─── Angle formula verification (pure math, time-independent) ─────────────────

(:test)
function testMinuteAngleAt0Min(logger) {
    // min=0  →  0/60 * 2π - π/2 = -π/2
    var view     = new SimpleWatchView();
    var expected = -(Math.PI / 2.0);
    var actual   = (0.0 / 60.0) * view.TWO_PI - view.ANGLE_ADJUST;
    Test.assertMessage((actual - expected).abs() < 0.0001,
        "Angle formula at 0 min must yield -π/2");
    return true;
}

(:test)
function testMinuteAngleAt30Min(logger) {
    // min=30  →  0.5 * 2π - π/2 = π - π/2 = π/2
    var view     = new SimpleWatchView();
    var expected = Math.PI / 2.0;
    var actual   = (30.0 / 60.0) * view.TWO_PI - view.ANGLE_ADJUST;
    Test.assertMessage((actual - expected).abs() < 0.0001,
        "Angle formula at 30 min must yield π/2");
    return true;
}

(:test)
function testHourAngleAt12h00m(logger) {
    // 12:00  →  ((0%12 + 0/60) / 12) * 2π - π/2 = -π/2
    var view     = new SimpleWatchView();
    var expected = -(Math.PI / 2.0);
    var actual   = ((0 % 12 + 0.0 / 60.0) / 12.0) * view.TWO_PI - view.ANGLE_ADJUST;
    Test.assertMessage((actual - expected).abs() < 0.0001,
        "Hour angle at 12:00 must yield -π/2");
    return true;
}

(:test)
function testHourAngleAt3h00m(logger) {
    // 3:00  →  (3/12) * 2π - π/2 = π/2 - π/2 = 0
    var view     = new SimpleWatchView();
    var actual   = ((3 % 12 + 0.0 / 60.0) / 12.0) * view.TWO_PI - view.ANGLE_ADJUST;
    Test.assertMessage(actual.abs() < 0.0001,
        "Hour angle at 3:00 must yield 0.0");
    return true;
}

(:test)
function testHourAngleAt6h00m(logger) {
    // 6:00  →  (6/12) * 2π - π/2 = π/2
    var view     = new SimpleWatchView();
    var expected = Math.PI / 2.0;
    var actual   = ((6 % 12 + 0.0 / 60.0) / 12.0) * view.TWO_PI - view.ANGLE_ADJUST;
    Test.assertMessage((actual - expected).abs() < 0.0001,
        "Hour angle at 6:00 must yield π/2");
    return true;
}

(:test)
function testHourAngleAt9h00m(logger) {
    // 9:00  →  (9/12) * 2π - π/2 = 3π/2 - π/2 = π
    var view     = new SimpleWatchView();
    var expected = Math.PI;
    var actual   = ((9 % 12 + 0.0 / 60.0) / 12.0) * view.TWO_PI - view.ANGLE_ADJUST;
    Test.assertMessage((actual - expected).abs() < 0.0001,
        "Hour angle at 9:00 must yield π");
    return true;
}
