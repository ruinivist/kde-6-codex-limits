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

    function refresh() {
        runner.disconnectSource(command);
        runner.connectSource(command);
    }

    preferredRepresentation: fullRepresentation
    toolTipMainText: i18n("Codex weekly limits")
    toolTipSubText: statusText
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
            disconnectSource(sourceName);
            try {
                const result = JSON.parse(data.stdout);
                if (result.error)
                    throw new Error(result.error);

                root.usedPercent = result.usedPercent;
                root.statusText = i18n("%1% used", result.usedPercent);
            } catch (error) {
                root.usedPercent = -1;
                root.statusText = error.message || i18n("Unable to read limits");
            }
        }
    }

    fullRepresentation: RowLayout {
        spacing: Kirigami.Units.smallSpacing
        Layout.minimumWidth: implicitWidth
        Layout.minimumHeight: implicitHeight
        Layout.maximumHeight: implicitHeight
        Accessible.name: i18n("Codex weekly usage")
        Accessible.description: root.statusText

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

}
