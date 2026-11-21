import Toybox.Lang;
import Toybox.Math;

//! Pure geometry helpers for the SimpleWatch dial — no drawing, no state, no
//! dependency on Toybox.Graphics. Extracted so every formula of the render
//! pipeline can be unit-tested without a Dc or a View instance (audit C10).
//!
//! Coordinate conventions:
//!  - Screen: origin top-left, X right, Y down.
//!  - Hand angles: radians, 0 = 3 o'clock, positive = clockwise. Standard
//!    math formulas on a Y-down screen naturally rotate clockwise.
//!  - Arc angles: Connect IQ "Garmin degrees", as consumed by Dc.drawArc():
//!    0° = 3 o'clock, positive = counter-clockwise on screen.
module SimpleWatchGeometry {

    //! Round-half-up then truncate to Number. Robust against float epsilon —
    //! Math.sin(Math.PI / 2.0) can yield 0.99999…, and plain .toNumber()
    //! truncation turns that into a 1 px coordinate error.
    function px(v) as Number {
        return (v + 0.5).toNumber();
    }

    //! One step of the star-field LCG (16-bit state). Kept here so the star
    //! placement stream is reproducible unit-testably (bounds + determinism).
    function lcg16(seed as Number) as Number {
        return (seed * 32749 + 12345) & 0xFFFF;
    }

    //! Screen angle (radians) of a hand that has covered `fraction` of its
    //! full cycle, starting from 12 o'clock. Verified from first principles:
    //! 3 h → fraction 1/4 → angle 0 → point (cx + r, cy) = right.
    function handAngle(fraction as Float) as Float {
        return fraction * 2.0 * Math.PI - Math.PI / 2.0;
    }

    //! Fraction of the 12 h dial covered by the hour hand.
    //! hour: 0–23 (wraps), minuteFraction: [0, 1).
    function dialFraction(hour as Number, minuteFraction as Float) as Float {
        return (hour % 12 + minuteFraction) / 12.0;
    }

    //! End angle (Garmin degrees) of a progress arc starting at 90 (12 o'clock)
    //! and sweeping clockwise over `fraction` of the full circle.
    //! fraction 1/4 → 0° (3 o'clock) — matches Garmin's clockwise sweep from
    //! 90° down.
    function progressEndDeg(fraction as Float) as Float {
        return 90.0 - fraction * 360.0;
    }

    //! Convert a Garmin drawArc angle (degrees) to a screen point on the circle
    //! (cx, cy, r). Returns [x, y] with px() rounding.
    //! The MINUS sign on the sine is required: Garmin arcs are measured in the
    //! math orientation (Y up) while the screen is Y down. Getting this wrong
    //! mirrors every cap vertically (audit C4 of the maths review).
    function arcPoint(cx, cy, r, deg) as Array {
        var a  = deg * Math.PI / 180.0;
        var rf = r * 1.0;    // accept Number or Float
        return [
            px(cx + rf * Math.cos(a)),
            px(cy - rf * Math.sin(a))
        ];
    }

    //! Fraction clamped to [0, 1] so a decorative cap never detaches from an
    //! arc that is itself clamped (steps beyond goal — audit C3).
    function capFraction(percent as Float) as Float {
        if (percent > 1.0) { return 1.0; }
        if (percent < 0.0) { return 0.0; }
        return percent;
    }
}
