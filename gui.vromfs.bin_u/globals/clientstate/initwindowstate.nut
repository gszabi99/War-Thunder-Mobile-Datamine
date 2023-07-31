let { subscribe } = require("eventbus")
let { blockWindow, unblockWindow } = require("%globalScripts/windowState.nut")

subscribe("android.webview.onVisibleChange",
  @(msg) msg.visible ? blockWindow("android.webview") : unblockWindow("android.webview"))