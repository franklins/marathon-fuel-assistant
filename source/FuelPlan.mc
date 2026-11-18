using Toybox.Application;
using Toybox.Lang;

module FuelPlan {
    const CUE_COUNT = 10;
    const METERS_PER_MILE = 1609.344;
    const CUE_KEYS = ["cue1", "cue2", "cue3", "cue4", "cue5", "cue6", "cue7", "cue8", "cue9", "cue10"];
    const KIND_KEYS = ["kind1", "kind2", "kind3", "kind4", "kind5", "kind6", "kind7", "kind8", "kind9", "kind10"];
    const MILE_KEYS = ["mile1", "mile2", "mile3", "mile4", "mile5", "mile6", "mile7", "mile8"];
    const TIME_DEFAULTS = [
        "0:20 Maurten 160",
        "0:55 Maurten 100",
        "1:15 Salt tablet",
        "1:40 Maurten 100",
        "2:05 Maurten 160",
        "2:30 Salt tablet",
        "",
        "",
        "",
        ""
    ];
    const MILE_DEFAULTS = [
        "4 Maurten 160",
        "8 Maurten 100",
        "12 Salt tablet",
        "16 Maurten 100",
        "20 Maurten 160",
        "24 Salt tablet",
        "",
        ""
    ];
    const FUELS = [
        "Maurten 160",
        "Maurten 100",
        "Maurten 320",
        "Salt tablet",
        "Gel",
        "Chews",
        "Water",
        "Electrolytes"
    ];

    function isMiles() {
        var value = readValue("cueMode");
        if (value instanceof Lang.Number) {
            return value == 1;
        }
        if (value instanceof Lang.String) {
            return value.equals("1") || value.equals("miles");
        }
        return false;
    }

    function setMiles(enabled) {
        writeValue("cueMode", enabled ? 1 : 0);
        bump();
    }

    function isCueMiles(index) {
        var value = readValue(KIND_KEYS[index]);
        if (value instanceof Lang.Number) {
            if (value == 1) {
                return true;
            }
            if (value == 0) {
                return false;
            }
        }
        return isMiles();
    }

    function setCueMiles(index, miles) {
        writeValue(KIND_KEYS[index], miles ? 1 : 0);
        bump();
    }

    function cueText(index) {
        var text = readString(CUE_KEYS[index], TIME_DEFAULTS[index]);
        if (isCueMiles(index) && trimText(text).length() == 0 && index < MILE_KEYS.size()) {
            var legacy = readString(MILE_KEYS[index], MILE_DEFAULTS[index]);
            if (trimText(legacy).length() > 0) {
                return legacy;
            }
        }
        return text;
    }

    function cueTitle(index) {
        return "Cue " + (index + 1);
    }

    function cueSubtitle(index) {
        var text = trimText(cueText(index));
        if (text.length() == 0) {
            return cueKindLabel(index) + " · Empty";
        }
        return cueKindLabel(index) + " · " + text;
    }

    function cueKindLabel(index) {
        return isCueMiles(index) ? "Miles" : "Time";
    }

    function saveCue(index, mark, label) {
        var line = mark;
        if (label != null && label.length() > 0) {
            line = mark + " " + label;
        }
        writeValue(CUE_KEYS[index], line);
        bump();
    }

    function clearCue(index) {
        writeValue(CUE_KEYS[index], "");
        writeValue(KIND_KEYS[index], -1);
        if (index < MILE_KEYS.size()) {
            writeValue(MILE_KEYS[index], "");
        }
        bump();
    }

    function resetPlan() {
        for (var i = 0; i < CUE_COUNT; i += 1) {
            writeValue(CUE_KEYS[i], TIME_DEFAULTS[i]);
            writeValue(KIND_KEYS[i], -1);
            if (i < MILE_KEYS.size()) {
                writeValue(MILE_KEYS[i], MILE_DEFAULTS[i]);
            }
        }
        bump();
    }

    function splitCue(index) {
        var text = trimText(cueText(index));
        var fallbackMark = isCueMiles(index) ? "4" : "0:20";
        if (text.length() == 0) {
            return { :time => fallbackMark, :label => "Maurten 160" };
        }
        var space = text.find(" ");
        if (space == null) {
            return { :time => text, :label => "Fuel" };
        }
        return {
            :time => text.substring(0, space),
            :label => trimText(text.substring(space + 1, text.length()))
        };
    }

    function formatHm(hours, minutes) {
        return hours + ":" + two(minutes);
    }

    function testMode() {
        return readBool("testMode", false);
    }

    function setTestMode(value) {
        writeValue("testMode", value);
        bump();
    }

    function vibrate() {
        return readBool("vibrate", true);
    }

    function setVibrate(value) {
        writeValue("vibrate", value);
        bump();
    }

    function bump() {
        Application.getApp().onSettingsChanged();
    }

    function readString(key, fallback) {
        var value = readValue(key);
        if (value instanceof Lang.String) {
            return value;
        }
        return fallback;
    }

    function readBool(key, fallback) {
        var value = readValue(key);
        if (value instanceof Lang.Boolean) {
            return value;
        }
        return fallback;
    }

    function readValue(key) {
        return Application.getApp().getProperty(key);
    }

    function writeValue(key, value) {
        Application.getApp().setProperty(key, value);
    }
}
