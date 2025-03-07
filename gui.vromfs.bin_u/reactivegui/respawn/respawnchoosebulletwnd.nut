from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("math")
let { defer } = require("dagor.workcycle")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { bulletsInfo, bulletsSecInfo, chosenBullets, chosenBulletsSec, setOrSwapUnitBullet,
  visibleBullets, visibleBulletsSec, BULLETS_PRIM_SLOTS
} = require("bulletsChoiceState.nut")
let { selSlot, hasUnseenShellsBySlot, saveSeenShells } = require("respawnState.nut")
let { mkCutBg } = require("%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut")
let mkBulletSlot = require("mkBulletSlot.nut")
let { textButtonPrimary, textButtonCommon } = require("%rGui/components/textButton.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let getBulletStats = require("bulletStats.nut")
let { getAmmoNameText, getAmmoTypeText, getAmmoAdviceText } = require("%rGui/weaponry/weaponsVisual.nut")
let hasAddons = require("%appGlobals/updater/hasAddons.nut")
let { arrayByRows, isEqual } = require("%sqstd/underscore.nut")
let { mkPriorityUnseenMarkWatch } = require("%rGui/components/unseenMark.nut")
let { mkGradientCtorDoubleSideY, gradTexSize, mkGradientCtorRadial } = require("%rGui/style/gradients.nut")
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { sendPlayerActivityToServer } = require("playerActivity.nut")

let bgSlotColor = 0xFF51C1D1
let slotBGImage = mkBitmapPictureLazy(gradTexSize, gradTexSize,
  mkGradientCtorRadial(bgSlotColor, 0 , 20, 55, 35, 0))

let WND_UID = "respawn_choose_bullet_wnd"
let bulletSlotSize = [hdpxi(350), hdpxi(105)]
let minWndWidth = hdpx(700)
let minBulletWidth = max(bulletSlotSize[0], hdpx(150))
let bulletHeight = bulletSlotSize[1]
let statRowHeight = hdpx(28)
let lockedColor = 0xFFF04005
let lineColor = 0xFF75D0E7
let wndKey = {}
let transDuration = 0.3
let lineGradient = mkBitmapPictureLazy(4, gradTexSize, mkGradientCtorDoubleSideY(0, lineColor, 0.25))
let opacityTransition = [{ prop = AnimProp.opacity, duration = transDuration, easing = InOutQuad }]

let maxColumns = 2
let slotsGap = hdpx(5)
let bulletsColumnsCount = @(bSetsCount) min(maxColumns, bSetsCount)
let bulletsListWidth = @(columns) max((minBulletWidth * columns) + slotsGap, minWndWidth)

let openedSlot = Watched(-1)
let openParams = mkWatched(persist, "openParams", null)
let curSlotName = mkWatched(persist, "curSlotName", "")
let isBulletSec = Computed(@() openedSlot.get() >= BULLETS_PRIM_SLOTS)
let savedSlotName = Computed(function() {
  let bullets = isBulletSec.get() ? chosenBulletsSec.get() : chosenBullets.get()
  return openParams.get()?.slotIdx == null ? curSlotName.get()
    : (bullets?[openParams.get().slotIdx % BULLETS_PRIM_SLOTS].name ?? curSlotName.get())
})
let wndAABB = Watched(null)

let hasBulletsVideo = Computed(@() hasAddons.value?.pkg_video ?? false)

function close(){
  openedSlot(-1)
  openParams(null)
  sendPlayerActivityToServer()
}
savedSlotName.subscribe(@(v) curSlotName(v))
chosenBullets.subscribe(@(_) curSlotName(savedSlotName.value))
chosenBulletsSec.subscribe(@(_) curSlotName.set(savedSlotName.get()))
openParams.subscribe(@(_) wndAABB(null))
curSlotName.subscribe(@(_) defer( function() {
  let aabb = gui_scene.getCompAABBbyKey(wndKey)
  if (!isEqual(aabb, wndAABB.value))
    wndAABB(aabb)
}))

function mkBulletButton(isSecondary, name, bSet, fromUnitTags, id) {
  let isCurrent = Computed(@() name == curSlotName.value)
  let isLockedSlot = Computed(@() (fromUnitTags?.reqLevel ?? 0) > (selSlot.value?.level ?? 0))
  let hasUnseenBullets = Computed(@() hasUnseenShellsBySlot.value?[selSlot.value?.id ?? 0][name])
  let children = [
    @() {
      watch = isLockedSlot
      valign = ALIGN_TOP
      children = [
        @() mkBulletSlot(isSecondary, bSet, fromUnitTags,
          {
            color = isCurrent.value ? 0xFF51C1D1 : 0x402C2C2C
            opacity = isLockedSlot.value ? 0.5 : 1
            rendObj = isCurrent.value ? ROBJ_IMAGE : ROBJ_SOLID
            image = isCurrent.value ? slotBGImage() : null
          }, {
            key = $"{name}_icon" //for UI tutorial
          }, {
            watch = [ isCurrent, isLockedSlot ]
            key = name //for UI tutorial
          })
        @() {
          watch = isCurrent
          size = [hdpx(9), flex()]
          rendObj = ROBJ_IMAGE
          image = lineGradient()
          opacity = isCurrent.value ? 1 : 0
          transitions = opacityTransition
          hplace = id % 2 != 0 ? ALIGN_RIGHT : ALIGN_LEFT
          pos = [id % 2 != 0 ? hdpx(15) : hdpx(-15), 0]
        }
        isLockedSlot.value
          ? {
            rendObj = ROBJ_IMAGE
            pos = [0, -hdpx(5)]
            size = [hdpxi(70), hdpxi(70)]
            image = Picture("ui/gameuiskin#lock_unit.svg")
            keepAspect = KEEP_ASPECT_FIT
            vplace = ALIGN_BOTTOM
            children = {
              rendObj = ROBJ_TEXT
              text = fromUnitTags.reqLevel
              hplace = ALIGN_CENTER
              vplace = ALIGN_CENTER
              pos = [hdpx(1), hdpx(10)]
            }.__update(fontVeryTiny)
          }
          : null
        @() {
          watch = isLockedSlot
          size = [flex(), hdpx(108)]
          rendObj = ROBJ_BOX
          borderWidth = isLockedSlot.value ? 0 : hdpxi(4)
        }
      ]
    }
    mkPriorityUnseenMarkWatch(hasUnseenBullets, { vplace = ALIGN_TOP, hplace = ALIGN_RIGHT, margin = [hdpx(7), hdpx(7)] })
  ]
  function onClick() {
    sendPlayerActivityToServer()
    curSlotName(name)
  }

  return {
    behavior = Behaviors.Button
    onClick
    children
    transitions = [{ prop = AnimProp.color, duration = 0.3, easing = InOutQuad }]
  }
}

function bulletsList() {
  let bInfo = isBulletSec.get() ? bulletsSecInfo.get() : bulletsInfo.get()
  if (bInfo == null)
    return { watch = [bulletsInfo, bulletsSecInfo, isBulletSec] }

  let { bulletSets, bulletsOrder, fromUnitTags } = bInfo
  let visibleBulletsList = bulletsOrder.filter(function(name) {
    let { isExternalAmmo = false } = fromUnitTags?[name]
    let bullets = isBulletSec.get() ? visibleBulletsSec.get() : visibleBullets.get()
    let isVisible = bullets?[name] ?? false
    return openedSlot.get() == 0 ? isVisible && !isExternalAmmo : isVisible
  })
  let numberBullets = visibleBulletsList.len()
  let columns = bulletsColumnsCount(numberBullets)
  let rows = ceil(numberBullets.tofloat() / columns)
  let rowsWithBullets = arrayByRows(visibleBulletsList.map(@(name, id)
    mkBulletButton(isBulletSec.get(), name, bulletSets[name], fromUnitTags?[name], id)), columns)
  return {
    watch = [bulletsInfo, bulletsSecInfo, openedSlot, isBulletSec, visibleBullets, visibleBulletsSec]
    key = "bulletsList" //for UI tutorial
    size = [bulletsListWidth(columns), bulletHeight * rows]
    flow = FLOW_VERTICAL
    gap = slotsGap
    children = rowsWithBullets.map(@(item) {
      flow = FLOW_HORIZONTAL
      children = item
      gap = slotsGap
    }).append({
      key = "saveSection"
      size = flex()
      function onDetach() {
        if (selSlot.get()?.name != null)
          saveSeenShells(selSlot.get().name, visibleBulletsList.map(@(name) name))
      }
    })
  }
}

let separator = { size = [ flex(), hdpx(10) ] }

let mkStatRow = @(nameText, valText, color = 0xFFC0C0C0) {
  size = [flex(), statRowHeight]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXT
      color
      text = nameText
      behavior = Behaviors.Marquee
      delay = defMarqueeDelay
      speed = hdpx(30)
    }.__update(fontVeryTiny)
    {
      rendObj = ROBJ_TEXT
      color
      text = valText
    }.__update(fontVeryTiny)
  ]
}

let mkStatTextarea = @(text, color = 0xFFC0C0C0) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  color
}.__update(fontVeryTiny)

function mkShellVideo(videos, width) {
  if (videos.len() == 0)
    return null
  let idx = Watched(0)
  let watch = [idx, hasBulletsVideo]
  return @() !hasBulletsVideo.value ? { watch }
    : {
        watch
        key = videos
        size = [width, (0.25 * width + 0.5).tointeger()]
        margin = [hdpx(10), 0, 0, 0]
        hplace = ALIGN_CENTER
        children = {
          size = flex()
          key = idx.value
          rendObj = ROBJ_MOVIE
          behavior = Behaviors.Movie
          loop = videos.len() == 1
          keepAspect = true
          movie = $"content/pkg_video/{videos[idx.value]}"
          onFinish = @() idx((idx.value + 1) % videos.len())
        }
      }
}

function curBulletInfo() {
  let bInfo = isBulletSec.get() ? bulletsSecInfo.get() : bulletsInfo.get()
  if (bInfo == null)
    return { watch = [bulletsInfo, bulletsSecInfo, isBulletSec] }

  let { bulletSets, fromUnitTags, unitName } = bInfo
  let { caliber = 0.0 } = bulletSets.findvalue(@(_) true)
  let bSet = bulletSets?[curSlotName.value]
  let tags = fromUnitTags?[curSlotName.value]
  let { reqLevel = 0 } = tags
  let columns = bulletsColumnsCount(bulletSets.len())
  let bulletName = getAmmoNameText(bSet)
  let children = [
    {
      size = [ flex(), SIZE_TO_CONTENT ]
      margin = [0, 0, hdpx(10), 0]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = 0xFFFFFFFF
      text = loc($"bulletNameWithCaliber", {caliber, bulletName})
    }.__update(fontTiny)
    mkStatTextarea(getAmmoTypeText(bSet))
  ]

  let adviceText = getAmmoAdviceText(bSet)
  if (adviceText != "")
    children.append(mkStatTextarea(adviceText))
  children.append(mkShellVideo(bSet?.shellAnimations ?? [], bulletsListWidth(columns)))

  children.append(separator)
  if (reqLevel > (selSlot.value?.level ?? 0))
    children.append(mkStatRow(loc("requiredPlatoonLevel"), reqLevel, lockedColor))
  children.extend(getBulletStats(bSet, tags, unitName).map(@(s) mkStatRow(s.nameText, s.valueText)))

  return {
    watch = [bulletsInfo, bulletsSecInfo, isBulletSec, curSlotName]
    key = "curBulletInfo" //for UI tutorial
    size = [flex(), SIZE_TO_CONTENT]
    minHeight = hdpx(500)
    padding = hdpx(15)
    flow = FLOW_VERTICAL
    children
  }
}

function applyBullet() {
  let { slotIdx = null } = openParams.get()
  if (slotIdx != null)
    setOrSwapUnitBullet(slotIdx, curSlotName.get())
  close()
}

let applyText = utf8ToUpper(loc("msgbox/btn_choose"))
function applyButton() {
  let { fromUnitTags = null } = isBulletSec.get() ? bulletsSecInfo.get() : bulletsInfo.get()
  let { reqLevel = 0 } = fromUnitTags?[curSlotName.value]
  let isEnoughLevel = reqLevel <= (selSlot.value?.level ?? 0)
  let children = savedSlotName.value == curSlotName.value
      ? textButtonCommon(utf8ToUpper(loc("mainmenu/btnClose")),
        close,
        { ovr = { key = "closeButton" }}) // key for UI tutorial
    : !isEnoughLevel
      ? textButtonCommon(applyText,
        @() openMsgBox({ text = loc("msg/reqPlatoonLevelToUse", { reqLevel }) }),
        { ovr = { key = "errorButton" }}) // key for UI tutorial
    : textButtonPrimary(applyText,
      applyBullet,
      { ovr = { key = "applyButton" }}) // key for UI tutorial
  return {
    watch = [savedSlotName, curSlotName, bulletsInfo, bulletsSecInfo, isBulletSec, selSlot]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    size = [flex(), hdpx(110)]
    children
  }
}

let window = {
  onAttach = @() defer(@() wndAABB(gui_scene.getCompAABBbyKey(wndKey)))
  key = "bulletsInfo" //for UI tutorial
  stopMouse = true
  vplace = ALIGN_CENTER
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_SOLID
  color = 0xA0000000
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  padding = hdpx(20)
  maxHeight = saSize[1]
  children = [
    bulletsList
    curBulletInfo
    applyButton
  ]
}

function content() {
  if (openParams.value == null)
    return { watch = openParams }

  let { wndBox, bulletBox } = openParams.value
  return {
    watch = openParams
    size = flex()
    children = [
      mkCutBg([bulletBox])
      {
        size = flex()
        padding = wndBox == null ? null
          : [wndBox.t, sw(100) - wndBox.r, sh(100) - wndBox.b, wndBox.l]
        children = window
      }
    ]
  }
}

let openImpl = @() addModalWindow({
  key = WND_UID
  size = flex()
  children = content
  onClick = close
})

if (openParams.value != null)
  openImpl()
openParams.subscribe(@(v) v != null ? openImpl() : removeModalWindow(WND_UID))

function showRespChooseWnd(slotIdx, bulletBox, wndBox) {
  openParams({ slotIdx, bulletBox, wndBox })
  openedSlot(slotIdx)
}
return {
  showRespChooseWnd
  openedSlot
  curSlotName
  applyBullet
}