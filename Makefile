CONFIGURATION ?= release
PREFIX ?= /usr/local
VALID_CONFIGURATIONS := debug release
SOURCES := $(shell find Sources -type f -name '*.swift')
TESTS := $(shell find Tests -type f -name '*.swift')
PACKAGE := Package.swift

ifeq ($(filter $(CONFIGURATION),$(VALID_CONFIGURATIONS)),)
	$(error Invalid value for CONFIGURATION. Valid values are $(VALID_CONFIGURATIONS))
endif


.PHONY: all test clean
all: build
build: $(wildcard Sources/**/*.swift Tests/**/*.swift Package.swift)
	swift build -c $(CONFIGURATION) --static-swift-stdlib -Xswiftc -g
	touch build
install: build
	pkill -9 Swift-MesonLSP || true
	cp .build/$(CONFIGURATION)/Swift-MesonLSP $(PREFIX)/bin
test:
	swift test
clean:
	swift package clean

