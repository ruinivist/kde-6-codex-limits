import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    property int usedPercent: -1
    property double resetsAt: 0
    property double now: Date.now()
    property string statusText: i18n("Loading…")
    readonly property string scriptPath: Qt.resolvedUrl("../code/limits.py").toString().replace(/^file:\/\//, "")
    readonly property string command: "python3 '" + scriptPath.replace(/'/g, "'\\''") + "'"

    function refresh() {
        runner.disconnectSource(command);
        runner.connectSource(command);
    }

    function remainingTime() {
        const totalMinutes = Math.max(0, Math.ceil((resetsAt * 1000 - now) / 60000));
        const days = Math.floor(totalMinutes / 1440);
        const hours = Math.floor(totalMinutes % 1440 / 60);
        const minutes = totalMinutes % 60;
        return i18n("%1d %2h %3m", days, ("0" + hours).slice(-2), ("0" + minutes).slice(-2));
    }

    preferredRepresentation: compactRepresentation
    toolTipMainText: ""
    toolTipSubText: ""
    Component.onCompleted: refresh()

    Timer {
        interval: 5 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        interval: 60 * 1000
        running: true
        repeat: true
        onTriggered: root.now = Date.now()
    }

    Plasma5Support.DataSource {
        id: runner

        engine: "executable"
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName);
            try {
                const result = JSON.parse(data.stdout);
                if (result.error)
                    throw new Error(result.error);

                root.usedPercent = result.usedPercent;
                root.resetsAt = result.resetsAt;
                root.statusText = i18n("%1% used", result.usedPercent);
            } catch (error) {
                root.usedPercent = -1;
                root.resetsAt = 0;
                root.statusText = error.message || i18n("Unable to read limits");
            }
        }
    }

    compactRepresentation: RowLayout {
        spacing: Kirigami.Units.smallSpacing
        Layout.minimumWidth: implicitWidth
        Layout.minimumHeight: implicitHeight
        Layout.maximumHeight: implicitHeight
        Accessible.role: Accessible.Button
        Accessible.name: i18n("Codex weekly usage")
        Accessible.description: root.statusText
        Accessible.onPressAction: root.expanded = !root.expanded

        TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: root.expanded = !root.expanded
        }

        Image {
            source: "../images/chatgpt.svg"
            Layout.preferredWidth: usage.implicitHeight
            Layout.preferredHeight: usage.implicitHeight
            Layout.alignment: Qt.AlignVCenter
        }

        PlasmaComponents.Label {
            id: usage

            text: (root.usedPercent < 0 ? "--" : root.usedPercent) + "%"
            color: "white"
            font.family: "monospace"
        }

        Rectangle {
            color: Qt.rgba(1, 1, 1, 0.25)
            Layout.preferredWidth: usage.implicitHeight * 5
            Layout.preferredHeight: usage.implicitHeight * 0.6
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                width: parent.width * Math.min(100, Math.max(0, root.usedPercent)) / 100
                height: parent.height
                color: "white"
            }

        }

    }

    fullRepresentation: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        Layout.minimumWidth: Kirigami.Units.gridUnit * 12
        Layout.minimumHeight: implicitHeight

        PlasmaComponents.Label {
            text: i18n("Codex weekly limits")
            font.bold: true
        }

        PlasmaComponents.Label {
            text: root.statusText
        }

        PlasmaComponents.Label {
            visible: root.resetsAt > 0
            text: i18n("Resets in %1", root.remainingTime())
        }
    }

}
