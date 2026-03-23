# Prerequisites: brew install go ffmpeg
# For SpankBar: Xcode 15+ required

.PHONY: build build-supervisor build-app run install install-supervisor install-agent normalize clean

BINARY        := spank
SUPERVISOR    := spank-supervisor
INSTALL_DIR   := /usr/local/bin
APP_NAME      := SpankBar
APP_DIR       := SpankBar
AGENT_PLIST   := $(APP_DIR)/com.scott.spankbar.plist
AGENT_DEST    := $(HOME)/Library/LaunchAgents/com.scott.spankbar.plist

build:
	go build -o $(BINARY) .
	go build -o $(SUPERVISOR) ./supervisor/

build-supervisor:
	go build -o $(SUPERVISOR) ./supervisor/

build-app:
	xcodebuild -project $(APP_DIR)/$(APP_NAME).xcodeproj \
	           -scheme $(APP_NAME) \
	           -configuration Release \
	           -derivedDataPath /tmp/SpankBarBuild \
	           CODE_SIGN_IDENTITY="-" \
	           build
	@echo "Built: /tmp/SpankBarBuild/Build/Products/Release/$(APP_NAME).app"
	@echo "Copy to /Applications/: cp -R /tmp/SpankBarBuild/Build/Products/Release/$(APP_NAME).app /Applications/"

run: build
	sudo ./$(BINARY)

install: build
	sudo cp $(BINARY) $(INSTALL_DIR)/$(BINARY)
	sudo cp $(SUPERVISOR) $(INSTALL_DIR)/$(SUPERVISOR)
	@echo ""
	@echo "--- Supervisor install steps (run these manually) ---"
	@echo "1. sudo cp /Library/LaunchDaemons/com.taigrr.spank.plist /Library/LaunchDaemons/com.taigrr.spank.plist.bak"
	@echo "2. Edit /Library/LaunchDaemons/com.taigrr.spank.plist:"
	@echo "   Change ProgramArguments to: /usr/local/bin/spank-supervisor"
	@echo "   Add EnvironmentVariables key with SPANK_USER_HOME=$(HOME)"
	@echo "3. sudo launchctl unload /Library/LaunchDaemons/com.taigrr.spank.plist"
	@echo "4. sudo launchctl load /Library/LaunchDaemons/com.taigrr.spank.plist"

install-supervisor: build-supervisor
	sudo cp $(SUPERVISOR) $(INSTALL_DIR)/$(SUPERVISOR)

install-agent:
	cp $(AGENT_PLIST) $(AGENT_DEST)
	launchctl load $(AGENT_DEST)
	@echo "SpankBar LaunchAgent installed and loaded."

normalize:
	@./scripts/normalize.sh

clean:
	rm -f $(BINARY) $(SUPERVISOR)
