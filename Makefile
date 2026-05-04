APP     = Finch.app
BUNDLE  = $(APP)/Contents
BINARY  = $(BUNDLE)/MacOS/Finch

.PHONY: build run clean install test

LSREGISTER = /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister

build:
	swift build -c release 2>&1
	@mkdir -p $(BUNDLE)/MacOS $(BUNDLE)/Resources
	@cp .build/release/Finch $(BINARY)
	@cp Info.plist $(BUNDLE)/Info.plist
	@codesign --deep --force --sign - $(APP)
	@echo "Built $(APP)"

# Open the app and register with Launch Services
run: build
	@pkill -f "Finch.app/Contents/MacOS/Finch" 2>/dev/null || true
	@sleep 0.2
	@$(LSREGISTER) -f $(APP)
	open $(APP)
	@echo "Finch running. Set as default browser in System Settings → Desktop & Dock → Default web browser."

# Test a URL against current config without launching a browser
test: build
	$(BINARY) --test "$(URL)"

clean:
	rm -rf .build $(APP)

# Count source lines
loc:
	@wc -l Sources/Finch/*.swift | tail -1
