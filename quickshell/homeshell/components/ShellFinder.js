.pragma library

function findShell(start) {
  var p = start
  while (p) {
    if (p.shell) return p.shell
    if (typeof p.baseDir === "string" && typeof p.drawerMode === "string") return p
    p = p.parent
  }
  return null
}
