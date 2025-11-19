from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { is_ios, is_pc } = require("%sqstd/platform.nut")
let { buttonsHGap, mkCustomButton, mkButtonTextMultiline, mergeStyles
} = require("%rGui/components/textButton.nut")
let { PRIMARY } = require("%rGui/components/buttonStyles.nut")

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
let multilineButtonOvrStyle = { size = static [hdpx(450), SIZE_TO_CONTENT], lineSpacing = hdpx(-4) }.__update(fontTinyAccentedShadedBold)

let isSignedIn = Computed(@() debugSignedIn.get() || isSigned.get())

register_command(function() {
  debugSignedIn.set(!debugSignedIn.get())
  console_print($"debugSignedIn: {debugSignedIn.get()}") 
}, "ui.debug.gameCenter.toggleSignIn")

return @() {
  watch = isSignedIn
  size = flex()
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
