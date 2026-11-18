# Marathon Fuel

A Garmin Connect IQ data field for the Forerunner 945. During a run it shows the next fuel cue and, when that mark hits, vibrates and turns the field green with TAKE.

You can set up to 10 cues. Each cue can be time or miles, so a time plan can include a mile cue and the other way around.

## Time cue

Hours:minutes from Start.

    0:20 Maurten 160

## Miles cue

Activity distance, in miles.

    4 Maurten 160

## Mixed example

    0:20 Maurten 160
    8 Maurten 100
    1:15 Salt tablet

## Phone settings

Garmin Connect -> devices -> Forerunner 945 -> Activities and apps -> Marathon Fuel.

1. Default plan is Time or Miles for cues that still say Same as Default plan.
2. For any cue, set Cue N type to Time or Miles to override that one slot.
3. Time text is H:MM then a label. Mile text is the mile number then a label, for example 4 Maurten 160.
4. Test mode: time treats 0:20 as 20 seconds; miles treats 4 as 0.4 miles so you can check it on a short jog.

## On the watch

If Connect IQ settings appear under the Run activity, open a cue and set Type to Time or Miles, then Set time or Set mile.

## During the run

Stay on the Marathon Fuel data page. At the cue you get a vibration and TAKE on that field. GPS must be locked before a mile cue can fire. The field shows whichever unfired cue is due soonest (using pace when both time and mile cues are in the plan).

## Build

.\build.ps1 writes bin\MarathonFuel.prg for the Forerunner 945. Copy it to GARMIN\Apps on the watch.

## Store package

.\package.ps1 writes a signed release IQ at store\MarathonFuel.iq (and bin\MarathonFuel.iq) for every product in manifest.xml. Upload that file at https://apps.garmin.com/developer. Keep using the same developer_key.der for later updates. Listing screenshots and description are entered on the store site, not in the IQ file.

The current store file is also in this repo: [store/MarathonFuel.iq](store/MarathonFuel.iq).
