import QtQuick

Text {
  id: component
  property var shell: null

  function findShell() {
    var p = parent
    while (p) {
      if (p.shell) return p.shell
      if (typeof p.baseDir === 'string' && typeof p.drawerMode === 'string') return p
      p = p.parent
    }
    return null
  }

  Component.onCompleted: { if (shell === null) shell = findShell() }

  color: shell ? shell.textColor : "#efe4dc"
  font.family: "JetBrainsMono Nerd Font"
  font.pixelSize: 12
  font.contextFontMerging: true
  verticalAlignment: Text.AlignVCenter
  horizontalAlignment: Text.AlignHCenter
  elide: Text.ElideRight

  Behavior on color { ColorAnimation { duration: shell ? shell.motionFast : 110 } }
}
