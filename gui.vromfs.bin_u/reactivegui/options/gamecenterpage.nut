from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "%sqstd/platform.nut" import is_ios, is_pc
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/components/buttonStyles.nut" import PRIMARY
from "%rGui/components/textButton.nut" import buttonsHGap, mkCustomButton, mkButtonTextMultiline, mergeStyles


let debugSignedIn = Watched(false)

let { openAchievementsApp = @() null, signIn = @() null, isSigned = Watched(false) } = is_ios ? require("%rGui/unlocks/iosGameCenter.nut")
  : is_pc ? {
      openAchievementsApp = @() console_print("Opened achievements app") 
      signIn = @() debugSignedIn.set(true)
      isSigned = Watched(false)
    }
  : null

let buttonsWidthStyle = {
  ovr = {
    minWidth = hdpx(550)
  }
}
let multilineButtonOvrStyle = { size = const [hdpx(450), SIZE_TO_CONTENT], lineSpacing = hdpx(-4) }.__update(fontBoldTinyAccentedShaded)

let isSignedIn = Computed(@() debugSignedIn.get() || isSigned.get())

register_command(function() {
  debugSignedIn.set(!debugSignedIn.get())
  console_print($"debugSignedIn: {debugSignedIn.get()}") 
}, "ui.debug.gameCenter.toggleSignIn")

return @() {
  watch = isSignedIn
  size = FLEX
  flow = FLOW_VERTICAL
  gap = buttonsHGap
  halign = ALIGN_CENTER
  children = !isSignedIn.get()
    ? mkCustomButton(
        mkButtonTextMultiline(utf8ToUpper(loc("gameCenter/signIn")), multilineButtonOvrStyle),
        signIn,
        mergeStyles(PRIMARY, buttonsWidthStyle))
    : [
        {
          rendObj = ROBJ_TEXT
          text = loc("gameCenter/loggedIn")
        }.__update(fontSmall)
        mkCustomButton(
          mkButtonTextMultiline(utf8ToUpper(loc("gameCenter/openAchievements")), multilineButtonOvrStyle),
          openAchievementsApp,
          mergeStyles(PRIMARY, buttonsWidthStyle))
      ]
}
