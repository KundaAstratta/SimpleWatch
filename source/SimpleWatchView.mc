using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.ActivityMonitor as Act;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Application as App;
using Toybox.Application.Properties as Properties;


class SimpleWatchView extends Ui.WatchFace {
    // Awake state — starts true (watchface launches in awake state per Garmin lifecycle)
    // onEnterSleep() sets it false, onExitSleep() sets it back true
    var isAwake = true;
    // 2 pi
    var TWO_PI = Math.PI * 2;
    // Angle adjust for time hands (start from 12 o'clock)
    var ANGLE_ADJUST = Math.PI / 2.0;

    // Screen size threshold to distinguish small vs large round displays
    var SMALL_SCREEN_WIDTH = 220;

    // Clock hand pen widths
    var HAND_PEN_WIDTH = 7;
    var SECOND_PEN_WIDTH = 2;

    // Hand tip decoration sizes relative to screen radius
    var HAND_TIP_RATIO = 0.04;
    var HAND_TIP_INNER_RATIO = 0.02;
    var CENTER_CIRCLE_RATIO = 0.10;

    // Arc end-cap size relative to arc width
    var ARC_CAP_RATIO = 0.45;

    // Battery level below which the arc turns red
    var BATTERY_CRITICAL_THRESHOLD = 0.20;

    // Minimum step progress ratio before drawing a visible arc
    var STEPS_MIN_THRESHOLD = 0.01;


    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
    }

    // Called when this View is brought to the foreground
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
        var layout   = computeLayout(dc);
        var colors   = computeColors();
        var timeData = computeTimeData();

        drawBackground(dc, layout, colors);
        drawTickMarks(dc, layout, colors);
        drawTimeArcs(dc, layout, colors, timeData);
        drawStatusIndicators(dc, layout, colors, timeData);
        drawProgressArcs(dc, layout, colors, timeData);
        drawHands(dc, layout, colors, timeData);
    }

    // Returns a dictionary of layout parameters adapted to the current device and arc-size setting
    function computeLayout(dc) {
        var center_x = dc.getWidth() / 2;
        var center_y = dc.getHeight() / 2;
        var radius   = center_x;

        var large_arc = Properties.getValue("LargeArc");

        // Default layout values match semi-round devices
        var percent_big_circ = 0.80;
        var percent_lit_circ = 0.70;
        var percent_pos_dat  = 0.25;
        var percent_pos_oth  = 0.15;
        var l_circ_back      = 7;
        var l_circ           = 9;
        var pos_l            = 7;
        var pos_dec          = 6;

        if (System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND) {
            if (System.getDeviceSettings().screenWidth < SMALL_SCREEN_WIDTH) {
                // Small round
                percent_big_circ = 0.90;
                percent_lit_circ = 0.60;
                percent_pos_dat  = 0.20;
                percent_pos_oth  = 0.20;
                l_circ_back      = 10;
                l_circ           = 12;
                pos_l            = 14;
                pos_dec          = 6;
                if (large_arc == 2) {
                    l_circ_back = 15;
                    l_circ      = 15;
                }
            } else {
                // Large round
                percent_big_circ = 0.95;
                percent_lit_circ = 0.65;
                percent_pos_dat  = 0.20;
                percent_pos_oth  = 0.20;
                l_circ_back      = 10;
                l_circ           = 12;
                pos_l            = 14;
                pos_dec          = 6;
                if (large_arc == 2) {
                    percent_big_circ = 0.90;
                    percent_lit_circ = 0.60;
                    l_circ_back      = 15;
                    l_circ           = 17;
                    pos_dec          = 8;
                }
            }
        } else {
            // Semi-round: defaults already set above; only override for Extra Large
            if (large_arc == 2) {
                percent_big_circ = 0.75;
                percent_lit_circ = 0.60;
                percent_pos_dat  = 0.20;
                percent_pos_oth  = 0.05;
                l_circ_back      = 11;
                l_circ           = 14;
                pos_dec          = 9;
            }
        }

        var arc_radius = radius * percent_big_circ;
        var pos_large  = (large_arc == 0) ? 0 : pos_l;

        return {
            :center_x        => center_x,
            :center_y        => center_y,
            :radius          => radius,
            :large_arc       => large_arc,
            :percent_big_circ => percent_big_circ,
            :percent_lit_circ => percent_lit_circ,
            :percent_pos_dat => percent_pos_dat,
            :percent_pos_oth => percent_pos_oth,
            :l_circ_back     => l_circ_back,
            :l_circ          => l_circ,
            :pos_dec         => pos_dec,
            :arc_radius      => arc_radius,
            :pos_large       => pos_large
        };
    }

    // Returns a dictionary of colors derived from theme and user settings
    function computeColors() {
        var invers_color = Properties.getValue("InversColor");
        var color_background;
        var color_foreground;
        if (invers_color == 0) {
            color_background = Gfx.COLOR_BLACK;
            color_foreground = Gfx.COLOR_WHITE;
        } else {
            color_background = Gfx.COLOR_WHITE;
            color_foreground = Gfx.COLOR_BLACK;
        }

        var color_arc_out = returnColor(Properties.getValue("ArcColorOut"));
        var color_arc_in  = returnColor(Properties.getValue("ArcColorIn"));

        var color_hand = Properties.getValue("ColorHand");
        var color_hand_in;
        var color_hand_out;
        if (color_hand == 0) {
            color_hand_in  = color_foreground;
            color_hand_out = color_foreground;
        } else {
            color_hand_in  = color_arc_in;
            color_hand_out = color_arc_out;
        }

        return {
            :invers_color    => invers_color,
            :color_background => color_background,
            :color_foreground => color_foreground,
            :color_arc_out   => color_arc_out,
            :color_arc_in    => color_arc_in,
            :color_hand_in   => color_hand_in,
            :color_hand_out  => color_hand_out
        };
    }

    // Returns a dictionary of current time, activity, and battery values
    function computeTimeData() {
        var now  = Sys.getClockTime();
        var hour = now.hour;
        var min  = now.min;
        var sec  = now.sec;

        var hour_fraction  = min / 60.0;
        // Pure math delegated to SimpleWatchGeometry — unit-tested independently
        // without a Dc or a View instance. Numerically identical to the former
        // inlined formulas (fraction * 2π − π/2).
        var minute_angle   = SimpleWatchGeometry.handAngle(hour_fraction);
        var hour_angle     = SimpleWatchGeometry.handAngle(SimpleWatchGeometry.dialFraction(hour, hour_fraction));
        var seconde_angle  = SimpleWatchGeometry.handAngle(sec / 60.0);

        // Activity data
        var actInfo  = Act.getInfo();
        var stepsMax = actInfo.stepGoal;
        var stepsNow = actInfo.steps;
        var stepsPercent = 0.0;
        if (stepsMax != null and stepsMax > 0 and stepsNow != null) {
            stepsPercent = stepsNow * 1.0 / stepsMax;
        }
        var color_sec = (stepsPercent >= 1.0) ? Gfx.COLOR_GREEN : Gfx.COLOR_BLUE;

        var battery = Sys.getSystemStats().battery / 100.0;
        // FORMAT_SHORT: only the numeric day is needed; FORMAT_LONG allocated
        // a localized dictionary + strings every frame at 1 Hz (audit C9)
        var dayDate = Calendar.info(Time.now(), Time.FORMAT_SHORT).day;

        return {
            :hour_angle    => hour_angle,
            :minute_angle  => minute_angle,
            :seconde_angle => seconde_angle,
            :xyz_min       => min,
            :xyz_hour      => SimpleWatchGeometry.dialFraction(hour, hour_fraction),
            :stepsPercent  => stepsPercent,
            :color_sec     => color_sec,
            :battery       => battery,
            :dayDate       => dayDate
        };
    }

    // Fills the background and draws the two dark guide circles for the arcs
    function drawBackground(dc, layout, colors) {
        var cx          = layout[:center_x];
        var cy          = layout[:center_y];
        var radius      = layout[:radius];
        var arc_radius  = layout[:arc_radius];
        var l_circ_back = layout[:l_circ_back];

        // One full-screen paint: both color slots set so dc.clear() is
        // unambiguous, replacing the former clear() + fillCircle(radius*2)
        // double pass (audit C9)
        // Background always black in sleep — InversColor (white bg) would
        // immediately exceed the AMOLED 10 % luminance limit in ambient mode
        var bg = isAwake ? colors[:color_background] : Gfx.COLOR_BLACK;
        dc.setColor(bg, bg);
        dc.clear();

        if (isAwake) {
            drawConcentricBackground(dc, cx, cy, radius);
            drawStarField(dc, cx, cy, radius);
        }

        // Guide circles: awake only — two full-circumference strokes at
        // l_circ_back width would consume too much of the luminance budget in sleep
        if (isAwake) {
            var inner_r = arc_radius * layout[:percent_lit_circ];
            dc.setPenWidth(l_circ_back);
            dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.drawCircle(cx, cy, arc_radius);
            dc.drawCircle(cx, cy, inner_r);
            // 3D rims: bright inner edge + dim outer shadow
            dc.setPenWidth(1);
            dc.setColor(0x505050, Gfx.COLOR_TRANSPARENT);
            dc.drawCircle(cx, cy, arc_radius - l_circ_back / 2 + 1);
            dc.drawCircle(cx, cy, inner_r - l_circ_back / 2 + 1);
            dc.setColor(0x2a2a2a, Gfx.COLOR_TRANSPARENT);
            dc.drawCircle(cx, cy, arc_radius + l_circ_back / 2);
            dc.drawCircle(cx, cy, inner_r + l_circ_back / 2);
        }
    }

    // Draws a dark navy radial gradient from center (very dark) to edge (dark teal).
    // Each gradient step is a single wide-pen drawCircle ring instead of a
    // stacked full-screen fillCircle: overdraw drops from ~11.5x the
    // framebuffer to ~1.0x — this runs at 1 Hz while awake (audit C2).
    function drawConcentricBackground(dc, cx, cy, radius) {
        var numRings = 30;
        var maxRadius = radius + 10;
        // Integer division is fine: the +2 pen overlap hides banding steps
        var band = maxRadius / numRings;

        var startG = 0x05; var startB = 0x10;
        var endG   = 0x30; var endB   = 0x50;

        // Largest ring first (edge color) down to innermost (start color)
        for (var i = numRings; i >= 1; i--) {
            var ratio = (i - 1).toFloat() / (numRings - 1);
            var g = (startG + (endG - startG) * ratio).toNumber();
            var b = (startB + (endB - startB) * ratio).toNumber();
            dc.setColor((g << 8) | b, Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(band + 2);
            dc.drawCircle(cx, cy, maxRadius * i / numRings);
        }

        // Wide-pen rings leave the central disk uncovered — fill it with the
        // darkest gradient step (same color the innermost ring carries)
        dc.setColor((startG << 8) | startB, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, band);
    }

    // Draws ~60 stars using a deterministic PRNG, clipped to the circular screen.
    // 60 instead of the original 150: only ≈π/4 of candidates fall inside the
    // circle anyway, so visible density drops just ~15 % while fillCircle calls
    // shrink 2.5x at 1 Hz (audit C2).
    function drawStarField(dc, cx, cy, radius) {
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        var numStars = 60;
        var diameter = radius * 2;
        // Explicit frame origin — stays correct even if width != height (audit C6)
        var origin_x = cx - radius;
        var origin_y = cy - radius;
        var seed = 1;

        for (var i = 0; i < numStars; i++) {
            seed = SimpleWatchGeometry.lcg16(seed);
            var x = seed % diameter;
            seed = SimpleWatchGeometry.lcg16(seed);
            var y = seed % diameter;
            seed = SimpleWatchGeometry.lcg16(seed);
            var size = (seed % 10 > 7) ? 2 : 1;

            var dx = x - radius;
            var dy = y - radius;
            if (dx * dx + dy * dy <= radius * radius) {
                dc.fillCircle(origin_x + x, origin_y + y, size);
            }
        }
    }

    // Draws 12 beveled rectangular tick marks (major at 12/3/6/9, minor elsewhere)
    function drawTickMarks(dc, layout, colors) {
        var cx         = layout[:center_x];
        var cy         = layout[:center_y];
        var arc_radius = layout[:arc_radius];
        var l_circ     = layout[:l_circ];
        var fg         = colors[:color_foreground];

        var major_len = (l_circ * 1.8).toNumber();
        var minor_len = (l_circ * 1.0).toNumber();

        for (var i = 0; i < 12; i++) {
            // Sleep mode: only 4 cardinal marks (12/3/6/9) to reduce lit pixels
            if (!isAwake && i % 3 != 0) { continue; }

            var angle   = (i * 30 - 90) * Math.PI / 180.0;
            var isMajor = (i % 3 == 0);
            var len     = isMajor ? major_len : minor_len;
            var cos_a   = Math.cos(angle);
            var sin_a   = Math.sin(angle);
            // 12h marker is wider for distinction
            var half_w  = (i == 0) ? 3.5 : (isMajor ? 2.5 : 1.5);
            var px      = -sin_a;
            var py      = cos_a;

            var outerX = cx + arc_radius * cos_a;
            var outerY = cy + arc_radius * sin_a;
            var innerX = cx + (arc_radius - len) * cos_a;
            var innerY = cy + (arc_radius - len) * sin_a;

            var p1 = [(outerX + half_w * px).toNumber(), (outerY + half_w * py).toNumber()];
            var p2 = [(outerX - half_w * px).toNumber(), (outerY - half_w * py).toNumber()];
            var p3 = [(innerX - half_w * px).toNumber(), (innerY - half_w * py).toNumber()];
            var p4 = [(innerX + half_w * px).toNumber(), (innerY + half_w * py).toNumber()];

            if (isAwake) {
                // Shadow (offset +1,+1)
                dc.setColor(0x111111, Gfx.COLOR_TRANSPARENT);
                dc.fillPolygon([[p1[0]+1, p1[1]+1], [p2[0]+1, p2[1]+1],
                                [p3[0]+1, p3[1]+1], [p4[0]+1, p4[1]+1]]);
            }

            // Main rectangle — brighter in sleep for readability
            dc.setColor(isAwake ? fg : 0x555555, Gfx.COLOR_TRANSPARENT);
            dc.fillPolygon([p1, p2, p3, p4]);

            // Rounded end caps (awake only)
            if (isAwake) {
                dc.fillCircle(outerX.toNumber(), outerY.toNumber(), 1);
                dc.fillCircle(innerX.toNumber(), innerY.toNumber(), 1);
                // Bevel highlight along left edge
                dc.setColor(lightenColor(fg), Gfx.COLOR_TRANSPARENT);
                dc.setPenWidth(1);
                dc.drawLine(p1[0], p1[1], p4[0], p4[1]);
            }
        }

        // Sleep mode: small 12h reference dot so the top of the dial is always clear
        if (!isAwake) {
            dc.setColor(0x888888, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(cx, (cy - arc_radius + major_len / 2).toNumber(), 2);
        }

        // 60 minute graduation dots between main ticks (awake only)
        if (isAwake) {
            dc.setColor(darkenColor(fg), Gfx.COLOR_TRANSPARENT);
            for (var i = 0; i < 60; i++) {
                if (i % 5 == 0) { continue; }
                var a = (i * 6 - 90) * Math.PI / 180.0;
                dc.fillCircle(
                    (cx + arc_radius * Math.cos(a)).toNumber(),
                    (cy + arc_radius * Math.sin(a)).toNumber(),
                    1
                );
            }
        }

        // Lume pip: double-ring Super-LumiNova style at 12h (awake only)
        if (isAwake) {
            var pip_dist  = arc_radius - major_len - l_circ * 0.8;
            var pip_y     = (cy - pip_dist).toNumber();
            var pip_color = colors[:color_arc_out];
            // Outer dim halo ring
            dc.setColor(darkenColor(pip_color), Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawCircle(cx, pip_y, 6);
            // Shadow
            dc.setColor(0x111111, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(cx + 1, pip_y + 1, 3);
            // Main pip
            dc.setColor(pip_color, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(cx, pip_y, 3);
            // Bright inner rim
            dc.setColor(lightenColor(pip_color), Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawCircle(cx, pip_y, 3);
            // Bright outer ring
            dc.setColor(pip_color, Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawCircle(cx, pip_y, 5);
        }
    }

    // Draws the hour (inner) and minute (outer) progress arcs
    function drawTimeArcs(dc, layout, colors, timeData) {
        var cx               = layout[:center_x];
        var cy               = layout[:center_y];
        var arc_radius       = layout[:arc_radius];
        var percent_lit_circ = layout[:percent_lit_circ];
        var l_circ           = layout[:l_circ];
        var l_circ_back      = layout[:l_circ_back];

        var color_arc_in  = colors[:color_arc_in];
        var color_arc_out = colors[:color_arc_out];
        var xyz_hour      = timeData[:xyz_hour];
        var xyz_min       = timeData[:xyz_min];

        var inner_r = (arc_radius * percent_lit_circ).toNumber();
        // Garmin drawArc degrees: 90 = 12 o'clock; clockwise sweep = 90° minus
        // the elapsed dial fraction. Pure formulas live in SimpleWatchGeometry.
        // safeArc() also skips the degenerate start == end case (HH:00:00 —
        // behaviour undefined across devices, audit C5)
        var hour_end_deg = SimpleWatchGeometry.progressEndDeg(xyz_hour);
        var min_end_deg  = SimpleWatchGeometry.progressEndDeg(xyz_min / 60.0);

        var cap_r = (l_circ * ARC_CAP_RATIO).toNumber();

        // Remaining dim track (unelapsed portion) — awake only.
        // In sleep mode these l_circ_back-wide arcs cover most of the circle and
        // would push total luminance over the AMOLED 10 % budget.
        if (isAwake) {
            dc.setPenWidth(l_circ_back);
            dc.setColor(darkenColor(darkenColor(color_arc_in)), Gfx.COLOR_TRANSPARENT);
            safeArc(dc, cx, cy, inner_r, Gfx.ARC_COUNTER_CLOCKWISE, 90, hour_end_deg);
            dc.setColor(darkenColor(darkenColor(color_arc_out)), Gfx.COLOR_TRANSPARENT);
            safeArc(dc, cx, cy, arc_radius.toNumber(), Gfx.ARC_COUNTER_CLOCKWISE, 90, min_end_deg);
        }

        // Inner arc: hour progress
        if (isAwake) {
            dc.setColor(darkenColor(darkenColor(color_arc_in)), Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(l_circ + 6);
            safeArc(dc, cx, cy, inner_r, Gfx.ARC_CLOCKWISE, 90, hour_end_deg);
            dc.setColor(darkenColor(color_arc_in), Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(l_circ + 2);
            safeArc(dc, cx, cy, inner_r, Gfx.ARC_CLOCKWISE, 90, hour_end_deg);
            dc.setColor(color_arc_in, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(cx, cy - inner_r, cap_r);
            dc.setPenWidth(l_circ);
            safeArc(dc, cx, cy, inner_r, Gfx.ARC_CLOCKWISE, 90, hour_end_deg);
            // End cap at the Garmin-degrees endpoint (audit C4 of the maths:
            // the sine sign flip lives in SimpleWatchGeometry.arcPoint)
            var h_end = SimpleWatchGeometry.arcPoint(cx, cy, inner_r, hour_end_deg);
            dc.fillCircle(h_end[0], h_end[1], cap_r);
            dc.setColor(lightenColor(color_arc_in), Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            safeArc(dc, cx, cy, (inner_r - l_circ / 2 + 1).toNumber(), Gfx.ARC_CLOCKWISE, 90, hour_end_deg);
        } else {
            // Sleep: single 1px dim arc, no caps
            dc.setColor(0x1a1a1a, Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            safeArc(dc, cx, cy, inner_r, Gfx.ARC_CLOCKWISE, 90, hour_end_deg);
        }

        // Outer arc: minute progress
        if (isAwake) {
            dc.setColor(darkenColor(darkenColor(color_arc_out)), Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(l_circ + 6);
            safeArc(dc, cx, cy, arc_radius.toNumber(), Gfx.ARC_CLOCKWISE, 90, min_end_deg);
            dc.setColor(darkenColor(color_arc_out), Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(l_circ + 2);
            safeArc(dc, cx, cy, arc_radius.toNumber(), Gfx.ARC_CLOCKWISE, 90, min_end_deg);
            dc.setColor(color_arc_out, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(cx, cy - arc_radius.toNumber(), cap_r);
            dc.setPenWidth(l_circ);
            safeArc(dc, cx, cy, arc_radius.toNumber(), Gfx.ARC_CLOCKWISE, 90, min_end_deg);
            // End cap at the Garmin-degrees endpoint (audit C4 of the maths:
            // the sine sign flip lives in SimpleWatchGeometry.arcPoint)
            var m_end = SimpleWatchGeometry.arcPoint(cx, cy, arc_radius.toNumber(), min_end_deg);
            dc.fillCircle(m_end[0], m_end[1], cap_r);
            dc.setColor(lightenColor(color_arc_out), Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            safeArc(dc, cx, cy, (arc_radius - l_circ / 2 + 1).toNumber(), Gfx.ARC_CLOCKWISE, 90, min_end_deg);
        } else {
            // Sleep: single 1px dim arc, no caps
            dc.setColor(0x1a1a1a, Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            safeArc(dc, cx, cy, arc_radius.toNumber(), Gfx.ARC_CLOCKWISE, 90, min_end_deg);
        }
    }

    // Draws the phone-connection icon, notification icon, or date on the right side
    // Hidden in sleep mode to conserve power and simplify display
    function drawStatusIndicators(dc, layout, colors, timeData) {
        if (!isAwake) { return; }
        var cx              = layout[:center_x];
        var cy              = layout[:center_y];
        var radius          = layout[:radius];
        var percent_pos_dat = layout[:percent_pos_dat];
        var percent_pos_oth = layout[:percent_pos_oth];

        var invers_color     = colors[:invers_color];
        var color_foreground = colors[:color_foreground];
        var battery          = timeData[:battery];
        var battery_color    = (battery < BATTERY_CRITICAL_THRESHOLD) ? Gfx.COLOR_RED : color_foreground;

        if (System.getDeviceSettings().phoneConnected) {
            if (System.getDeviceSettings().notificationCount != 0) {
                var icon = Ui.loadResource(Rez.Drawables.Notification);
                if (invers_color == 1) {
                    icon = Ui.loadResource(Rez.Drawables.NotificationBlack);
                }
                // drawBitmap anchors top-left: shift up half the icon height
                // to center it on the horizontal axis (audit C4)
                dc.drawBitmap((cx + radius * percent_pos_oth).toNumber(),
                              cy - iconHalfHeight(icon), icon);
            } else {
                // Date window: beveled box with date text
                var date_cx = (cx + radius * percent_pos_dat).toNumber();
                var font_h  = dc.getFontHeight(Gfx.FONT_TINY);
                var text_w  = dc.getTextWidthInPixels(timeData[:dayDate].toString(), Gfx.FONT_TINY);
                var dw = text_w + 10; var dh = font_h + 4;
                var dx = date_cx - dw / 2;
                var dy = cy - 2;  // top of box, text draws from here + 2px padding
                // Shadow
                dc.setColor(0x111111, Gfx.COLOR_TRANSPARENT);
                dc.fillRectangle(dx + 2, dy + 2, dw, dh);
                // Dark background
                dc.setColor(0x1a1a2a, Gfx.COLOR_TRANSPARENT);
                dc.fillRectangle(dx, dy, dw, dh);
                // Outer border
                dc.setColor(0x2a2a2a, Gfx.COLOR_TRANSPARENT);
                dc.setPenWidth(1);
                dc.drawRectangle(dx, dy, dw, dh);
                // Inner bevel: bright top and left edges
                dc.setColor(0x505050, Gfx.COLOR_TRANSPARENT);
                dc.drawLine(dx, dy, dx + dw - 1, dy);
                dc.drawLine(dx, dy, dx, dy + dh - 1);
                // Date text, top-aligned inside the box with 2px padding
                dc.setColor(battery_color, Gfx.COLOR_TRANSPARENT);
                dc.drawText(date_cx, dy + 2, Gfx.FONT_TINY, timeData[:dayDate],
                            Gfx.TEXT_JUSTIFY_CENTER);
            }
        } else {
            var icon = Ui.loadResource(Rez.Drawables.Notconnected);
            if (invers_color == 1) {
                icon = Ui.loadResource(Rez.Drawables.NotconnectedBlack);
            }
            // drawBitmap anchors top-left: shift up half the icon height
            // to center it on the horizontal axis (audit C4)
            dc.drawBitmap((cx + radius * percent_pos_oth).toNumber(),
                          cy - iconHalfHeight(icon), icon);
        }
    }

    // Draws the steps arc (top half) and battery arc (bottom half) — skipped in sleep mode
    function drawProgressArcs(dc, layout, colors, timeData) {
        if (!isAwake) { return; }
        var cx         = layout[:center_x];
        var cy         = layout[:center_y];
        var arc_radius = layout[:arc_radius];
        var pos_dec    = layout[:pos_dec];
        var pos_large  = layout[:pos_large];
        var large_arc  = layout[:large_arc];
        var l_circ     = layout[:l_circ];

        var color_foreground = colors[:color_foreground];
        var stepsPercent     = timeData[:stepsPercent];
        var color_sec        = timeData[:color_sec];
        var battery          = timeData[:battery];
        var battery_color    = (battery < BATTERY_CRITICAL_THRESHOLD) ? Gfx.COLOR_RED : color_foreground;

        var effective_radius = (arc_radius - pos_dec - pos_large).toNumber();

        var arc_pen = (large_arc == 0) ? 3 : l_circ;

        // Steps arc (top half, counter-clockwise) — outer glow + shadow + main + highlight
        var showSteps = Properties.getValue("ShowStepsArc");
        if (showSteps == 0) {
            if (stepsPercent > STEPS_MIN_THRESHOLD) {
                var steps_end = (stepsPercent >= 1.0) ? 180 : stepsPercent * 180;
                dc.setColor(darkenColor(darkenColor(color_sec)), Gfx.COLOR_TRANSPARENT);
                dc.setPenWidth(arc_pen + 4);
                safeArc(dc, cx, cy, effective_radius, Gfx.ARC_COUNTER_CLOCKWISE, 0, steps_end);
                dc.setColor(darkenColor(color_sec), Gfx.COLOR_TRANSPARENT);
                dc.setPenWidth(arc_pen + 1);
                safeArc(dc, cx, cy, effective_radius, Gfx.ARC_COUNTER_CLOCKWISE, 0, steps_end);
                dc.setColor(color_sec, Gfx.COLOR_TRANSPARENT);
                dc.setPenWidth(arc_pen);
                safeArc(dc, cx, cy, effective_radius, Gfx.ARC_COUNTER_CLOCKWISE, 0, steps_end);
                if ((large_arc == 1) or (large_arc == 2)) {
                    // Cap rides on the drawn arc end — steps_end is already
                    // clamped to 180 for stepsPercent > 1.0, so the cap can
                    // never detach from the arc (audit C3)
                    var s_cap = SimpleWatchGeometry.arcPoint(cx, cy, effective_radius, steps_end);
                    dc.fillCircle(s_cap[0], s_cap[1], (l_circ * ARC_CAP_RATIO).toNumber());
                }
                dc.setColor(lightenColor(color_sec), Gfx.COLOR_TRANSPARENT);
                dc.setPenWidth(1);
                safeArc(dc, cx, cy, effective_radius - arc_pen / 2 + 1, Gfx.ARC_COUNTER_CLOCKWISE, 0, steps_end);
            } else {
                dc.setColor(color_sec, Gfx.COLOR_TRANSPARENT);
                dc.setPenWidth(arc_pen);
                safeArc(dc, cx, cy, effective_radius, Gfx.ARC_COUNTER_CLOCKWISE, 0, 1);
            }
        }

        // Battery arc (bottom half, clockwise) — outer glow + shadow + main + highlight
        var showBattery = Properties.getValue("ShowBatteryArc");
        if (showBattery == 0) {
            dc.setColor(darkenColor(darkenColor(battery_color)), Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(arc_pen + 4);
            safeArc(dc, cx, cy, effective_radius, Gfx.ARC_CLOCKWISE, 0, -180 * battery);
            dc.setColor(darkenColor(battery_color), Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(arc_pen + 1);
            safeArc(dc, cx, cy, effective_radius, Gfx.ARC_CLOCKWISE, 0, -180 * battery);
            dc.setColor(battery_color, Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(arc_pen);
            safeArc(dc, cx, cy, effective_radius, Gfx.ARC_CLOCKWISE, 0, -180 * battery);
            if ((large_arc == 1) or (large_arc == 2)) {
                // battery ∈ [0, 1] ⇒ end ∈ [−180, 0], cap stays on the arc
                var b_cap = SimpleWatchGeometry.arcPoint(cx, cy, effective_radius, -180 * battery);
                dc.fillCircle(b_cap[0], b_cap[1], (l_circ * ARC_CAP_RATIO).toNumber());
            }
            dc.setColor(lightenColor(battery_color), Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            safeArc(dc, cx, cy, effective_radius - arc_pen / 2 + 1, Gfx.ARC_CLOCKWISE, 0, -180 * battery);
        }
    }

    // Draws hour, minute, and (when awake) second hands
    function drawHands(dc, layout, colors, timeData) {
        var cx               = layout[:center_x];
        var cy               = layout[:center_y];
        var radius           = layout[:radius];
        var percent_big_circ = layout[:percent_big_circ];
        var percent_lit_circ = layout[:percent_lit_circ];

        var hour_angle    = timeData[:hour_angle];
        var minute_angle  = timeData[:minute_angle];
        var seconde_angle = timeData[:seconde_angle];
        var color_sec     = timeData[:color_sec];

        var color_background = colors[:color_background];
        var color_hand_in    = colors[:color_hand_in];
        var color_hand_out   = colors[:color_hand_out];
        var color_arc_in     = colors[:color_arc_in];
        var color_arc_out    = colors[:color_arc_out];

        var hand_length = percent_big_circ * radius;
        var hour_length = percent_lit_circ * hand_length;

        // Sleep mode: differentiated slim hands — hour wider/brighter than minute
        if (!isAwake) {
            var h_cos_s = Math.cos(hour_angle);
            var h_sin_s = Math.sin(hour_angle);
            var m_cos_s = Math.cos(minute_angle);
            var m_sin_s = Math.sin(minute_angle);
            // Minute hand: 2px, lighter gray — drawn first so hour overlaps at center
            dc.setPenWidth(2);
            dc.setColor(0x777777, Gfx.COLOR_TRANSPARENT);
            dc.drawLine(
                (cx - hand_length * 0.15 * m_cos_s).toNumber(),
                (cy - hand_length * 0.15 * m_sin_s).toNumber(),
                (cx + hand_length * m_cos_s).toNumber(),
                (cy + hand_length * m_sin_s).toNumber()
            );
            // Hour hand: 3px, lighter gray — visually heavier and brighter
            dc.setPenWidth(3);
            dc.setColor(0x888888, Gfx.COLOR_TRANSPARENT);
            dc.drawLine(
                (cx - hour_length * 0.15 * h_cos_s).toNumber(),
                (cy - hour_length * 0.15 * h_sin_s).toNumber(),
                (cx + hour_length * h_cos_s).toNumber(),
                (cy + hour_length * h_sin_s).toNumber()
            );
            // Center hub: same tone as minute hand
            dc.setColor(0x555555, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(cx, cy, 3);
            return;
        }

        var hour_tail   = hour_length * 0.15;
        var minute_tail = hand_length * 0.15;

        // --- Hour hand: 5-point Dauphine with rectangular counterweight ---
        var h_cos    = Math.cos(hour_angle);
        var h_sin    = Math.sin(hour_angle);
        var h_perp_x = -h_sin;
        var h_perp_y = h_cos;
        var h_pivot  = hour_length * 0.40;
        var h_hw     = HAND_PEN_WIDTH / 2.0;  // body half-width
        var h_tw     = 1.8;                    // tail paddle half-width
        var h_tip_x  = (cx + hour_length * h_cos).toNumber();
        var h_tip_y  = (cy + hour_length * h_sin).toNumber();
        var h_tail_x = cx - hour_tail * h_cos;
        var h_tail_y = cy - hour_tail * h_sin;
        var h_piv_x  = cx + h_pivot * h_cos;
        var h_piv_y  = cy + h_pivot * h_sin;
        // 5 points: tail-A, tail-B, pivot-B, tip, pivot-A
        var h_pts = [
            [(h_tail_x + h_tw * h_perp_x).toNumber(), (h_tail_y + h_tw * h_perp_y).toNumber()],
            [(h_tail_x - h_tw * h_perp_x).toNumber(), (h_tail_y - h_tw * h_perp_y).toNumber()],
            [(h_piv_x  - h_hw * h_perp_x).toNumber(), (h_piv_y  - h_hw * h_perp_y).toNumber()],
            [h_tip_x,                                   h_tip_y                                ],
            [(h_piv_x  + h_hw * h_perp_x).toNumber(), (h_piv_y  + h_hw * h_perp_y).toNumber()]
        ];
        if (isAwake) {
            dc.setColor(0x111111, Gfx.COLOR_TRANSPARENT);
            dc.fillPolygon([
                [h_pts[0][0]+1, h_pts[0][1]+1], [h_pts[1][0]+1, h_pts[1][1]+1],
                [h_pts[2][0]+1, h_pts[2][1]+1], [h_pts[3][0]+1, h_pts[3][1]+1],
                [h_pts[4][0]+1, h_pts[4][1]+1]
            ]);
            dc.fillCircle(h_tip_x + 1, h_tip_y + 1, (radius * HAND_TIP_RATIO + 1).toNumber());
        }
        dc.setColor(color_hand_in, Gfx.COLOR_TRANSPARENT);
        dc.fillPolygon(h_pts);
        dc.fillCircle(h_tip_x, h_tip_y, (radius * HAND_TIP_RATIO).toNumber());
        if (isAwake) {
            dc.setColor(lightenColor(color_hand_in), Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawLine(h_pts[0][0], h_pts[0][1], h_pts[4][0], h_pts[4][1]);
            dc.drawLine(h_pts[4][0], h_pts[4][1], h_tip_x, h_tip_y);
            // Colored center channel
            dc.setColor(color_arc_in, Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawLine(h_tail_x.toNumber(), h_tail_y.toNumber(), h_tip_x, h_tip_y);
        }

        // --- Minute hand: 5-point Dauphine with rectangular counterweight ---
        var m_cos    = Math.cos(minute_angle);
        var m_sin    = Math.sin(minute_angle);
        var m_perp_x = -m_sin;
        var m_perp_y = m_cos;
        var m_pivot  = hand_length * 0.40;
        var m_hw     = HAND_PEN_WIDTH / 2.0;
        var m_tw     = 1.8;
        var m_tip_x  = (cx + hand_length * m_cos).toNumber();
        var m_tip_y  = (cy + hand_length * m_sin).toNumber();
        var m_tail_x = cx - minute_tail * m_cos;
        var m_tail_y = cy - minute_tail * m_sin;
        var m_piv_x  = cx + m_pivot * m_cos;
        var m_piv_y  = cy + m_pivot * m_sin;
        var m_pts = [
            [(m_tail_x + m_tw * m_perp_x).toNumber(), (m_tail_y + m_tw * m_perp_y).toNumber()],
            [(m_tail_x - m_tw * m_perp_x).toNumber(), (m_tail_y - m_tw * m_perp_y).toNumber()],
            [(m_piv_x  - m_hw * m_perp_x).toNumber(), (m_piv_y  - m_hw * m_perp_y).toNumber()],
            [m_tip_x,                                   m_tip_y                                ],
            [(m_piv_x  + m_hw * m_perp_x).toNumber(), (m_piv_y  + m_hw * m_perp_y).toNumber()]
        ];
        if (isAwake) {
            dc.setColor(0x111111, Gfx.COLOR_TRANSPARENT);
            dc.fillPolygon([
                [m_pts[0][0]+1, m_pts[0][1]+1], [m_pts[1][0]+1, m_pts[1][1]+1],
                [m_pts[2][0]+1, m_pts[2][1]+1], [m_pts[3][0]+1, m_pts[3][1]+1],
                [m_pts[4][0]+1, m_pts[4][1]+1]
            ]);
            dc.fillCircle(m_tip_x + 1, m_tip_y + 1, (radius * HAND_TIP_RATIO + 1).toNumber());
        }
        dc.setColor(color_hand_out, Gfx.COLOR_TRANSPARENT);
        dc.fillPolygon(m_pts);
        dc.fillCircle(m_tip_x, m_tip_y, (radius * HAND_TIP_RATIO).toNumber());
        if (isAwake) {
            dc.setColor(lightenColor(color_hand_out), Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawLine(m_pts[0][0], m_pts[0][1], m_pts[4][0], m_pts[4][1]);
            dc.drawLine(m_pts[4][0], m_pts[4][1], m_tip_x, m_tip_y);
            // Colored center channel
            dc.setColor(color_arc_out, Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawLine(m_tail_x.toNumber(), m_tail_y.toNumber(), m_tip_x, m_tip_y);
        }

        // --- Center hub: 3D concentric rings ---
        var hub_r = radius * CENTER_CIRCLE_RATIO;
        dc.setColor(0x111111, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, (hub_r + 2).toNumber());
        dc.setColor(color_hand_out, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, hub_r.toNumber());
        if (isAwake) {
            dc.setColor(lightenColor(color_hand_out), Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            safeArc(dc, cx, cy, (hub_r - 1).toNumber(), Gfx.ARC_CLOCKWISE, 135, 45);
        }
        dc.setColor(color_background, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, (hub_r * 0.65).toNumber());
        dc.setColor(0x111111, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(cx, cy, (hub_r * 0.65).toNumber());
        dc.setColor(color_hand_in, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, (hub_r * 0.25).toNumber());
        if (isAwake) {
            dc.setColor(lightenColor(color_hand_in), Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            safeArc(dc, cx, cy, (hub_r * 0.25 - 1).toNumber(), Gfx.ARC_CLOCKWISE, 135, 45);
        }

        // --- Second hand: lollipop style (awake only) ---
        if (isAwake) {
            var second_tail = hand_length * 0.20;
            var s_cos = Math.cos(seconde_angle);
            var s_sin = Math.sin(seconde_angle);
            var s_tail_x = (cx - second_tail * s_cos).toNumber();
            var s_tail_y = (cy - second_tail * s_sin).toNumber();
            var s_tip_x  = (cx + hand_length * s_cos).toNumber();
            var s_tip_y  = (cy + hand_length * s_sin).toNumber();
            // Shadow
            dc.setColor(darkenColor(color_sec), Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(SECOND_PEN_WIDTH + 1);
            dc.drawLine(s_tail_x, s_tail_y, s_tip_x, s_tip_y);
            // Main needle
            dc.setColor(color_sec, Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(SECOND_PEN_WIDTH);
            dc.drawLine(s_tail_x, s_tail_y, s_tip_x, s_tip_y);
            // Highlight
            dc.setColor(lightenColor(color_sec), Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawLine(s_tail_x, s_tail_y, s_tip_x, s_tip_y);
            // Lollipop counterweight ball
            dc.setColor(0x111111, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(s_tail_x + 1, s_tail_y + 1, 5);
            dc.setColor(color_sec, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(s_tail_x, s_tail_y, 5);
            dc.setColor(lightenColor(color_sec), Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            safeArc(dc, s_tail_x, s_tail_y, 4, Gfx.ARC_CLOCKWISE, 135, 45);
            // Center pip
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(cx, cy, (radius * HAND_TIP_INNER_RATIO).toNumber());
        }
    }

    // Called when this View is removed from the screen
    function onHide() {
    }

    // The user has just looked at their watch
    function onExitSleep() {
        isAwake = true;
        Ui.requestUpdate();
    }

    // Prepare for slow updates (ambient mode)
    function onEnterSleep() {
        isAwake = false;
        Ui.requestUpdate();
    }

    // Returns a darker version of a color (40% brightness)
    function darkenColor(color) {
        var r = ((color >> 16) & 0xFF) * 2 / 5;
        var g = ((color >> 8)  & 0xFF) * 2 / 5;
        var b = ( color        & 0xFF) * 2 / 5;
        return (r << 16) | (g << 8) | b;
    }

    // Returns a lighter version of a color (blended 2/3 toward white; the
    // former comment said 60 %, the code always did 2/3 ≈ 66.7 % — audit C9)
    function lightenColor(color) {
        var r = ((color >> 16) & 0xFF);
        var g = ((color >> 8)  & 0xFF);
        var b = ( color        & 0xFF);
        r = r + (255 - r) * 2 / 3;
        g = g + (255 - g) * 2 / 3;
        b = b + (255 - b) * 2 / 3;
        return (r << 16) | (g << 8) | b;
    }

    // Maps a setting index to a curated 8-color palette (optimised for dark backgrounds)
    function returnColor(colorNum) {
        switch(colorNum) {
            case 0:  return Gfx.COLOR_WHITE;
            case 1:  return 0x00FFFF; // Cyan
            case 2:  return Gfx.COLOR_BLUE;
            case 3:  return Gfx.COLOR_PURPLE;
            case 4:  return Gfx.COLOR_RED;
            case 5:  return Gfx.COLOR_ORANGE;
            case 6:  return Gfx.COLOR_GREEN;
            case 7:  return Gfx.COLOR_PINK;
            default: return Gfx.COLOR_WHITE;
        }
    }

    // Draws an arc with the two guards from the audit:
    //  1. drawArc() only exists since Connect IQ 2.3.0. minApiLevel="2.3.0"
    //     now enforces it for store builds; this runtime guard keeps any
    //     sideloaded build on an older firmware from crashing on a missing
    //     symbol instead of rendering (audit C1).
    //  2. start == end is a degenerate arc whose behaviour is undefined across
    //     devices (full circle vs nothing): skipped explicitly (audit C5).
    function safeArc(dc, x, y, r, clip, start, end) as Void {
        if (!(dc has :drawArc)) { return; }
        if (start == end) { return; }
        dc.drawArc(x, y, r, clip, start, end);
    }

    // Vertical half-height of a loaded bitmap resource, across SDK generations:
    // WatchUi.Bitmap resources expose getDimensions() (API 1.0+), while
    // Graphics.BitmapReference only gained getHeight() at API 4.0 (audit C4).
    function iconHalfHeight(icon) as Lang.Number {
        if (icon has :getDimensions) { return icon.getDimensions()[1] / 2; }
        if (icon has :getHeight)     { return icon.getHeight() / 2; }
        return 0;
    }

}
