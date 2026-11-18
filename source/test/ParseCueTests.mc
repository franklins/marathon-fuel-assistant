using Toybox.Test;

(:test)
function testTimeCueTwentyMinutes(logger) {
    var cue = parseCue("0:20 Maurten 160", false, false);
    Test.assertEqualMessage(cue[:label], "Maurten 160", "label");
    Test.assertEqualMessage(cue[:at], 20 * 60, "twenty minutes in seconds");
    return true;
}

(:test)
function testTimeCueTestModeSeconds(logger) {
    var cue = parseCue("0:20 Maurten 160", true, false);
    Test.assertEqualMessage(cue[:at], 20, "test mode uses seconds");
    return true;
}

(:test)
function testMileCueFour(logger) {
    var cue = parseCue("4 Maurten 160", false, true);
    var expected = 4 * FuelPlan.METERS_PER_MILE;
    var delta = cue[:at] - expected;
    if (delta < 0) { delta = -delta; }
    Test.assertMessage(delta < 1.0, "four miles in meters");
    return true;
}

(:test)
function testMileCueTestModeTenth(logger) {
    var cue = parseCue("4 Maurten 160", true, true);
    var expected = 0.4 * FuelPlan.METERS_PER_MILE;
    var delta = cue[:at] - expected;
    if (delta < 0) { delta = -delta; }
    Test.assertMessage(delta < 1.0, "test mode uses 0.4 miles");
    return true;
}

(:test)
function testEmptyCueSkipped(logger) {
    Test.assert(parseCue("", false, false) == null);
    Test.assert(parseCue("   ", false, true) == null);
    return true;
}

(:test)
function testMixedCueKinds(logger) {
    var timeCue = parseCue("0:20 Maurten 160", false, false);
    var mileCue = parseCue("4 Maurten 160", false, true);
    Test.assertEqualMessage(timeCue[:miles], false, "time cue is not miles");
    Test.assertEqualMessage(mileCue[:miles], true, "mile cue is miles");
    Test.assertEqualMessage(timeCue[:at], 20 * 60, "time still in seconds");
    return true;
}
