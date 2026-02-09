from "%globalsDarg/darg_library.nut" import *
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { eventbus_send } = require("eventbus")
let { openMsgBox, msgBoxText, closeMsgBox } = require("%rGui/components/msgBox.nut")
let { isInMenuNoModals } = require("%rGui/mainMenu/mainMenuState.nut")
let { isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { isTutorialActive } = require("%rGui/tutorial/tutorialWnd/tutorialWndState.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { allPenalties } = require("%appGlobals/userPenalties.nut")

let PENALTY_KEY = "DECALS_DISABLE"
let isOriginalDecals = "USEROPT_IS_ORIGINAL_DECALS"
let isDecalsPenaltyShowed = hardPersistWatched("isDecalsPenaltyShowed", false)
let decalsPenalty = keepref(Computed(@() allPenalties.get()?[PENALTY_KEY] ?? 0))

let needShowPenalty = keepref(Computed(@() isInMenuNoModals.get()
  && decalsPenalty.get() > 0
  && !isInLoadingScreen.get()
  && !isTutorialActive.get()
  && !isDecalsPenaltyShowed.get()
  && isLoggedIn.get()))

function showDecalInfoWnd() {
  let sBlk = get_local_custom_settings_blk()
  let isWndShown = sBlk?[isOriginalDecals] ?? false
  if (isWndShown)
    return

  sBlk[isOriginalDecals] <- true
  eventbus_send("saveProfile", {})

  openMsgBox({
    text = loc("options/desc/hud_show_original_decals", {
      optionName = colorize("@mark", loc("options/hud_show_original_decals"))
      optionValue = colorize("@mark", loc("options/enable"))
    })
    title = loc("unit/customization/modalTitle")
  })
}

function showDecalInfoPenaltyWnd() {
  if (isDecalsPenaltyShowed.get())
    return
  isDecalsPenaltyShowed.set(true)
  let timeToEndDecalsPenalty = Computed(@() decalsPenalty.get() - serverTime.get())
  timeToEndDecalsPenalty.subscribe(@(timeToEnd) timeToEnd <= 0 ? closeMsgBox(PENALTY_KEY) : null)

  openMsgBox({
    uid = PENALTY_KEY
    text = {
      size = flex()
      flow = FLOW_VERTICAL
      children = [
        msgBoxText(loc("msgbox/decalsPenalty"))
        @() {
          watch = timeToEndDecalsPenalty
          size = flex()
          children = msgBoxText($"{loc("time_to_end_penalty")} {secondsToHoursLoc(timeToEndDecalsPenalty.get())}")
        }
      ]
    }
    title = loc("msgbox/attention")
  })
}

needShowPenalty.subscribe(@(v) v ? showDecalInfoPenaltyWnd() : null)

register_command(function() {
    get_local_custom_settings_blk()[isOriginalDecals] <- null
    eventbus_send("saveProfile", {})
  }, "debug.reset_show_other_decals")

register_command(@() isDecalsPenaltyShowed.set(false), "debug.reset_penalty_decals_popup")

return {
  showDecalInfoWnd
}
