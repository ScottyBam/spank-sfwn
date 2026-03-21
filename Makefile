# Prerequisites: brew install go ffmpeg

.PHONY: build run install normalize clean

BINARY := spank
INSTALL_DIR := /usr/local/bin

build:
	go build -o $(BINARY) .

run: build
	sudo ./$(BINARY)

install: build
	sudo cp $(BINARY) $(INSTALL_DIR)/$(BINARY)

normalize:
	@./scripts/normalize.sh

clean:
	rm -f $(BINARY)
