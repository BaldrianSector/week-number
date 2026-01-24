# week-number-menu-bar
A simple menu bar app that displays current week.

## Run
1. Open the Xcode project: `open WeekNumberMenuBar.xcodeproj`
2. Select the `WeekNumberMenuBar` scheme
3. Run the app

## Release (DMG)
This creates `dist/WeekNumber.dmg` (unsigned).

```
./scripts/build_dmg.sh
```

## Download
The most recent release includes this DMG file:

```
WeekNumber.dmg
```

You can find it attached to the latest GitHub Release for this repo (link below once provided).

## Add to Login Items
1. Open **System Settings** → **General** → **Login Items**.
2. Under **Open at Login**, click **+**.
3. Select `WeekNumber.app` (in your Applications folder) and click **Add**.
