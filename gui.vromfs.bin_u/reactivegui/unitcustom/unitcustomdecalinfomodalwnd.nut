from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_local_custom_settings_blk
from "console" import register_command
from "eventbus" import eventbus_send
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/clientState/clientState.nut" import isInLoadingScreen
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/timeToText.nut" import secondsToHoursLoc
from "%appGlobals/userPenalties.nut" import allPenalties
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/components/msgBox.nut" import openMsgBox, msgBoxText, closeMsgBox
from "%rGui/mainMenu/mainMenuState.nut" import isInMenuNoModals
from "%rGui/tutorial/tutorialWnd/tutorialWndState.nut" import isTutorialActive


const PENALTY_KEY = "DECALS_DISABLE"
const isOriginalDecals = "USEROPT_IS_ORIGINAL_DECALS"
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
      size = FLEX
      flow = FLOW_VERTICAL
      children = [
        msgBoxText(loc("msgbox/decalsPenalty"))
        @() {
          watch = timeToEndDecalsPenalty
          size = FLEX
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
