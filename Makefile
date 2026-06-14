IOS_DEVICE = iPhone
TVOS_DEVICE = TV
WATCHOS_DEVICE = Watch
VISIONOS_DEVICE = Vision

IOS_SIMULATOR = $(call udid_for,$(IOS_DEVICE))
TVOS_SIMULATOR = $(call udid_for,$(TVOS_DEVICE))
WATCHOS_SIMULATOR = $(call udid_for,$(WATCHOS_DEVICE))
VISIONOS_SIMULATOR = $(call udid_for,$(VISIONOS_DEVICE))

PLATFORM_IOS = iOS Simulator,id=$(IOS_SIMULATOR)
PLATFORM_MACOS = macOS
PLATFORM_MAC_CATALYST = macOS,variant=Mac Catalyst
PLATFORM_TVOS = tvOS Simulator,id=$(TVOS_SIMULATOR)
PLATFORM_WATCHOS = watchOS Simulator,id=$(WATCHOS_SIMULATOR)
PLATFORM_VISIONOS = visionOS Simulator,id=$(VISIONOS_SIMULATOR)

default: test

test: test-macos test-maccatalyst test-ios test-tvos test-watchos test-visionos

test-macos:
	@echo "Testing macOS..."
	xcodebuild test -scheme Textual -destination platform="$(PLATFORM_MACOS)"

test-maccatalyst:
	@echo "Testing Mac Catalyst..."
	xcodebuild test -scheme Textual -destination platform="$(PLATFORM_MAC_CATALYST)"

test-ios:
	@echo "Testing iOS..."
	$(call require_simulator,$(IOS_SIMULATOR),$(IOS_DEVICE))
	xcodebuild test -scheme Textual -destination platform="$(PLATFORM_IOS)"

test-tvos:
	@echo "Testing tvOS..."
	$(call require_simulator,$(TVOS_SIMULATOR),$(TVOS_DEVICE))
	xcodebuild test -scheme Textual -destination platform="$(PLATFORM_TVOS)"

test-watchos:
	@echo "Testing watchOS..."
	$(call require_simulator,$(WATCHOS_SIMULATOR),$(WATCHOS_DEVICE))
	xcodebuild test -scheme Textual -destination platform="$(PLATFORM_WATCHOS)"

test-visionos:
	@echo "Testing visionOS..."
	$(call require_simulator,$(VISIONOS_SIMULATOR),$(VISIONOS_DEVICE))
	xcodebuild test -scheme Textual -destination platform="$(PLATFORM_VISIONOS)"

format:
	swift format \
		--ignore-unparsable-files \
		--in-place \
		--parallel \
		--recursive \
		./Package.swift ./Sources ./Tests ./Examples

bundle-prism:
	@echo "Bundling Prism.js..."
	./Scripts/bundle-prism.sh

build-demo:
	@echo "Building TextualDemo for iOS..."
	xcodebuild build -workspace Textual.xcworkspace -scheme TextualDemo -destination platform="$(PLATFORM_IOS)" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
	@echo "Building TextualDemo for macOS..."
	xcodebuild build -workspace Textual.xcworkspace -scheme TextualDemo -destination platform="$(PLATFORM_MACOS)" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

.PHONY: format test test-macos test-maccatalyst test-ios test-tvos test-watchos test-visionos bundle-prism build-demo

define udid_for
$(shell xcrun simctl list --json devices available '$(1)' | jq -r '[.devices | to_entries | sort_by(.key) | reverse | .[].value | select(length > 0) | .[0]][0].udid // empty')
endef

define require_simulator
@test "$(1)" != "" || (echo "No available simulator found matching '$(2)'" >&2; exit 1)
endef
