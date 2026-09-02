.DEFAULT_GOAL := help
.PHONY: help setup run release analyze test gates check-architecture check-design check-conventions doctor devices apk bundle clean reset

help:
	@echo Bilang - make targets
	@echo   make run        run on the connected device, debug mode
	@echo   make release    run in release mode - real scanning speed
	@echo   make setup      restore packages
	@echo   make gates      everything CI runs: analyze, test, architecture, design
	@echo   make analyze    static analysis
	@echo   make test       unit + widget tests
	@echo   make apk        build the release APK for sideloading
	@echo   make bundle     build the signed release bundle for Play
	@echo   make devices    list connected devices
	@echo   make doctor     flutter doctor -v
	@echo   make clean      drop build output
	@echo   make reset      clean, then restore packages

setup:
	flutter pub get

run:
	flutter run

release:
	flutter run --release

analyze:
	flutter analyze

test:
	flutter test

check-architecture:
	node scripts/check-architecture.mjs

check-design:
	node scripts/check-design.mjs

check-conventions:
	node scripts/check-conventions.mjs

gates: analyze test check-architecture check-design
	@echo all gates green

apk:
	flutter build apk --release

bundle:
	flutter build appbundle --release

devices:
	flutter devices

doctor:
	flutter doctor -v

clean:
	flutter clean

reset: clean setup
