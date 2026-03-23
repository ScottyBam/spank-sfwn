# Prerequisites: brew install go ffmpeg
# For SpankBar: Xcode 15+ required
#
# Quick start (first install):
#   make install          — build + install Go binaries + load daemon
#   make build-app        — build SpankBar.app (Xcode required)
#   sudo cp -R /tmp/SpankBarBuild/Build/Products/Release/SpankBar.app /Applications/
#   make install-agent    — install SpankBar LaunchAgent

.PHONY: build build-supervisor build-app run install install-supervisor install-daemon install-agent reload-daemon normalize clean

BINARY        := spank
SUPERVISOR    := spank-supervisor
INSTALL_DIR   := /usr/local/bin
APP_NAME      := SpankBar
APP_DIR       := SpankBar
AGENT_PLIST   := $(APP_DIR)/com.scott-t-b.spankbar.plist
AGENT_DEST    := $(HOME)/Library/LaunchAgents/com.scott-t-b.spankbar.plist

DAEMON_PLIST_SRC  := LaunchDaemons/com.taigrr.spank.plist
DAEMON_PLIST_DEST := /Library/LaunchDaemons/com.taigrr.spank.plist
DAEMON_LABEL      := com.taigrr.spank

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
	@echo "Install: sudo cp -R /tmp/SpankBarBuild/Build/Products/Release/$(APP_NAME).app /Applications/"

run: build
	sudo ./$(BINARY)

# Install binaries and load daemon — single sudo prompt, no line-split issues
install:
	sudo bash scripts/install.sh

install-supervisor: build-supervisor
	sudo cp $(SUPERVISOR) $(INSTALL_DIR)/$(SUPERVISOR)
	sudo codesign --force --deep --sign - $(INSTALL_DIR)/$(SUPERVISOR)
	$(MAKE) reload-daemon

# Install and activate the LaunchDaemon (substitutes current user's home dir)
install-daemon:
	sudo cp $(DAEMON_PLIST_SRC) $(DAEMON_PLIST_DEST)
	sudo sed -i '' 's|__SPANK_USER_HOME__|$(HOME)|g' $(DAEMON_PLIST_DEST)
	sudo chown root:wheel $(DAEMON_PLIST_DEST)
	sudo chmod 644 $(DAEMON_PLIST_DEST)
	@if launchctl print system/$(DAEMON_LABEL) >/dev/null 2>&1; then \
		sudo launchctl kickstart -k system/$(DAEMON_LABEL); \
		echo "Daemon reloaded."; \
	else \
		sudo launchctl bootstrap system $(DAEMON_PLIST_DEST); \
		echo "Daemon loaded."; \
	fi

reload-daemon:
	sudo launchctl kickstart -k system/$(DAEMON_LABEL)

install-agent:
	cp $(AGENT_PLIST) $(AGENT_DEST)
	launchctl load $(AGENT_DEST)
	@echo "SpankBar LaunchAgent installed and loaded."

normalize:
	@./scripts/normalize.sh

clean:
	rm -f $(BINARY) $(SUPERVISOR)
