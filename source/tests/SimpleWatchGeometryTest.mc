using Toybox.Test as Test;
using Toybox.Math as Math;

// ─── SimpleWatchGeometry — pure math, time-independent, no Dc needed ─────────
// Covers the audit's high-risk formulas: pointer angles, Garmin drawArc
// conversions, arc endpoints (sine sign flip), fraction clamping and the
// star-field LCG reproducibility.

const EPS = 0.0001;

// ─── handAngle: fraction of the dial → screen angle (radians) ────────────────

(:test)
function testHandAngleAt12h(logger) {
    var a = SimpleWatchGeometry.handAngle(0.0);
    Test.assertMessage((a - -(Math.PI / 2.0)).abs() < EPS,
        "handAngle(0) must be -π/2 (12 o'clock), got " + a);
    return true;
}

(:test)
function testHandAngleAt3h(logger) {
    // 3 o'clock → point (cx + r, cy) ⇒ angle 0
    var a = SimpleWatchGeometry.handAngle(0.25);
    Test.assertMessage(a.abs() < EPS,
        "handAngle(0.25) must be 0 (3 o'clock), got " + a);
    return true;
}

(:test)
function testHandAngleAt6h(logger) {
    var a = SimpleWatchGeometry.handAngle(0.5);
    Test.assertMessage((a - Math.PI / 2.0).abs() < EPS,
        "handAngle(0.5) must be π/2 (6 o'clock on a Y-down screen), got " + a);
    return true;
}

(:test)
function testHandAngleAt9h(logger) {
    var a = SimpleWatchGeometry.handAngle(0.75);
    Test.assertMessage((a - Math.PI).abs() < EPS,
        "handAngle(0.75) must be π (9 o'clock), got " + a);
    return true;
}

(:test)
function testHandAngleFullCycle(logger) {
    var a = SimpleWatchGeometry.handAngle(1.0);
    Test.assertMessage((a - 3.0 * Math.PI / 2.0).abs() < EPS,
        "handAngle(1.0) must be 3π/2, got " + a);
    return true;
}

(:test)
function testHandAngleMonotonicIncreasing(logger) {
    // Screen angles increase clockwise across the whole cycle
    var prev = SimpleWatchGeometry.handAngle(0.0);
    var i = 1;
    while (i <= 48) {
        var cur = SimpleWatchGeometry.handAngle(i / 48.0);
        Test.assertMessage(cur > prev,
            "handAngle must be strictly increasing at step " + i);
        prev = cur;
        i++;
    }
    return true;
}

// ─── dialFraction: (hour, minuteFraction) → 12 h dial fraction ──────────────

(:test)
function testDialFractionAtMidnight(logger) {
    var f = SimpleWatchGeometry.dialFraction(0, 0.0);
    Test.assertMessage(f.abs() < EPS, "dialFraction(0, 0) must be 0, got " + f);
    return true;
}

(:test)
function testDialFractionWrapsAtNoon(logger) {
    var f = SimpleWatchGeometry.dialFraction(12, 0.0);
    Test.assertMessage(f.abs() < EPS, "dialFraction(12, 0) must wrap to 0, got " + f);
    return true;
}

(:test)
function testDialFractionWrapsAt23h59(logger) {
    var f = SimpleWatchGeometry.dialFraction(23, 59.0 / 60.0);
    var expected = (11.0 + 59.0 / 60.0) / 12.0;
    Test.assertMessage((f - expected).abs() < EPS,
        "dialFraction(23, 59/60) must equal 11h59/12, got " + f);
    return true;
}

(:test)
function testDialFractionHalfPastSix(logger) {
    var f = SimpleWatchGeometry.dialFraction(6, 0.5);
    Test.assertMessage((f - 6.5 / 12.0).abs() < EPS,
        "dialFraction(6, 0.5) must be 6.5/12, got " + f);
    return true;
}

// ─── progressEndDeg: Garmin drawArc end angle for clockwise from 90° ─────────

(:test)
function testProgressEndDegAtZero(logger) {
    Test.assertEqualMessage(SimpleWatchGeometry.progressEndDeg(0.0), 90.0,
        "progressEndDeg(0) must be 90 (nothing elapsed)");
    return true;
}

(:test)
function testProgressEndDegAtQuarter(logger) {
    Test.assertEqualMessage(SimpleWatchGeometry.progressEndDeg(0.25), 0.0,
        "progressEndDeg(0.25) must be 0 (3 o'clock)");
    return true;
}

(:test)
function testProgressEndDegAtHalf(logger) {
    Test.assertEqualMessage(SimpleWatchGeometry.progressEndDeg(0.5), -90.0,
        "progressEndDeg(0.5) must be -90 (6 o'clock)");
    return true;
}

(:test)
function testProgressEndDegFull(logger) {
    Test.assertEqualMessage(SimpleWatchGeometry.progressEndDeg(1.0), -270.0,
        "progressEndDeg(1) must be -270 (full sweep back to 12)");
    return true;
}

(:test)
function testProgressEndDegMonotonicDecreasing(logger) {
    var prev = SimpleWatchGeometry.progressEndDeg(0.0);
    var i = 1;
    while (i <= 48) {
        var cur = SimpleWatchGeometry.progressEndDeg(i / 48.0);
        Test.assertMessage(cur < prev,
            "progressEndDeg must be strictly decreasing at step " + i);
        prev = cur;
        i++;
    }
    return true;
}

// ─── arcPoint: Garmin degrees → screen point (sine sign flip) ────────────────

(:test)
function testArcPointAtZeroDeg(logger) {
    var p = SimpleWatchGeometry.arcPoint(100, 100, 50.0, 0.0);
    Test.assertMessage(p[0] == 150 && p[1] == 100,
        "deg 0 must be (cx + r, cy), got " + p[0] + "," + p[1]);
    return true;
}

(:test)
function testArcPointAtNinetyDegIsUp(logger) {
    // Garmin 90° = 12 o'clock = UP on screen ⇒ y = cy − r (sign flip, audit C4)
    var p = SimpleWatchGeometry.arcPoint(100, 100, 50.0, 90.0);
    Test.assertMessage(p[0] == 100 && p[1] == 50,
        "deg 90 must be (cx, cy - r), got " + p[0] + "," + p[1]);
    return true;
}

(:test)
function testArcPointAt180Deg(logger) {
    var p = SimpleWatchGeometry.arcPoint(100, 100, 50.0, 180.0);
    Test.assertMessage(p[0] == 50 && p[1] == 100,
        "deg 180 must be (cx - r, cy), got " + p[0] + "," + p[1]);
    return true;
}

(:test)
function testArcPointAtMinusNinetyDegIsDown(logger) {
    var p = SimpleWatchGeometry.arcPoint(100, 100, 50.0, -90.0);
    Test.assertMessage(p[0] == 100 && p[1] == 150,
        "deg -90 must be (cx, cy + r) — downward, got " + p[0] + "," + p[1]);
    return true;
}

(:test)
function testArcPointRoundingEpsilonRobust(logger) {
    // Math.sin(90°) can be 0.99999…: the px() rounding must still give cy − r
    var p = SimpleWatchGeometry.arcPoint(200, 200, 100.0, 90.0);
    Test.assertMessage(p[1] == 100,
        "px() rounding must absorb float epsilon, got y=" + p[1]);
    return true;
}

(:test)
function testArcPointMatchesCapRegression(logger) {
    // Regression of the former manual conversion for arc endpoints:
    // at min=15 the minute arc ends at Garmin 0° ⇒ (cx + r, cy)
    var end = SimpleWatchGeometry.progressEndDeg(15.0 / 60.0);
    var p   = SimpleWatchGeometry.arcPoint(120, 120, 80.0, end);
    Test.assertMessage(p[0] == 200 && p[1] == 120,
        "endpoint of a 15-min arc must be at 3 o'clock, got " + p[0] + "," + p[1]);
    return true;
}

// ─── capFraction: clamp [0, 1] so a cap never detaches (audit C3) ────────────

(:test)
function testCapFractionOverGoalClamped(logger) {
    Test.assertEqualMessage(SimpleWatchGeometry.capFraction(1.2), 1.0,
        "capFraction(1.2) must clamp to 1.0");
    return true;
}

(:test)
function testCapFractionNegativeClamped(logger) {
    Test.assertEqualMessage(SimpleWatchGeometry.capFraction(-0.1), 0.0,
        "capFraction(-0.1) must clamp to 0.0");
    return true;
}

(:test)
function testCapFractionPassThrough(logger) {
    Test.assertEqualMessage(SimpleWatchGeometry.capFraction(0.5), 0.5,
        "capFraction(0.5) is unchanged");
    Test.assertEqualMessage(SimpleWatchGeometry.capFraction(0.0), 0.0,
        "capFraction(0.0) is unchanged");
    Test.assertEqualMessage(SimpleWatchGeometry.capFraction(1.0), 1.0,
        "capFraction(1.0) is unchanged");
    return true;
}

(:test)
function testCapFractionMatchesClampedArcEnd(logger) {
    // steps_drawn clamps the arc end to 180° for percent > 1; the cap fraction
    // must clamp to the same bound so both sit at 9 o'clock (deg 180)
    var percent = 1.35;
    var capP    = SimpleWatchGeometry.capFraction(percent);
    var arcDeg  = 90.0 + capP * 90.0;           // 0→180 CCW steps arc mapping
    Test.assertEqualMessage(arcDeg, 180.0,
        "clamped cap and arc must coincide at 180 Garmin degrees");
    return true;
}

// ─── lcg16: star PRNG — bounds and determinism ───────────────────────────────

(:test)
function testLcg16Deterministic(logger) {
    var a1 = SimpleWatchGeometry.lcg16(1);
    var a2 = SimpleWatchGeometry.lcg16(1);
    Test.assertEqualMessage(a1, a2, "lcg16 must be deterministic");
    return true;
}

(:test)
function testLcg16KnownValue(logger) {
    // 1 * 32749 + 12345 = 45094 (pins the constants against accidental edits)
    Test.assertEqualMessage(SimpleWatchGeometry.lcg16(1), 45094,
        "lcg16(1) must be 45094");
    return true;
}

(:test)
function testLcg16StaysIn16Bits(logger) {
    var seed = 1;
    var i = 0;
    while (i < 1000) {
        seed = SimpleWatchGeometry.lcg16(seed);
        Test.assertMessage(seed >= 0 && seed <= 0xFFFF,
            "lcg16 overflowed 16-bit state: " + seed);
        i++;
    }
    return true;
}

(:test)
function testLcg16PathReproducibleFromSeedOne(logger) {
    // Same 10-step path from the fixed seed ⇒ identical star field every frame
    var s1 = 1; var s2 = 1;
    var i = 0;
    while (i < 10) {
        s1 = SimpleWatchGeometry.lcg16(s1);
        s2 = SimpleWatchGeometry.lcg16(s2);
        Test.assertEqualMessage(s1, s2, "star stream diverged at step " + i);
        i++;
    }
    return true;
}
