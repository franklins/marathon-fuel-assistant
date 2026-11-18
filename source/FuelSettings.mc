using Toybox.WatchUi;

class FuelSettingsMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => "Fuel plan" });
        rebuild();
    }

    function onShow() {
        rebuild();
    }

    function rebuild() {
        while (getItem(0) != null) {
            deleteItem(0);
        }

        var modeLabel = FuelPlan.isMiles() ? "Miles" : "Time";
        addItem(new WatchUi.MenuItem("Default plan", modeLabel, "mode", null));

        for (var i = 0; i < FuelPlan.CUE_COUNT; i += 1) {
            addItem(new WatchUi.MenuItem(FuelPlan.cueTitle(i), FuelPlan.cueSubtitle(i), i, null));
        }

        addItem(new WatchUi.ToggleMenuItem("Test mode", "Time 0:20=20s, mile 4=0.4", "testMode", FuelPlan.testMode(), null));
        addItem(new WatchUi.ToggleMenuItem("Vibrate", null, "vibrate", FuelPlan.vibrate(), null));
        addItem(new WatchUi.MenuItem("Reset plan", "Restore defaults", "reset", null));
    }
}

class FuelSettingsDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var id = item.getId();
        if (id instanceof Toybox.Lang.Number) {
            WatchUi.pushView(new CueEditMenu(id), new CueEditDelegate(id), WatchUi.SLIDE_LEFT);
            return;
        }
        if (id.equals("mode")) {
            WatchUi.pushView(new ModeMenu(), new ModeDelegate(), WatchUi.SLIDE_LEFT);
            return;
        }
        if (id.equals("testMode")) {
            FuelPlan.setTestMode(item.isEnabled());
            return;
        }
        if (id.equals("vibrate")) {
            FuelPlan.setVibrate(item.isEnabled());
            return;
        }
        if (id.equals("reset")) {
            FuelPlan.resetPlan();
            WatchUi.requestUpdate();
        }
    }
}

class ModeMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => "Default plan" });
        addItem(new WatchUi.MenuItem("Time", "Hours and minutes", 0, null));
        addItem(new WatchUi.MenuItem("Miles", "After mile 4, 8, ...", 1, null));
    }
}

class ModeDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        FuelPlan.setMiles(item.getId() == 1);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class CueEditMenu extends WatchUi.Menu2 {
    hidden var _index;

    function initialize(index) {
        _index = index;
        Menu2.initialize({ :title => FuelPlan.cueTitle(index) });
        addItem(new WatchUi.MenuItem("Type", FuelPlan.cueKindLabel(index), "type", null));
        var markTitle = FuelPlan.isCueMiles(index) ? "Set mile" : "Set time";
        addItem(new WatchUi.MenuItem(markTitle, FuelPlan.splitCue(index)[:time], "mark", null));
        addItem(new WatchUi.MenuItem("Set fuel", FuelPlan.splitCue(index)[:label], "fuel", null));
        addItem(new WatchUi.MenuItem("Clear cue", null, "clear", null));
    }
}

class CueEditDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _index;

    function initialize(index) {
        Menu2InputDelegate.initialize();
        _index = index;
    }

    function onSelect(item) {
        var id = item.getId();
        if (id.equals("type")) {
            WatchUi.pushView(new CueTypeMenu(), new CueTypeDelegate(_index), WatchUi.SLIDE_LEFT);
            return;
        }
        if (id.equals("mark")) {
            if (FuelPlan.isCueMiles(_index)) {
                WatchUi.pushView(new MileMenu(), new MilePickDelegate(_index), WatchUi.SLIDE_LEFT);
            } else {
                WatchUi.pushView(new HourMenu(), new HourDelegate(_index), WatchUi.SLIDE_LEFT);
            }
            return;
        }
        if (id.equals("fuel")) {
            WatchUi.pushView(new FuelMenu(_index), new FuelDelegate(_index), WatchUi.SLIDE_LEFT);
            return;
        }
        if (id.equals("clear")) {
            FuelPlan.clearCue(_index);
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}

class CueTypeMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => "Cue type" });
        addItem(new WatchUi.MenuItem("Time", "Hours and minutes", 0, null));
        addItem(new WatchUi.MenuItem("Miles", "Distance in miles", 1, null));
    }
}

class CueTypeDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _index;

    function initialize(index) {
        Menu2InputDelegate.initialize();
        _index = index;
    }

    function onSelect(item) {
        var miles = item.getId() == 1;
        FuelPlan.setCueMiles(_index, miles);
        var parts = FuelPlan.splitCue(_index);
        var mark = parts[:time];
        if (miles && mark.find(":") != null) {
            mark = "4";
        }
        if (!miles && mark.find(":") == null) {
            mark = "0:20";
        }
        FuelPlan.saveCue(_index, mark, parts[:label]);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class MileMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => "Mile" });
        addItem(new WatchUi.MenuItem("0.1", "test", "0.1", null));
        addItem(new WatchUi.MenuItem("0.2", "test", "0.2", null));
        addItem(new WatchUi.MenuItem("0.5", null, "0.5", null));
        for (var m = 1; m <= 26; m += 1) {
            addItem(new WatchUi.MenuItem("Mile " + m, null, m.toString(), null));
        }
    }
}

class MilePickDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _index;

    function initialize(index) {
        Menu2InputDelegate.initialize();
        _index = index;
    }

    function onSelect(item) {
        var parts = FuelPlan.splitCue(_index);
        FuelPlan.setCueMiles(_index, true);
        FuelPlan.saveCue(_index, item.getId(), parts[:label]);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class HourMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => "Hours" });
        for (var h = 0; h <= 6; h += 1) {
            addItem(new WatchUi.MenuItem(h + " h", null, h, null));
        }
    }
}

class HourDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _index;

    function initialize(index) {
        Menu2InputDelegate.initialize();
        _index = index;
    }

    function onSelect(item) {
        WatchUi.pushView(new MinuteMenu(), new MinuteDelegate(_index, item.getId()), WatchUi.SLIDE_LEFT);
    }
}

class MinuteMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => "Minutes" });
        for (var m = 0; m < 60; m += 5) {
            addItem(new WatchUi.MenuItem(two(m) + " min", null, m, null));
        }
    }
}

class MinuteDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _index;
    hidden var _hours;

    function initialize(index, hours) {
        Menu2InputDelegate.initialize();
        _index = index;
        _hours = hours;
    }

    function onSelect(item) {
        var parts = FuelPlan.splitCue(_index);
        FuelPlan.setCueMiles(_index, false);
        FuelPlan.saveCue(_index, FuelPlan.formatHm(_hours, item.getId()), parts[:label]);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class FuelMenu extends WatchUi.Menu2 {
    function initialize(index) {
        Menu2.initialize({ :title => "Fuel" });
        for (var i = 0; i < FuelPlan.FUELS.size(); i += 1) {
            addItem(new WatchUi.MenuItem(FuelPlan.FUELS[i], null, FuelPlan.FUELS[i], null));
        }
    }
}

class FuelDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _index;

    function initialize(index) {
        Menu2InputDelegate.initialize();
        _index = index;
    }

    function onSelect(item) {
        var parts = FuelPlan.splitCue(_index);
        FuelPlan.saveCue(_index, parts[:time], item.getId());
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
