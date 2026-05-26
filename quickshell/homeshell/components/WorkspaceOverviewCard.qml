import QtQuick
import QtQuick.Layouts

Rectangle {
  id: workspaceCard
  property var shell: null

  function findShell() {
    var p = parent
    while (p) {
      if (p.shell) return p.shell
      if (p && typeof p.baseDir !== "undefined" && typeof p.drawerMode !== "undefined") return p
      p = p.parent
    }
    return null
  }

  Component.onCompleted: { if (shell === null) shell = findShell() }

  property var workspace
  property real cardHeight: 260
  property bool hovered: false
  readonly property var clients: workspace && workspace.clients ? workspace.clients : []
  readonly property bool activeWorkspace: shell && shell.workspaceIsActive ? shell.workspaceIsActive(workspace) : workspace && workspace.active

  Layout.fillWidth: true
  Layout.preferredHeight: Math.max(245, cardHeight)
  radius: shell ? shell.cornerRadius : 3
  color: shell ? Qt.rgba(shell.base.r, shell.base.g, shell.base.b, hovered || activeWorkspace ? 0.76 : 0.58) : Qt.rgba(0.08, 0.07, 0.06, hovered || activeWorkspace ? 0.76 : 0.58)
  border.width: shell ? shell.uiBorderWidth : 3
  border.color: activeWorkspace
    ? (shell ? Qt.rgba(shell.accent.r, shell.accent.g, shell.accent.b, 0.80) : Qt.rgba(0.66, 0.77, 0.79, 0.80))
    : (shell ? Qt.rgba(shell.muted.r, shell.muted.g, shell.muted.b, hovered ? 0.46 : 0.22) : Qt.rgba(0.8, 0.75, 0.71, hovered ? 0.46 : 0.22))
  scale: hovered || activeWorkspace ? (shell ? shell.motionLift : 1.006) : 1

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 12
    spacing: 10

    RowLayout {
      Layout.fillWidth: true
      Layout.preferredHeight: 28
      spacing: 10

      MinimalText {
        Layout.fillWidth: true
        text: "workspace " + ((workspaceCard.workspace && workspaceCard.workspace.name) ? workspaceCard.workspace.name : "")
        color: workspaceCard.activeWorkspace ? (shell ? shell.accent : "#a8c5c9") : (shell ? shell.textColor : "#efe4dc")
        horizontalAlignment: Text.AlignLeft
        font.pixelSize: 16
      }

      MinimalText {
        Layout.preferredWidth: 120
        text: String(workspaceCard.clients.length) + (workspaceCard.clients.length === 1 ? " window" : " windows")
        color: shell ? shell.muted : "#cdbeb4"
        horizontalAlignment: Text.AlignRight
        font.pixelSize: 10
      }
    }

    Rectangle {
      id: previewArea
      Layout.fillWidth: true
      Layout.fillHeight: true
      radius: shell ? shell.cornerRadius : 3
      color: shell ? Qt.rgba(shell.baseAlt.r, shell.baseAlt.g, shell.baseAlt.b, 0.46) : Qt.rgba(0.14, 0.11, 0.09, 0.46)
      border.width: 1
      border.color: shell ? Qt.rgba(shell.muted.r, shell.muted.g, shell.muted.b, 0.22) : Qt.rgba(0.8, 0.75, 0.71, 0.22)
      clip: true

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: workspaceCard.hovered = true
        onExited: workspaceCard.hovered = false
        onClicked: if (shell) shell.focusWorkspace(workspaceCard.workspace)
      }

      MinimalText {
        visible: workspaceCard.clients.length === 0
        anchors.centerIn: parent
        text: "empty"
        color: shell ? shell.muted : "#cdbeb4"
        font.pixelSize: 12
      }

      Repeater {
        model: workspaceCard.clients
        delegate: MiniWindowPreview {
          shell: workspaceCard.shell
          client: modelData
          clients: workspaceCard.clients
          previewWidth: previewArea.width
          previewHeight: previewArea.height
        }
      }
    }
  }

  Behavior on color { ColorAnimation { duration: shell ? shell.motionBase : 170 } }
  Behavior on border.color { ColorAnimation { duration: shell ? shell.motionBase : 170 } }
  Behavior on scale { NumberAnimation { duration: shell ? shell.motionFast : 110; easing.type: Easing.OutCubic } }
}
