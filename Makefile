APP_NAME = Prayer
BUNDLE   = build/$(APP_NAME).app
INSTALL  = /Applications/$(APP_NAME).app

.PHONY: app run install uninstall dev icon clean cert release render

## Build the release .app bundle into build/
app:
	scripts/build-app.sh release

## Build and launch from build/
run: app
	-pkill -x $(APP_NAME)
	open "$(BUNDLE)"

## Build, copy to /Applications, and launch
install: app
	-pkill -x $(APP_NAME)
	rm -rf "$(INSTALL)"
	cp -R "$(BUNDLE)" "$(INSTALL)"
	open "$(INSTALL)"

uninstall:
	-pkill -x $(APP_NAME)
	rm -rf "$(INSTALL)"

## One-time: create the local signing certificate so updates keep their Location grant
cert:
	scripts/make-signing-cert.sh

## Build, zip, and publish a GitHub release for the version in Packaging/Info.plist
release:
	scripts/release.sh

## Quick iteration without a bundle (no icon, no LSUIElement, no self-update)
dev:
	swift run PrayerNotch

## Render the notch UI (collapsed + expanded) to PNGs in build/render/{ar,en,island}
render:
	swift build
	mkdir -p build/render/ar build/render/en build/render/island
	PRAYER_RENDER_LANG=ar .build/debug/PrayerNotch --render build/render/ar Riyadh SA 24.7136 46.6753 Asia/Riyadh
	PRAYER_RENDER_LANG=en .build/debug/PrayerNotch --render build/render/en Riyadh SA 24.7136 46.6753 Asia/Riyadh
	PRAYER_RENDER_ISLAND=1 PRAYER_RENDER_LANG=en .build/debug/PrayerNotch --render build/render/island Riyadh SA 24.7136 46.6753 Asia/Riyadh

icon:
	scripts/make-icon.sh

clean:
	rm -rf build .build
