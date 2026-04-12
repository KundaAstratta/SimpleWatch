using Toybox.Test as Test;
using Toybox.Graphics as Gfx;

// ─── darkenColor ─────────────────────────────────────────────────────────────
// 40 % brightness per channel: channel * 2 / 5  (Monkey C integer division)

(:test)
function testDarkenColorWhite(logger) {
    // 255 * 2 / 5 = 102 = 0x66 on every channel  →  0x666666
    var view = new SimpleWatchView();
    Test.assertEqualMessage(view.darkenColor(0xFFFFFF), 0x666666,
        "darkenColor(white) should be 0x666666");
    return true;
}

(:test)
function testDarkenColorRed(logger) {
    // r=102, g=0, b=0  →  0x660000
    var view = new SimpleWatchView();
    Test.assertEqualMessage(view.darkenColor(0xFF0000), 0x660000,
        "darkenColor(red) should be 0x660000");
    return true;
}

(:test)
function testDarkenColorGreen(logger) {
    var view = new SimpleWatchView();
    Test.assertEqualMessage(view.darkenColor(0x00FF00), 0x006600,
        "darkenColor(green) should be 0x006600");
    return true;
}

(:test)
function testDarkenColorBlue(logger) {
    var view = new SimpleWatchView();
    Test.assertEqualMessage(view.darkenColor(0x0000FF), 0x000066,
        "darkenColor(blue) should be 0x000066");
    return true;
}

(:test)
function testDarkenColorBlack(logger) {
    var view = new SimpleWatchView();
    Test.assertEqualMessage(view.darkenColor(0x000000), 0x000000,
        "darkenColor(black) should stay 0x000000");
    return true;
}

(:test)
function testDarkenColorCyan(logger) {
    // r=0, g=102, b=102  →  0x006666
    var view = new SimpleWatchView();
    Test.assertEqualMessage(view.darkenColor(0x00FFFF), 0x006666,
        "darkenColor(cyan) should be 0x006666");
    return true;
}

(:test)
function testDarkenTwiceOnBlack(logger) {
    var view = new SimpleWatchView();
    Test.assertEqualMessage(view.darkenColor(view.darkenColor(0x000000)), 0x000000,
        "darkenColor applied twice on black should still be black");
    return true;
}

(:test)
function testDarkenTwiceWhite(logger) {
    // 0x666666 → 102*2/5=40=0x28 on every channel  →  0x282828
    var view = new SimpleWatchView();
    Test.assertEqualMessage(view.darkenColor(view.darkenColor(0xFFFFFF)), 0x282828,
        "darkenColor applied twice on white should be 0x282828");
    return true;
}

// ─── lightenColor ─────────────────────────────────────────────────────────────
// Blends 2/3 toward 255: channel + (255 - channel) * 2 / 3

(:test)
function testLightenColorBlack(logger) {
    // 0 + 255*2/3 = 510/3 = 170 = 0xAA on every channel  →  0xAAAAAA
    var view = new SimpleWatchView();
    Test.assertEqualMessage(view.lightenColor(0x000000), 0xAAAAAA,
        "lightenColor(black) should be 0xAAAAAA");
    return true;
}

(:test)
function testLightenColorWhite(logger) {
    var view = new SimpleWatchView();
    Test.assertEqualMessage(view.lightenColor(0xFFFFFF), 0xFFFFFF,
        "lightenColor(white) should stay 0xFFFFFF");
    return true;
}

(:test)
function testLightenColorRed(logger) {
    // r=255+0=255, g=0+170=170, b=170  →  0xFFAAAA
    var view = new SimpleWatchView();
    Test.assertEqualMessage(view.lightenColor(0xFF0000), 0xFFAAAA,
        "lightenColor(red) should be 0xFFAAAA");
    return true;
}

(:test)
function testLightenColorBlue(logger) {
    // r=170, g=170, b=255  →  0xAAAAFF
    var view = new SimpleWatchView();
    Test.assertEqualMessage(view.lightenColor(0x0000FF), 0xAAAAFF,
        "lightenColor(blue) should be 0xAAAAFF");
    return true;
}

(:test)
function testLightenDarkenRoundTrip(logger) {
    var view = new SimpleWatchView();
    var dark = view.darkenColor(0xFFFFFF);   // 0x666666
    var lit  = view.lightenColor(dark);
    Test.assertMessage(lit > dark,
        "lightenColor(darkenColor(white)) should be brighter than darkened value");
    return true;
}

// ─── returnColor ──────────────────────────────────────────────────────────────

(:test)
function testReturnColor0IsWhite(logger) {
    var view = new SimpleWatchView();
    Test.assertEqualMessage(view.returnColor(0), Gfx.COLOR_WHITE,
        "returnColor(0) should be COLOR_WHITE");
    return true;
}

(:test)
function testReturnColor1IsCyan(logger) {
    var view = new SimpleWatchView();
    Test.assertEqualMessage(view.returnColor(1), 0x00FFFF,
        "returnColor(1) should be Cyan 0x00FFFF");
    return true;
}

(:test)
function testReturnColor2IsBlue(logger) {
    var view = new SimpleWatchView();
    Test.assertEqualMessage(view.returnColor(2), Gfx.COLOR_BLUE,
        "returnColor(2) should be COLOR_BLUE");
    return true;
}

(:test)
function testReturnColor3IsPurple(logger) {
    var view = new SimpleWatchView();
    Test.assertEqualMessage(view.returnColor(3), Gfx.COLOR_PURPLE,
        "returnColor(3) should be COLOR_PURPLE");
    return true;
}

(:test)
function testReturnColor4IsRed(logger) {
    var view = new SimpleWatchView();
    Test.assertEqualMessage(view.returnColor(4), Gfx.COLOR_RED,
        "returnColor(4) should be COLOR_RED");
    return true;
}

(:test)
function testReturnColor5IsOrange(logger) {
    var view = new SimpleWatchView();
    Test.assertEqualMessage(view.returnColor(5), Gfx.COLOR_ORANGE,
        "returnColor(5) should be COLOR_ORANGE");
    return true;
}

(:test)
function testReturnColor6IsGreen(logger) {
    var view = new SimpleWatchView();
    Test.assertEqualMessage(view.returnColor(6), Gfx.COLOR_GREEN,
        "returnColor(6) should be COLOR_GREEN");
    return true;
}

(:test)
function testReturnColor7IsPink(logger) {
    var view = new SimpleWatchView();
    Test.assertEqualMessage(view.returnColor(7), Gfx.COLOR_PINK,
        "returnColor(7) should be COLOR_PINK");
    return true;
}

(:test)
function testReturnColorDefaultIsWhite(logger) {
    var view = new SimpleWatchView();
    Test.assertEqualMessage(view.returnColor(99), Gfx.COLOR_WHITE,
        "returnColor(99) default should be COLOR_WHITE");
    Test.assertEqualMessage(view.returnColor(-1), Gfx.COLOR_WHITE,
        "returnColor(-1) default should be COLOR_WHITE");
    return true;
}

(:test)
function testReturnColorAllNonTransparent(logger) {
    var view = new SimpleWatchView();
    for (var i = 0; i <= 7; i++) {
        Test.assertMessage(view.returnColor(i) != Gfx.COLOR_TRANSPARENT,
            "returnColor(" + i + ") must not be transparent");
    }
    return true;
}

(:test)
function testReturnColorAllDistinct(logger) {
    var view = new SimpleWatchView();
    var seen = new [8];
    for (var i = 0; i < 8; i++) {
        var c = view.returnColor(i);
        for (var j = 0; j < i; j++) {
            Test.assertMessage(c != seen[j],
                "returnColor(" + i + ") duplicates returnColor(" + j + ")");
        }
        seen[i] = c;
    }
    return true;
}
