IOS_VERSION = 26.0
TVOS_VERSION = 26.0
WATCHOS_VERSION = 26.0
VISIONOS_VERSION = 26.0

PLATFORM_IOS = iOS Simulator,id=$(call udid_for,iOS $(IOS_VERSION),iPhone \d\+ Pro [^M])
PLATFORM_MACOS = macOS
PLATFORM_TVOS = tvOS Simulator,id=$(call udid_for,tvOS $(TVOS_VERSION),TV)
PLATFORM_WATCHOS = watchOS Simulator,id=$(call udid_for,watchOS $(WATCHOS_VERSION),Watch)
PLATFORM_VISIONOS = visionOS Simulator,id=$(call udid_for,visionOS $(VISIONOS_VERSION),Vision)

default: test

test: test-macos test-ios test-tvos test-watchos test-visionos

test-macos:
	@echo "Testing macOS..."
	xcodebuild test -scheme Textual -destination platform="$(PLATFORM_MACOS)"

test-ios:
	@echo "Testing iOS $(IOS_VERSION)..."
	xcodebuild test -scheme Textual -destination platform="$(PLATFORM_IOS)"

test-tvos:
	@echo "Testing tvOS $(TVOS_VERSION)..."
	xcodebuild test -scheme Textual -destination platform="$(PLATFORM_TVOS)"

test-watchos:
	@echo "Testing watchOS $(WATCHOS_VERSION)..."
	xcodebuild test -scheme Textual -destination platform="$(PLATFORM_WATCHOS)"

test-visionos:
	@echo "Testing visionOS $(PLATFORM_VISIONOS)..."
	xcodebuild test -scheme Textual -destination platform="$(PLATFORM_VISIONOS)"

format:
	swift format \
		--ignore-unparsable-files \
		--in-place \
		--parallel \
		--recursive \
		./Package.swift ./Package@swift-6.0.swift ./Sources ./Tests ./Examples

bundle-prism:
	@echo "Bundling Prism.js..."
	./Scripts/bundle-prism.sh

build-demo:
	@echo "Building TextualDemo for iOS..."
	xcodebuild build -workspace Textual.xcworkspace -scheme TextualDemo -destination platform="$(PLATFORM_IOS)" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
	@echo "Building TextualDemo for macOS..."
	xcodebuild build -workspace Textual.xcworkspace -scheme TextualDemo -destination platform="$(PLATFORM_MACOS)" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

test-swift-5:
  swift test  -Xswiftc -swift-version -Xswiftc 5

.PHONY: format test bundle-prism build-demo

define udid_for
$(shell xcrun simctl list devices available '$(1)' | grep '$(2)' | sort -r | head -1 | awk -F '[()]' '{ print $$(NF-3) }')
endef
