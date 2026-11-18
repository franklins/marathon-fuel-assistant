using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Attention;

class MarathonFuelView extends WatchUi.DataField {
    hidden var _cues;
    hidden var _elapsed;
    hidden var _distance;
    hidden var _primed;
    hidden var _lastTimer;
    hidden var _lastDistance;
    hidden var _alertLabel;
    hidden var _alertUntil;
    hidden var _testMode;
    hidden var _vibrate;
    hidden var _hasDistance;
    hidden var _planStamp;

    function initialize() {
        DataField.initialize();
        _cues = [];
        _elapsed = 0;
        _distance = 0;
        _primed = false;
        _lastTimer = 0;
        _lastDistance = 0;
        _alertLabel = null;
        _alertUntil = 0;
        _hasDistance = false;
        _planStamp = -1;
        loadSettings();
    }

    function onLayout(dc) {
        View.onLayout(dc);
    }

    function compute(info) {
        var app = Application.getApp();
        if (app.planStamp != _planStamp) {
            loadSettings();
            _planStamp = app.planStamp;
            _primed = false;
        }

        if (info == null || info.timerTime == null) {
            return;
        }

        var timer = info.timerTime;
        if (timer < _lastTimer) {
            _primed = false;
            loadSettings();
        }
        _lastTimer = timer;
        _elapsed = timer / 1000;

        if (info.elapsedDistance == null) {
            _hasDistance = false;
        } else {
            var distance = info.elapsedDistance;
            if (distance < _lastDistance) {
                _primed = false;
                loadSettings();
            }
            _lastDistance = distance;
            _distance = distance;
            _hasDistance = true;
        }

        if (!_primed) {
            markPastCues();
            _primed = true;
            return;
        }

        checkCues();
    }

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        if (_alertLabel != null && _elapsed < _alertUntil) {
            drawTake(dc, width, height);
            return;
        }

        var bg = getBackgroundColor();
        var fg = Graphics.COLOR_BLACK;
        if (bg == Graphics.COLOR_BLACK) {
            fg = Graphics.COLOR_WHITE;
        }

        dc.setColor(fg, bg);
        dc.clear();

        var next = nextCue();

        if (height < 70) {
            drawCompact(dc, width, height, fg, next);
            return;
        }

        dc.drawText(width / 2, 6, Graphics.FONT_XTINY, "NEXT FUEL", Graphics.TEXT_JUSTIFY_CENTER);
        if (next != null && next[:miles] && !_hasDistance) {
            dc.drawText(width / 2, height / 2, Graphics.FONT_SMALL, "Waiting GPS", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }
        if (next == null) {
            dc.drawText(width / 2, height / 2, Graphics.FONT_SMALL, "Plan done", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(width / 2, height - 22, Graphics.FONT_XTINY, formatProgress(), Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        dc.drawText(width / 2, height / 2 - 10, Graphics.FONT_MEDIUM, next[:label], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(width / 2, height - 28, Graphics.FONT_SMALL, "in " + formatRemain(next), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, height - 12, Graphics.FONT_XTINY, formatProgress() + (_testMode ? "  TEST" : ""), Graphics.TEXT_JUSTIFY_CENTER);
    }

    hidden function drawTake(dc, width, height) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_DK_GREEN);
        dc.clear();
        dc.drawText(width / 2, height / 2 - 18, Graphics.FONT_SMALL, "TAKE", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, height / 2 + 8, Graphics.FONT_MEDIUM, _alertLabel, Graphics.TEXT_JUSTIFY_CENTER);
    }

    hidden function drawCompact(dc, width, height, fg, next) {
        if (_alertLabel != null && _elapsed < _alertUntil) {
            drawTake(dc, width, height);
            return;
        }
        if (next != null && next[:miles] && !_hasDistance) {
            dc.drawText(width / 2, height / 2, Graphics.FONT_XTINY, "GPS", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }
        if (next == null) {
            dc.drawText(width / 2, height / 2, Graphics.FONT_SMALL, "Done", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }
        dc.drawText(width / 2, height / 2 - 8, Graphics.FONT_SMALL, next[:label], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(width / 2, height / 2 + 12, Graphics.FONT_XTINY, formatRemain(next), Graphics.TEXT_JUSTIFY_CENTER);
    }

    hidden function loadSettings() {
        _testMode = boolProp("testMode", false);
        _vibrate = boolProp("vibrate", true);
        _cues = [];
        for (var i = 0; i < FuelPlan.CUE_COUNT; i += 1) {
            addCue(FuelPlan.cueText(i), FuelPlan.isCueMiles(i));
        }
        _primed = false;
    }

    hidden function addCue(text, useMiles) {
        var cue = parseCue(text, _testMode, useMiles);
        if (cue != null) {
            _cues.add(cue);
        }
    }

    hidden function cueDue(cue) {
        if (cue[:miles]) {
            return _hasDistance && _distance >= cue[:at];
        }
        return _elapsed >= cue[:at];
    }

    hidden function markPastCues() {
        for (var i = 0; i < _cues.size(); i += 1) {
            if (cueDue(_cues[i])) {
                _cues[i][:fired] = true;
            }
        }
    }

    hidden function checkCues() {
        for (var i = 0; i < _cues.size(); i += 1) {
            var cue = _cues[i];
            if (!cue[:fired] && cueDue(cue)) {
                cue[:fired] = true;
                fireCue(cue[:label]);
            }
        }
    }

    hidden function etaSeconds(cue) {
        if (cue[:miles]) {
            if (!_hasDistance) {
                return 2000000;
            }
            var metersLeft = cue[:at] - _distance;
            if (metersLeft < 0) {
                metersLeft = 0;
            }
            if (_elapsed >= 15 && _distance > 30) {
                return metersLeft / (_distance / _elapsed.toFloat());
            }
            return 1000000 + metersLeft;
        }
        var secondsLeft = cue[:at] - _elapsed;
        if (secondsLeft < 0) {
            secondsLeft = 0;
        }
        return secondsLeft;
    }

    hidden function nextCue() {
        var best = null;
        var bestEta = 0;
        for (var i = 0; i < _cues.size(); i += 1) {
            if (_cues[i][:fired]) {
                continue;
            }
            var eta = etaSeconds(_cues[i]);
            if (best == null || eta < bestEta) {
                best = _cues[i];
                bestEta = eta;
            }
        }
        return best;
    }

    hidden function fireCue(label) {
        _alertLabel = label;
        _alertUntil = _elapsed + 10;
        if (_vibrate && Attention has :vibrate) {
            Attention.vibrate([ new Attention.VibeProfile(100, 1500) ]);
        }
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_ALERT_HI);
        }
        if (WatchUi.DataField has :showAlert) {
            try {
                WatchUi.DataField.showAlert(new FuelAlert(label));
            } catch (ex) {
            }
        }
    }

    hidden function formatRemain(cue) {
        if (cue[:miles]) {
            var remain = cue[:at] - _distance;
            if (remain < 0) {
                remain = 0;
            }
            return formatMiles(remain) + " mi";
        }
        var remainTime = cue[:at] - _elapsed;
        if (remainTime < 0) {
            remainTime = 0;
        }
        return formatClock(remainTime);
    }

    hidden function formatProgress() {
        var clock = formatClock(_elapsed);
        if (_hasDistance) {
            return clock + "  " + formatMiles(_distance) + " mi";
        }
        return clock;
    }

    hidden function boolProp(key, fallback) {
        var value = readProp(key);
        if (value instanceof Lang.Boolean) {
            return value;
        }
        return fallback;
    }

    hidden function readProp(key) {
        return Application.getApp().getProperty(key);
    }
}

function parseCue(text, testMode, useMiles) {
    if (text == null) {
        return null;
    }
    var line = trimText(text);
    if (line.length() == 0) {
        return null;
    }

    var split = line.find(" ");
    var mark = line;
    var label = "Fuel";
    if (split != null) {
        mark = line.substring(0, split);
        label = trimText(line.substring(split + 1, line.length()));
        if (label.length() == 0) {
            label = "Fuel";
        }
    }

    var at = null;
    if (useMiles) {
        at = parseMiles(mark, testMode);
    } else {
        at = parseClock(mark, testMode);
    }
    if (at == null || at < 0) {
        return null;
    }
    return { :at => at, :label => label, :fired => false, :miles => useMiles };
}

function parseMiles(text, testMode) {
    var miles = text.toFloat();
    if (miles == null) {
        return null;
    }
    if (testMode) {
        miles = miles / 10.0;
    }
    return miles * FuelPlan.METERS_PER_MILE;
}

function parseClock(text, testMode) {
    var parts = splitColon(text);
    if (parts.size() == 0) {
        return null;
    }
    if (parts.size() == 1) {
        var n = toInt(parts[0]);
        if (n == null) {
            return null;
        }
        return testMode ? n : n * 60;
    }
    if (parts.size() == 2) {
        var a = toInt(parts[0]);
        var b = toInt(parts[1]);
        if (a == null || b == null) {
            return null;
        }
        if (testMode) {
            return a * 60 + b;
        }
        return a * 3600 + b * 60;
    }
    if (parts.size() >= 3) {
        var h = toInt(parts[0]);
        var m = toInt(parts[1]);
        var s = toInt(parts[2]);
        if (h == null || m == null || s == null) {
            return null;
        }
        return h * 3600 + m * 60 + s;
    }
    return null;
}

function splitColon(text) {
    var parts = [];
    var start = 0;
    var i = 0;
    while (i < text.length()) {
        if (text.substring(i, i + 1).equals(":")) {
            parts.add(text.substring(start, i));
            start = i + 1;
        }
        i += 1;
    }
    parts.add(text.substring(start, text.length()));
    return parts;
}

function toInt(text) {
    var n = text.toNumber();
    return n;
}

function trimText(text) {
    var start = 0;
    var end = text.length();
    while (start < end && text.substring(start, start + 1).equals(" ")) {
        start += 1;
    }
    while (end > start && text.substring(end - 1, end).equals(" ")) {
        end -= 1;
    }
    return text.substring(start, end);
}

function formatClock(seconds) {
    seconds = seconds.toNumber();
    if (seconds < 0) {
        seconds = 0;
    }
    var h = seconds / 3600;
    var m = (seconds % 3600) / 60;
    var s = seconds % 60;
    if (h > 0) {
        return h + ":" + two(m) + ":" + two(s);
    }
    return m + ":" + two(s);
}

function formatMiles(meters) {
    var miles = meters / FuelPlan.METERS_PER_MILE;
    if (miles < 0) {
        miles = 0;
    }
    var tenths = (miles * 10).toNumber();
    var whole = tenths / 10;
    var frac = tenths % 10;
    return whole + "." + frac;
}

function two(n) {
    if (n < 10) {
        return "0" + n;
    }
    return n.toString();
}
