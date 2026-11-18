using Toybox.Graphics;
using Toybox.WatchUi;

class FuelAlert extends WatchUi.DataFieldAlert {
    hidden var _label;

    function initialize(label) {
        DataFieldAlert.initialize();
        _label = label;
    }

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_DK_GREEN);
        dc.clear();
        dc.drawText(width / 2, height / 2 - 28, Graphics.FONT_SMALL, "TAKE", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, height / 2 + 4, Graphics.FONT_LARGE, _label, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
