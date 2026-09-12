PACKAGE := package
ID := de.ruiny.codexlimits
BUILD := build/$(ID).plasmoid

.PHONY: dev install uninstall package clean check

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
	cd $(PACKAGE) && zip -qr ../$(BUILD) .

check:
	python3 -m py_compile package/contents/core/limits.py
	qmllint package/contents/ui/main.qml

clean:
	rm -rf build
