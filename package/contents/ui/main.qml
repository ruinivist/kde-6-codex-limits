import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    property real weeklyUsedPercent: -1
    property double weeklyResetsAt: 0
    property real fiveHourUsedPercent: -1
    property double fiveHourResetsAt: 0
    property double now: Date.now()
    property string statusText: i18n("Loading…")
    readonly property string scriptPath: Qt.resolvedUrl("../code/limits.py").toString().replace(/^file:\/\//, "")
    readonly property string command: "python3 '" + scriptPath.replace(/'/g, "'\\''") + "'"

    function refresh() {
        runner.disconnectSource(command);
        runner.connectSource(command);
    }

    function remainingTime(resetAt) {
        const totalMinutes = Math.max(0, Math.ceil((resetAt * 1000 - now) / 60000));
        const days = Math.floor(totalMinutes / 1440);
        const hours = Math.floor(totalMinutes % 1440 / 60);
        const minutes = totalMinutes % 60;
        return i18n("%1d %2h %3m", days, ("0" + hours).slice(-2), ("0" + minutes).slice(-2));
    }

    function percentText(percent) {
        return percent < 0 ? "--%" : percent + "%";
    }

    function fillPercent(percent) {
        return Math.min(100, Math.max(0, percent < 0 ? 0 : percent));
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

                root.weeklyUsedPercent = result.weeklyUsedPercent ?? -1;
                root.weeklyResetsAt = result.weeklyResetsAt ?? 0;
                root.fiveHourUsedPercent = result.fiveHourUsedPercent ?? -1;
                root.fiveHourResetsAt = result.fiveHourResetsAt ?? 0;
                root.statusText = i18n("5-hour usage %1 | weekly usage %2", root.percentText(root.fiveHourUsedPercent), root.percentText(root.weeklyUsedPercent));
            } catch (error) {
                root.weeklyUsedPercent = -1;
                root.weeklyResetsAt = 0;
                root.fiveHourUsedPercent = -1;
                root.fiveHourResetsAt = 0;
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
        Accessible.name: i18n("Codex usage limits")
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

            text: root.percentText(root.fiveHourUsedPercent) + " | " + root.percentText(root.weeklyUsedPercent)
            color: "white"
            font.family: "monospace"
        }

        ColumnLayout {
            spacing: 1
            Layout.preferredWidth: usage.implicitHeight * 5
            Layout.preferredHeight: usage.implicitHeight * 0.6 + spacing
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: usage.implicitHeight * 0.3
                color: Qt.rgba(1, 1, 1, 0.25)
                Accessible.name: i18n("Weekly usage")
                Accessible.description: root.percentText(root.weeklyUsedPercent)

                Rectangle {
                    width: parent.width * root.fillPercent(root.weeklyUsedPercent) / 100
                    height: parent.height
                    color: "white"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: usage.implicitHeight * 0.3
                color: Qt.rgba(1, 1, 1, 0.25)
                Accessible.name: i18n("5-hour usage")
                Accessible.description: root.percentText(root.fiveHourUsedPercent)

                Rectangle {
                    width: parent.width * root.fillPercent(root.fiveHourUsedPercent) / 100
                    height: parent.height
                    color: "white"
                }
            }
        }

    }

    fullRepresentation: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        Layout.minimumWidth: Kirigami.Units.gridUnit * 12
        Layout.minimumHeight: implicitHeight

        PlasmaComponents.Label {
            text: i18n("Codex usage limits")
            font.bold: true
        }

        PlasmaComponents.Label {
            text: root.statusText
        }

        PlasmaComponents.Label {
            visible: root.fiveHourResetsAt > 0
            text: i18n("5-hour resets in %1", root.remainingTime(root.fiveHourResetsAt))
        }

        PlasmaComponents.Label {
            visible: root.weeklyResetsAt > 0
            text: i18n("Weekly resets in %1", root.remainingTime(root.weeklyResetsAt))
        }
    }

}
