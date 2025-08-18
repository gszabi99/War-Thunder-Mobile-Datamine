from "%globalsDarg/darg_library.nut" import *
let { defer } = require("dagor.workcycle")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { bulletsInfo, bulletsSecInfo, chosenBullets, chosenBulletsSec, setOrSwapCurUnitBullet,
  visibleBullets, visibleBulletsSec
} = require("%rGui/respawn/bulletsChoiceState.nut")
let { selSlot, hasUnseenShellsBySlot } = require("%rGui/respawn/respawnState.nut")
let { mkCutBg } = require("%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut")
let { textButtonPrimary, textButtonCommon } = require("%rGui/components/textButton.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { sendPlayerActivityToServer } = require("%rGui/respawn/playerActivity.nut")
let { BULLETS_PRIM_SLOTS } = require("%rGui/bullets/bulletsConst.nut")
let { mkBulletsList, mkCurListBulletInfo } = require("%rGui/bullets/bulletsSelectorComps.nut")


let WND_UID = "respawn_choose_bullet_wnd"
let wndKey = {}

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

function close(){
  openedSlot(-1)
  openParams.set(null)
  sendPlayerActivityToServer()
}
savedSlotName.subscribe(@(v) curSlotName.set(v))
chosenBullets.subscribe(@(_) curSlotName.set(savedSlotName.get()))
chosenBulletsSec.subscribe(@(_) curSlotName.set(savedSlotName.get()))
openParams.subscribe(@(_) wndAABB.set(null))
curSlotName.subscribe(@(_) defer( function() {
  let aabb = gui_scene.getCompAABBbyKey(wndKey)
  if (!isEqual(aabb, wndAABB.get()))
    wndAABB.set(aabb)
}))

function applyBullet() {
  let { slotIdx = null } = openParams.get()
  if (slotIdx != null)
    setOrSwapCurUnitBullet(slotIdx, curSlotName.get())
  close()
}

let applyText = utf8ToUpper(loc("msgbox/btn_choose"))
function applyButton() {
  let { fromUnitTags = null } = isBulletSec.get() ? bulletsSecInfo.get() : bulletsInfo.get()
  let { reqLevel = 0 } = fromUnitTags?[curSlotName.get()]
  let isEnoughLevel = reqLevel <= (selSlot.get()?.level ?? 0)
  let children = savedSlotName.get() == curSlotName.get()
      ? textButtonCommon(utf8ToUpper(loc("mainmenu/btnClose")),
        close,
        { ovr = { key = "closeButton" }}) 
    : !isEnoughLevel
      ? textButtonCommon(applyText,
        @() openMsgBox({ text = loc("msg/reqPlatoonLevelToUse", { reqLevel }) }),
        { ovr = { key = "errorButton" }}) 
    : textButtonPrimary(applyText,
      applyBullet,
      { ovr = { key = "applyButton" }}) 
  return {
    watch = [savedSlotName, curSlotName, bulletsInfo, bulletsSecInfo, isBulletSec, selSlot]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    size = const [flex(), hdpx(110)]
    children
  }
}

function onClickBulletBtn(name) {
  sendPlayerActivityToServer()
  curSlotName.set(name)
}

function bulletContent() {
  let bInfo = Computed(@() isBulletSec.get() ? bulletsSecInfo.get() : bulletsInfo.get())
  let visBullets = Computed(@() isBulletSec.get() ? visibleBulletsSec.get() : visibleBullets.get())
  let cBullets = Computed(@() isBulletSec.get() ? chosenBulletsSec.get() : chosenBullets.get())
  return @() {
    watch = [bInfo, visBullets, cBullets]
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    children = [
      mkBulletsList({
        bInfo,
        visibleBullets = visBullets,
        chosenBullets = cBullets,
        openedSlot,
        selSlot,
        hasUnseenShells = hasUnseenShellsBySlot,
        curSlotName,
        onClickBtn = onClickBulletBtn
      })
      mkCurListBulletInfo(bInfo, curSlotName, selSlot)
      applyButton
    ]
  }
}

let window = {
  onAttach = @() defer(@() wndAABB.set(gui_scene.getCompAABBbyKey(wndKey)))
  key = "bulletsInfo" 
  stopMouse = true
  vplace = ALIGN_CENTER
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_SOLID
  color = 0xA0000000
  padding = hdpx(20)
  maxHeight = saSize[1]
  children = bulletContent()
}

function content() {
  if (openParams.get() == null)
    return { watch = openParams }

  let { wndBox, bulletBox } = openParams.get()
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

if (openParams.get() != null)
  openImpl()
openParams.subscribe(@(v) v != null ? openImpl() : removeModalWindow(WND_UID))

function showRespChooseWnd(slotIdx, bulletBox, wndBox) {
  openParams.set({ slotIdx, bulletBox, wndBox })
  openedSlot.set(slotIdx)
}
return {
  showRespChooseWnd
  openedSlot
  curSlotName
  applyBullet
}