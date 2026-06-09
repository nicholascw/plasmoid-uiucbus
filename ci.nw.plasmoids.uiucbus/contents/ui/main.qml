import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid as PlasmaPlasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

PlasmaPlasmoid.PlasmoidItem {
    id: root

    Layout.minimumWidth: panelsWidth
    Layout.minimumHeight: 150
    Layout.preferredWidth: panelsWidth
    Layout.preferredHeight: 1000

    readonly property int panelsWidth: 420

    Item {
        id: contentRoot
        anchors.fill: parent

        // --- Configuration ---
        property bool isFetching: false
        property string stopId: PlasmaPlasmoid.Plasmoid.configuration.stopId
        property string apiKey: PlasmaPlasmoid.Plasmoid.configuration.apiKey
        property string stopName: "Loading..."

        // --- Data Age Properties ---
        property var lastUpdatedTime: null
        property string dataAgeText: "NaN"

        ListModel {
            id: departureModel
        }

        Timer {
            id: refreshTimer
            interval: 600000
            running: true
            repeat: true
            onTriggered: {
                contentRoot.fetchDepartures();
            }
        }

        Timer {
            id: ageTickerTimer
            interval: 1000
            running: contentRoot.lastUpdatedTime !== null
            repeat: true
            onTriggered: contentRoot.calculateDataAge()
        }

        function calculateDataAge() {
            if (!contentRoot.lastUpdatedTime) {
                contentRoot.dataAgeText = "NaN";
                return;
            }

            var now = new Date();
            var diffMs = now - contentRoot.lastUpdatedTime;
            var diffSecs = Math.floor(diffMs / 1000);
            var diffMins = Math.floor(diffSecs / 60);

            if (diffSecs < 3) {
                contentRoot.dataAgeText = "Just now";
            } else if (diffSecs < 60) {
                contentRoot.dataAgeText = diffSecs + " secs ago";
            } else {
                contentRoot.dataAgeText = diffMins + (diffMins === 1 ? " min ago" : " mins ago");
            }
        }

        function fetchDepartures() {
            if (!apiKey || apiKey === "YOUR_API_KEY") {
                contentRoot.stopName = "API Key Missing";
                return;
            }

            contentRoot.isFetching = true;
            departureModel.clear();

            // 1. Fetch Stop Location Details
            var stopUrl = "https://api.mtd.dev/stops/" + stopId;
            var xhrStop = new XMLHttpRequest();
            xhrStop.open("GET", stopUrl);
            xhrStop.setRequestHeader("X-ApiKey", apiKey);

            xhrStop.onreadystatechange = function () {
                if (xhrStop.readyState === XMLHttpRequest.DONE && xhrStop.status === 200) {
                    try {
                        var stopData = JSON.parse(xhrStop.responseText);
                        if (stopData.result && stopData.result.name) {
                            contentRoot.stopName = stopData.result.name;
                        }
                    } catch (e) {
                        console.error("Error parsing stop data", e);
                    }
                }
            };
            xhrStop.send();

            // 2. Fetch Live Departures
            var depUrl = "https://api.mtd.dev/stops/" + stopId + "/departures";
            var xhrDep = new XMLHttpRequest();
            xhrDep.open("GET", depUrl);
            xhrDep.setRequestHeader("X-ApiKey", apiKey);

            xhrDep.onreadystatechange = function () {
                if (xhrDep.readyState === XMLHttpRequest.DONE) {
                    contentRoot.isFetching = false;
                    contentRoot.lastUpdatedTime = new Date();
                    contentRoot.calculateDataAge();
                    if (xhrDep.status === 200) {
                        try {
                            var depData = JSON.parse(xhrDep.responseText);
                            var departures = depData.result || [];
                            if (departures.length > 0) {
                                for (var i = 0; i < departures.length; i++) {
                                    var dep = departures[i];

                                    var timeStr = "--:--";
                                    var targetTime = dep.estimatedDeparture || dep.scheduledDeparture;
                                    if (targetTime) {
                                        var dateObj = new Date(targetTime);
                                        if (!isNaN(dateObj.getTime())) {
                                            timeStr = dateObj.getHours().toString().padStart(2, '0') + ":" + dateObj.getMinutes().toString().padStart(2, '0');
                                        }
                                    }

                                    var shortName = (dep.route && dep.route.shortName) ? dep.route.shortName : "";
                                    var directionChar = (dep.trip && dep.trip.direction && dep.trip.direction.shortName) ? dep.trip.direction.shortName : "";
                                    var computedRouteId = shortName + directionChar;
                                    if (!computedRouteId) {
                                        computedRouteId = "Bus";
                                    }

                                    var longName = (dep.route && dep.route.longName) ? dep.route.longName : "Scheduled Route";
                                    var destinationStr = dep.destination ? "to " + dep.destination : (dep.headsign || "");
                                    var hexColor = (dep.route && dep.route.color) ? "#" + dep.route.color : '#000000';

                                    departureModel.append({
                                        "routeId": computedRouteId,
                                        "routeName": longName,
                                        "headsign": destinationStr,
                                        "expectedTime": timeStr,
                                        "expectedMins": dep.minutesTillDeparture !== undefined ? dep.minutesTillDeparture : 0,
                                        "pillColor": hexColor
                                    });
                                }
                                refreshTimer.interval = 600 * 1000;
                            } else {
                                departureModel.append({
                                    "routeId": "NNN",
                                    "routeName": "No Scheduled Departures",
                                    "headsign": "Refresh interval reduced to once per hour.",
                                    "expectedTime": "You should have rest!",
                                    "expectedMins": 0,
                                    "pillColor": "#000"
                                });
                                refreshTimer.interval = 3600 * 1000;
                            }
                        } catch (e) {
                            console.error("Failed to parse departures JSON", e);
                        }
                    } else {
                        departureModel.append({
                            "routeId": "XXX",
                            "routeName": "Error Occured",
                            "headsign": "Refresh interval reduced to once per hour.",
                            "expectedTime": "Hit API Rate-limit?",
                            "expectedMins": 0,
                            "pillColor": '#720000'
                        });
                        refreshTimer.interval = 3600 * 1000;
                    }
                }
            };
            xhrDep.send();
        }

        Component.onCompleted: {
            fetchDepartures();
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            // --- Top Header ---
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                spacing: 8

                PlasmaComponents3.Label {
                    text: contentRoot.stopName
                    font.pixelSize: 16
                    font.bold: true
                    color: Kirigami.Theme.textColor
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                PlasmaComponents3.Label {
                    text: contentRoot.dataAgeText
                    font.pixelSize: 11
                    color: Kirigami.Theme.disabledTextColor
                    Layout.alignment: Qt.AlignVCenter
                }

                PlasmaComponents3.Switch {
                    PlasmaComponents3.ToolTip.text: "Auto Refresh"
                    PlasmaComponents3.ToolTip.visible: hovered
                    checked: refreshTimer.running
                    onToggled: {
                        if (checked) {
                            refreshTimer.start();
                        } else {
                            refreshTimer.stop();
                        }
                    }
                }

                PlasmaComponents3.ToolButton {
                    icon.name: "view-refresh"
                    onClicked: {
                        if (refreshTimer.running) {
                            refreshTimer.restart();
                        }
                        contentRoot.fetchDepartures();
                    }
                }
            }

            Kirigami.ScrollablePage {
                Layout.fillWidth: true
                Layout.fillHeight: true
                // --- Main Departure Cards Feed ---
                background: Rectangle {
                    color: "transparent"
                }

                Kirigami.CardsListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: departureModel
                    clip: true

                    delegate: Kirigami.AbstractCard {
                        height: 74

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            // Route Number Capsule
                            Rectangle {
                                width: 52
                                height: 48
                                color: model.pillColor
                                radius: 12
                                Layout.alignment: Qt.AlignVCenter

                                PlasmaComponents3.Label {
                                    text: model.routeId
                                    color: "#ffffff"
                                    font.bold: true
                                    font.pixelSize: 18
                                    anchors.centerIn: parent
                                }
                            }

                            // Label Information Stack
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Layout.alignment: Qt.AlignVCenter

                                PlasmaComponents3.Label {
                                    text: model.routeName
                                    color: Kirigami.Theme.textColor
                                    font.bold: true
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                }

                                PlasmaComponents3.Label {
                                    text: model.headsign
                                    color: Kirigami.Theme.disabledTextColor
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                PlasmaComponents3.Label {
                                    text: model.expectedTime
                                    color: Kirigami.Theme.disabledTextColor
                                    font.pixelSize: 11
                                }
                            }

                            // Time Countdown Tracking Pillar
                            RowLayout {
                                spacing: 4
                                Layout.alignment: Qt.AlignVCenter

                                PlasmaComponents3.Label {
                                    text: model.expectedMins
                                    color: Kirigami.Theme.textColor
                                    font.bold: true
                                    font.pixelSize: 22
                                }

                                PlasmaComponents3.Label {
                                    text: "min"
                                    color: Kirigami.Theme.disabledTextColor
                                    font.pixelSize: 11
                                    Layout.alignment: Qt.AlignBottom
                                    Layout.bottomMargin: 3
                                }

                                Kirigami.Icon {
                                    source: "chronometer"
                                    implicitWidth: 14
                                    implicitHeight: 14
                                    Layout.leftMargin: 2
                                    color: Kirigami.Theme.disabledTextColor
                                }
                            }
                        }
                    }
                }
            }
        }

        PlasmaComponents3.BusyIndicator {
            anchors.centerIn: parent
            running: contentRoot.isFetching
            visible: contentRoot.isFetching
        }
    }
}
