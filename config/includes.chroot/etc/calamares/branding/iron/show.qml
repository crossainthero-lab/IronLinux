import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Timer {
        interval: 18000
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Image {
            id: background
            source: "wallpaper.png"
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            opacity: 0.22
        }

        Rectangle {
            anchors.fill: parent
            color: "#171a1d"
            opacity: 0.74
        }

        Image {
            id: logo
            source: "wordmark.svg"
            width: Math.min(parent.width * 0.62, 420)
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 76
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logo.bottom
            anchors.topMargin: 34
            width: Math.min(parent.width * 0.78, 620)
            text: qsTr("Iron Linux is being installed. The target disk is being written, boot files are being configured, and the installed system will be prepared to start without this USB or ISO.")
            color: "#d7dce0"
            font.pixelSize: 18
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
