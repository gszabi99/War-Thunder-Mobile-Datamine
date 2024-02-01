from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe } = require("eventbus")
let iOsPlaform = require("ios.platform")
let { requestTrackingPermission, getTrackingPermission, ATT_NOT_DETERMINED } = iOsPlaform
let { isMainMenuAttached } = require("%rGui/mainMenu/mainMenuState.nut")
let { isOutOfBattleAndResults } = require("%appGlobals/clientState/clientState.nut")
let { newbieOfflineMissions } = require("%rGui/gameModes/newbieOfflineMissions.nut")
let { needFirstBattleTutor } = require("%rGui/tutorial/tutorialMissions.nut")
let { registerScene } = require("%rGui/navState.nut")
let { mkColoredGradientY } = require("%rGui/style/gradients.nut")
let { textButtonPrimary } = require("%rGui/components/textButton.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { setTimeout } = require("dagor.workcycle")
let { abTests } = require("%appGlobals/pServer/campaign.nut")
let { register_command } = require("console")


let IDFA_SCENE_ID = "iosIdentifierForAdvertisers"

let forceInGameAdTrackingMessage = mkWatched(persist, "forceInGameAdTrackingMessage", null)
let currentSettingForIDFA = hardPersistWatched("currentSettingForIDFA", getTrackingPermission())
let isForceClosed = mkWatched(persist, "isForceClosed", false)
let needShow = Computed(@() !isForceClosed.value
  && !needFirstBattleTutor.value
  && newbieOfflineMissions.value == null
  && currentSettingForIDFA.value == ATT_NOT_DETERMINED)
let canShow = Computed(@() isMainMenuAttached.value && isOutOfBattleAndResults.value)
let needOpen = keepref(Computed(@() canShow.value && needShow.value))
let isOpened = mkWatched(persist, "isOpened", needOpen.value)
let isPending = Watched(false)

let bagImgWidth = hdpxi(850)

eventbus_subscribe("ios.platform.onPermissionTrackCallback", function(p) {
  let { value } = p
  local result = value
  foreach(id, val in iOsPlaform)
    if (val == value && id.startswith("ATT_")) {
      result = id
      break
    }
  currentSettingForIDFA(result)
  isPending(false)
  log("ios.platform.onPermissionTrackCallback: ", result)
})

let bagImg = {
  rendObj = ROBJ_IMAGE
  size = [bagImgWidth, flex()]
  image = Picture($"ui/gameuiskin/data_bag.avif:0:P")
  keepAspect = true
}

let defenceAndGeoIcons = {
  size = [hdpx(150), flex()]
  flow = FLOW_VERTICAL
  gap = hdpx(100)
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_IMAGE
      size = [hdpx(150), hdpx(190)]
      image = Picture($"ui/gameuiskin/data_mark_defence.svg:0:P")
      keepAspect = KEEP_ASPECT_NONE
    }
    {
      rendObj = ROBJ_IMAGE
      size = [hdpx(140), hdpx(190)]
      image = Picture($"ui/gameuiskin/data_mark_geo.svg:0:P")
      keepAspect = KEEP_ASPECT_NONE
    }
  ]
}

let mkTextarea = @(text, maxWidth, ovr = {}) {
  maxWidth
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
}.__update(ovr)

let header = mkTextarea(loc("IDFA/header"), pw(100), fontBig)
let desc = mkTextarea(
  loc("IDFA/desc")
  pw(100)
  { margin = [hdpx(110), 0, 0, 0] }.__update(fontMedium)
)
let btnNext = mkSpinnerHideBlock(isPending, textButtonPrimary(
  utf8ToUpper(loc("mainmenu/btnNext"))
  function() {
    isPending(true)
    setTimeout(10, @() isForceClosed(true))
    requestTrackingPermission()
  }
))

let IDFAwnd = {
  rendObj = ROBJ_IMAGE
  size = flex()
  padding = saBordersRv
  image = mkColoredGradientY(0xFF253e52, 0xFF142a3b)
  flow = FLOW_HORIZONTAL
  gap = hdpx(70)
  onDetach = @() isPending(false)
  children = [
    bagImg
    defenceAndGeoIcons
    {
      size = flex()
      margin = [0, 0, 0, hdpx(70)]
      flow = FLOW_VERTICAL
      children = [
        header
        desc
        {
          size = flex()
          valign = ALIGN_BOTTOM
          halign = ALIGN_RIGHT
          children = btnNext
        }
      ]
    }
  ]
}

needOpen.subscribe(function(v) {
  if (v) {
    if (forceInGameAdTrackingMessage.value ?? abTests.value?.inGameAdTrackingMessage ?? false)
      isOpened(true)
    else
      requestTrackingPermission()
  }
})
needShow.subscribe(function(v) {
  if (!v)
    isOpened(false)
})

register_command(function() {
  forceInGameAdTrackingMessage.set(forceInGameAdTrackingMessage.get() != null
    ? null
    : !(abTests.value?.inGameAdTrackingMessage ?? false))
  dlog("inGameAdTrackingMessage", forceInGameAdTrackingMessage.value ?? abTests.value?.inGameAdTrackingMessage ?? false) // warning disable: -forbidden-function
}, "debug.abTests.inGameAdTrackingMessage")


registerScene(IDFA_SCENE_ID, IDFAwnd, null, isOpened)
