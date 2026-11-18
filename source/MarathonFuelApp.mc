using Toybox.Application;
using Toybox.WatchUi;

class MarathonFuelApp extends Application.AppBase {
    var planStamp;

    function initialize() {
        AppBase.initialize();
        planStamp = 0;
    }

    function getInitialView() {
        return [ new MarathonFuelView() ];
    }

    function getSettingsView() {
        return [ new FuelSettingsMenu(), new FuelSettingsDelegate() ];
    }

    function onSettingsChanged() {
        planStamp += 1;
        WatchUi.requestUpdate();
    }
}