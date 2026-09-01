from "eventbus" import eventbus_subscribe
from "%appGlobals/windowState.nut" import blockWindow, unblockWindow


eventbus_subscribe("android.webview.onVisibleChange",
  @(msg) msg.visible ? blockWindow("android.webview") : unblockWindow("android.webview"))