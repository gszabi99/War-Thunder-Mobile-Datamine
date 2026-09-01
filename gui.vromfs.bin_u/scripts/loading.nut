from "eventbus" import eventbus_subscribe
import "%scripts/loadRootScreen.nut" as loadRootScreen




eventbus_subscribe("gui_start_loading", @(_) loadRootScreen())
