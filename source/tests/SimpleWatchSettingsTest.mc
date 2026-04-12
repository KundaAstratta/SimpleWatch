using Toybox.Test as Test;
using Toybox.Graphics as Gfx;
using Toybox.Application.Properties as Properties;

// ─── computeColors() ─────────────────────────────────────────────────────────

(:test)
function testColorsNormalTheme(logger) {
    Properties.setValue("InversColor",  0);
    Properties.setValue("ArcColorOut",  0);
    Properties.setValue("ArcColorIn",   0);
    Properties.setValue("ColorHand",    0);
    var colors = new SimpleWatchView().computeColors();
    Test.assertEqualMessage(colors[:color_background], Gfx.COLOR_BLACK,
        "Normal theme: background should be black");
    Test.assertEqualMessage(colors[:color_foreground], Gfx.COLOR_WHITE,
        "Normal theme: foreground should be white");
    return true;
}

(:test)
function testColorsInvertedTheme(logger) {
    Properties.setValue("InversColor",  1);
    Properties.setValue("ArcColorOut",  0);
    Properties.setValue("ArcColorIn",   0);
    Properties.setValue("ColorHand",    0);
    var colors = new SimpleWatchView().computeColors();
    Test.assertEqualMessage(colors[:color_background], Gfx.COLOR_WHITE,
        "Inverted theme: background should be white");
    Test.assertEqualMessage(colors[:color_foreground], Gfx.COLOR_BLACK,
        "Inverted theme: foreground should be black");
    return true;
}

(:test)
function testHandColorFollowsForegroundNormal(logger) {
    Properties.setValue("InversColor",  0);
    Properties.setValue("ArcColorOut",  1);
    Properties.setValue("ArcColorIn",   2);
    Properties.setValue("ColorHand",    0);
    var colors = new SimpleWatchView().computeColors();
    Test.assertEqualMessage(colors[:color_hand_in],  Gfx.COLOR_WHITE,
        "ColorHand=0 normal: hand_in must equal foreground (white)");
    Test.assertEqualMessage(colors[:color_hand_out], Gfx.COLOR_WHITE,
        "ColorHand=0 normal: hand_out must equal foreground (white)");
    return true;
}

(:test)
function testHandColorFollowsForegroundInverted(logger) {
    Properties.setValue("InversColor",  1);
    Properties.setValue("ArcColorOut",  1);
    Properties.setValue("ArcColorIn",   2);
    Properties.setValue("ColorHand",    0);
    var colors = new SimpleWatchView().computeColors();
    Test.assertEqualMessage(colors[:color_hand_in],  Gfx.COLOR_BLACK,
        "ColorHand=0 inverted: hand_in must equal foreground (black)");
    Test.assertEqualMessage(colors[:color_hand_out], Gfx.COLOR_BLACK,
        "ColorHand=0 inverted: hand_out must equal foreground (black)");
    return true;
}

(:test)
function testHandColorFollowsArcColors(logger) {
    Properties.setValue("InversColor",  0);
    Properties.setValue("ArcColorOut",  1); // cyan
    Properties.setValue("ArcColorIn",   4); // red
    Properties.setValue("ColorHand",    1);
    var colors = new SimpleWatchView().computeColors();
    Test.assertEqualMessage(colors[:color_hand_out], 0x00FFFF,
        "ColorHand=1: hand_out must match arc_out (cyan)");
    Test.assertEqualMessage(colors[:color_hand_in], Gfx.COLOR_RED,
        "ColorHand=1: hand_in must match arc_in (red)");
    return true;
}

(:test)
function testHandColorFollowsArcAllIndices(logger) {
    Properties.setValue("InversColor", 0);
    Properties.setValue("ArcColorIn",  0);
    Properties.setValue("ColorHand",   1);
    var view = new SimpleWatchView();
    for (var i = 0; i <= 7; i++) {
        Properties.setValue("ArcColorOut", i);
        var colors = view.computeColors();
        Test.assertEqualMessage(colors[:color_hand_out], colors[:color_arc_out],
            "ColorHand=1: hand_out must equal arc_out for ArcColorOut=" + i);
    }
    return true;
}

(:test)
function testArcColorOutAllIndices(logger) {
    Properties.setValue("InversColor", 0);
    Properties.setValue("ArcColorIn",  0);
    Properties.setValue("ColorHand",   0);
    var view = new SimpleWatchView();
    for (var i = 0; i <= 7; i++) {
        Properties.setValue("ArcColorOut", i);
        var colors = view.computeColors();
        Test.assertEqualMessage(colors[:color_arc_out], view.returnColor(i),
            "arc_out must match returnColor(" + i + ")");
    }
    return true;
}

(:test)
function testArcColorInAllIndices(logger) {
    Properties.setValue("InversColor",  0);
    Properties.setValue("ArcColorOut",  0);
    Properties.setValue("ColorHand",    0);
    var view = new SimpleWatchView();
    for (var i = 0; i <= 7; i++) {
        Properties.setValue("ArcColorIn", i);
        var colors = view.computeColors();
        Test.assertEqualMessage(colors[:color_arc_in], view.returnColor(i),
            "arc_in must match returnColor(" + i + ")");
    }
    return true;
}

(:test)
function testColorsDictionaryKeys(logger) {
    Properties.setValue("InversColor",  0);
    Properties.setValue("ArcColorOut",  0);
    Properties.setValue("ArcColorIn",   0);
    Properties.setValue("ColorHand",    0);
    var colors = new SimpleWatchView().computeColors();
    var keys = [:color_background, :color_foreground, :color_arc_out,
                :color_arc_in, :color_hand_in, :color_hand_out, :invers_color];
    for (var i = 0; i < keys.size(); i++) {
        Test.assertMessage(colors.hasKey(keys[i]),
            "computeColors() missing key: " + keys[i]);
    }
    return true;
}

(:test)
function testColorsArcNotTransparent(logger) {
    Properties.setValue("InversColor", 0);
    Properties.setValue("ColorHand",   0);
    var view = new SimpleWatchView();
    for (var out = 0; out <= 7; out++) {
        Properties.setValue("ArcColorOut", out);
        for (var inn = 0; inn <= 7; inn++) {
            Properties.setValue("ArcColorIn", inn);
            var colors = view.computeColors();
            Test.assertMessage(colors[:color_arc_out] != Gfx.COLOR_TRANSPARENT,
                "arc_out must not be transparent (out=" + out + ")");
            Test.assertMessage(colors[:color_arc_in] != Gfx.COLOR_TRANSPARENT,
                "arc_in must not be transparent (in=" + inn + ")");
        }
    }
    return true;
}

// ─── Property round-trips ─────────────────────────────────────────────────────

(:test)
function testLargeArcPropertyValues(logger) {
    var valid = [0, 1, 2];
    for (var i = 0; i < valid.size(); i++) {
        Properties.setValue("LargeArc", valid[i]);
        Test.assertEqualMessage(Properties.getValue("LargeArc"), valid[i],
            "LargeArc round-trip failed for " + valid[i]);
    }
    return true;
}

(:test)
function testShowBatteryArcPropertyValues(logger) {
    var valid = [0, 1];
    for (var i = 0; i < valid.size(); i++) {
        Properties.setValue("ShowBatteryArc", valid[i]);
        Test.assertEqualMessage(Properties.getValue("ShowBatteryArc"), valid[i],
            "ShowBatteryArc round-trip failed for " + valid[i]);
    }
    return true;
}

(:test)
function testShowStepsArcPropertyValues(logger) {
    var valid = [0, 1];
    for (var i = 0; i < valid.size(); i++) {
        Properties.setValue("ShowStepsArc", valid[i]);
        Test.assertEqualMessage(Properties.getValue("ShowStepsArc"), valid[i],
            "ShowStepsArc round-trip failed for " + valid[i]);
    }
    return true;
}

(:test)
function testShowBatteryArcValue2IsHidden(logger) {
    // Value 2 ("Show When Awake") has been removed — draw code checks == 0 for
    // visible, so value 2 must be treated as hidden (not 0).
    Properties.setValue("ShowBatteryArc", 2);
    Test.assertMessage(Properties.getValue("ShowBatteryArc") != 0,
        "ShowBatteryArc=2 must not be treated as 'show' (only 0 means show)");
    return true;
}
