import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page
    wideMode: true
    Layout.fillWidth: true
    Layout.leftMargin: 4
    Layout.rightMargin: 4
    property alias cfg_stopId: stopIdField.text
    property alias cfg_apiKey: apiKeyField.text

    QQC2.TextField {
        id: stopIdField
        Kirigami.FormData.label: i18n("MTD Stop ID:")
        placeholderText: "GWNMN"
    }

    QQC2.TextField {
        id: apiKeyField
        Kirigami.FormData.label: i18n("MTD API Key:")
        placeholderText: "YOUR_API_KEY"
    }

    Kirigami.InlineMessage {
        Layout.fillWidth: true
        visible: true
        text: qsTr("You can get your API key here: <a href=\"https://mtd.dev/account/keys\">https://mtd.dev/account/keys<a/>")
        onLinkActivated: link => Qt.openUrlExternally(link)
    }
}
