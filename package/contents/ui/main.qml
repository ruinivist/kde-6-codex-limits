import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    property int usedPercent: -1
    property string statusText: i18n("Loading…")
    readonly property string scriptPath: Qt.resolvedUrl("../code/limits.py").toString().replace(/^file:\/\//, "")
    readonly property string command: "python3 '" + scriptPath.replace(/'/g, "'\\''") + "'"

    width: Kirigami.Units.gridUnit * 14
    height: Kirigami.Units.gridUnit * 6
    preferredRepresentation: fullRepresentation
    toolTipMainText: i18n("Codex weekly limits")
    toolTipSubText: statusText

    function refresh() {
        runner.disconnectSource(command)
        runner.connectSource(command)
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 5 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Plasma5Support.DataSource {
        id: runner

        engine: "executable"
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            try {
                const result = JSON.parse(data.stdout)
                if (result.error)
                    throw new Error(result.error)
                root.usedPercent = result.usedPercent
                root.statusText = i18n("%1% used", result.usedPercent)
            } catch (error) {
                root.usedPercent = -1
                root.statusText = error.message || i18n("Unable to read limits")
            }
        }
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 10
        Layout.minimumHeight: Kirigami.Units.gridUnit * 4
        Layout.preferredWidth: root.width
        Layout.preferredHeight: root.height

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                text: i18n("Codex weekly")
                font.bold: true
                Layout.fillWidth: true
            }

            PlasmaComponents.ProgressBar {
                from: 0
                to: 100
                value: Math.max(0, root.usedPercent)
                indeterminate: root.usedPercent < 0
                Accessible.name: i18n("Codex weekly usage")
                Accessible.description: root.statusText
                Layout.fillWidth: true
            }

            PlasmaComponents.Label {
                text: root.statusText
                opacity: 0.75
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }
}
