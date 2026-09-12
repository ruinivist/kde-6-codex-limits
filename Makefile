PACKAGE := package
ID := de.ruiny.codexlimits
BUILD := build/$(ID).plasmoid
PLING_UPLOADER := https://raw.githubusercontent.com/ruinivist/kde-6-widget-starter/main/scripts/pling_upload.py

.PHONY: dev install uninstall package pling-upload clean check format hook

dev:
	plasmoidviewer -a $(PACKAGE)

install:
	@if kpackagetool6 --type Plasma/Applet --show $(ID) >/dev/null 2>&1; then \
		kpackagetool6 --type Plasma/Applet --upgrade $(PACKAGE); \
	else \
		kpackagetool6 --type Plasma/Applet --install $(PACKAGE); \
	fi

uninstall:
	kpackagetool6 --type Plasma/Applet --remove $(ID)

package:
	mkdir -p build
	rm -f $(BUILD)
	cd $(PACKAGE) && zip -qr ../$(BUILD) . -x '*/__pycache__/*' '*.py[cod]'

pling-upload: package
	uv run --isolated --env-file .env --with 'niquests>=3.18.5' $(PLING_UPLOADER) -f $(BUILD)

check:
	python3 -m py_compile package/contents/core/limits.py
	qmllint package/contents/ui/main.qml

format:
	uvx --from ruff==0.16.7 ruff format package/contents/core/limits.py

hook:
	pre-commit install

clean:
	rm -rf build
