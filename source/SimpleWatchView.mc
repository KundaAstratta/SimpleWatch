using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.ActivityMonitor as Act;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Application as App;


class SimpleWatchView extends Ui.WatchFace {
    // Awake state
    var isAwake;
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

        var large_arc = App.getApp().getProperty("LargeArc");

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
        var invers_color = App.getApp().getProperty("InversColor");
        var color_background;
        var color_foreground;
        if (invers_color == 0) {
            color_background = Gfx.COLOR_BLACK;
            color_foreground = Gfx.COLOR_WHITE;
        } else {
            color_background = Gfx.COLOR_WHITE;
            color_foreground = Gfx.COLOR_BLACK;
        }

        var color_arc_out = returnColor(App.getApp().getProperty("ArcColorOut"));
        var color_arc_in  = returnColor(App.getApp().getProperty("ArcColorIn"));

        var color_hand = App.getApp().getProperty("ColorHand");
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
        var minute_angle   = hour_fraction * TWO_PI - ANGLE_ADJUST;
        var hour_angle     = ((hour % 12 + hour_fraction) / 12.0) * TWO_PI - ANGLE_ADJUST;
        var seconde_angle  = sec / 60.0 * TWO_PI - ANGLE_ADJUST;

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
        var dayDate = Calendar.info(Time.now(), Time.FORMAT_LONG).day;

        return {
            :hour_angle    => hour_angle,
            :minute_angle  => minute_angle,
            :seconde_angle => seconde_angle,
            :xyz_min       => min,
            :xyz_hour      => (hour % 12 + hour_fraction) / 12.0,
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

        dc.clear();

        dc.setColor(colors[:color_background], Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, radius * 2);

        dc.setPenWidth(l_circ_back);
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, arc_radius);
        dc.drawCircle(cx, cy, arc_radius * layout[:percent_lit_circ]);
    }

    // Draws the hour (inner) and minute (outer) progress arcs
    function drawTimeArcs(dc, layout, colors, timeData) {
        var cx               = layout[:center_x];
        var cy               = layout[:center_y];
        var arc_radius       = layout[:arc_radius];
        var percent_lit_circ = layout[:percent_lit_circ];
        var l_circ           = layout[:l_circ];

        var color_arc_in  = colors[:color_arc_in];
        var color_arc_out = colors[:color_arc_out];
        var xyz_hour      = timeData[:xyz_hour];
        var xyz_min       = timeData[:xyz_min];

        // Inner arc: hour progress
        dc.setColor(color_arc_in, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy - arc_radius * percent_lit_circ, l_circ * ARC_CAP_RATIO);
        dc.setPenWidth(l_circ);
        dc.drawArc(cx, cy, arc_radius * percent_lit_circ, Gfx.ARC_CLOCKWISE, 90, 90 - 360 * xyz_hour);

        // Outer arc: minute progress
        dc.setColor(color_arc_out, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy - arc_radius, l_circ * ARC_CAP_RATIO);
        dc.setPenWidth(l_circ);
        dc.drawArc(cx, cy, arc_radius, Gfx.ARC_CLOCKWISE, 90, 90 - 360 * xyz_min / 60);
    }

    // Draws the phone-connection icon, notification icon, or date on the right side
    function drawStatusIndicators(dc, layout, colors, timeData) {
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
                dc.drawBitmap(cx + radius * percent_pos_oth, cy, icon);
            } else {
                dc.setColor(battery_color, Gfx.COLOR_TRANSPARENT);
                dc.drawText(cx + radius * percent_pos_dat, cy, Gfx.FONT_SMALL, timeData[:dayDate], Gfx.TEXT_JUSTIFY_CENTER);
            }
        } else {
            var icon = Ui.loadResource(Rez.Drawables.Notconnected);
            if (invers_color == 1) {
                icon = Ui.loadResource(Rez.Drawables.NotconnectedBlack);
            }
            dc.drawBitmap(cx + radius * percent_pos_oth, cy, icon);
        }
    }

    // Draws the steps arc (top half) and battery arc (bottom half)
    function drawProgressArcs(dc, layout, colors, timeData) {
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

        var effective_radius = arc_radius - pos_dec - pos_large;

        if (large_arc == 0) {
            dc.setPenWidth(3);
        } else {
            dc.setPenWidth(l_circ);
        }

        // Steps arc (top half, counter-clockwise)
        var showSteps = App.getApp().getProperty("ShowStepsArc");
        if ((showSteps == 0) or ((showSteps == 2) and (isAwake == true))) {
            dc.setColor(color_sec, Gfx.COLOR_TRANSPARENT);
            if (stepsPercent >= 1.0) {
                dc.drawArc(cx, cy, effective_radius, Gfx.ARC_COUNTER_CLOCKWISE, 0, 180);
            } else if (stepsPercent <= STEPS_MIN_THRESHOLD) {
                dc.drawArc(cx, cy, effective_radius, Gfx.ARC_COUNTER_CLOCKWISE, 0, 1);
            } else {
                dc.drawArc(cx, cy, effective_radius, Gfx.ARC_COUNTER_CLOCKWISE, 0, stepsPercent * 180);
                if ((large_arc == 1) or (large_arc == 2)) {
                    dc.fillCircle(
                        cx + effective_radius * Math.cos(-Math.PI * stepsPercent),
                        cy + effective_radius * Math.sin(-Math.PI * stepsPercent),
                        l_circ * ARC_CAP_RATIO);
                }
            }
        }

        // Battery arc (bottom half, clockwise)
        var showBattery = App.getApp().getProperty("ShowBatteryArc");
        if ((showBattery == 0) or ((showBattery == 2) and (isAwake == true))) {
            dc.setColor(battery_color, Gfx.COLOR_TRANSPARENT);
            dc.drawArc(cx, cy, effective_radius, Gfx.ARC_CLOCKWISE, 0, -180 * battery);
            if ((large_arc == 1) or (large_arc == 2)) {
                dc.fillCircle(
                    cx + effective_radius * Math.cos(Math.PI * battery),
                    cy + effective_radius * Math.sin(Math.PI * battery),
                    l_circ * ARC_CAP_RATIO);
            }
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

        var hand_length = percent_big_circ * radius;
        var hour_length = percent_lit_circ * hand_length;

        // Hour hand
        dc.setColor(color_hand_in, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(HAND_PEN_WIDTH);
        dc.drawLine(cx, cy,
            cx + hour_length * Math.cos(hour_angle),
            cy + hour_length * Math.sin(hour_angle));
        dc.fillCircle(
            cx + hour_length * Math.cos(hour_angle),
            cy + hour_length * Math.sin(hour_angle),
            radius * HAND_TIP_RATIO);
        dc.setColor(color_background, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(
            cx + hour_length * Math.cos(hour_angle),
            cy + hour_length * Math.sin(hour_angle),
            radius * HAND_TIP_INNER_RATIO);

        // Minute hand
        dc.setColor(color_hand_out, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(HAND_PEN_WIDTH);
        dc.drawLine(cx, cy,
            cx + hand_length * Math.cos(minute_angle),
            cy + hand_length * Math.sin(minute_angle));
        dc.fillCircle(
            cx + hand_length * Math.cos(minute_angle),
            cy + hand_length * Math.sin(minute_angle),
            radius * HAND_TIP_RATIO);
        dc.setColor(color_background, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(
            cx + hand_length * Math.cos(minute_angle),
            cy + hand_length * Math.sin(minute_angle),
            radius * HAND_TIP_INNER_RATIO);

        // Center hub
        dc.setColor(color_background, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, radius * CENTER_CIRCLE_RATIO);
        dc.setColor(color_hand_in, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(
            cx + radius * CENTER_CIRCLE_RATIO * Math.cos(hour_angle),
            cy + radius * CENTER_CIRCLE_RATIO * Math.sin(hour_angle),
            radius * HAND_TIP_RATIO);
        dc.setColor(color_hand_out, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(
            cx + radius * CENTER_CIRCLE_RATIO * Math.cos(minute_angle),
            cy + radius * CENTER_CIRCLE_RATIO * Math.sin(minute_angle),
            radius * HAND_TIP_RATIO);

        // Second hand (only when awake to save battery)
        if (isAwake) {
            dc.setColor(color_sec, Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(SECOND_PEN_WIDTH);
            dc.drawLine(cx, cy,
                cx + hand_length * Math.cos(seconde_angle),
                cy + hand_length * Math.sin(seconde_angle));
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

    // Maps a setting index (0-12) to a Garmin color constant
    function returnColor(colorNum) {
        switch(colorNum) {
            case 0:  return Gfx.COLOR_WHITE;
            case 1:  return Gfx.COLOR_LT_GRAY;
            case 2:  return Gfx.COLOR_RED;
            case 3:  return Gfx.COLOR_DK_RED;
            case 4:  return Gfx.COLOR_ORANGE;
            case 5:  return Gfx.COLOR_YELLOW;
            case 6:  return Gfx.COLOR_GREEN;
            case 7:  return Gfx.COLOR_DK_GREEN;
            case 8:  return Gfx.COLOR_BLUE;
            case 9:  return Gfx.COLOR_DK_BLUE;
            case 10: return Gfx.COLOR_PURPLE;
            case 11: return Gfx.COLOR_PINK;
            case 12: return Gfx.COLOR_BLACK;
            default: return Gfx.COLOR_WHITE;
        }
    }

}
