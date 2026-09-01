from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import defer
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/underscore.nut" import isEqual
from "%rGui/bullets/bulletsConst.nut" import BULLETS_PRIM_SLOTS, BS_UNLOCKED
from "%rGui/bullets/bulletsSelectorComps.nut" import mkBulletsList, mkCurListBulletInfo
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/textButton.nut" import textButtonCommon, textButtonPrimary, textButtonInactive
from "%rGui/respawn/bulletsChoiceState.nut" import bulletsInfo, bulletsSecInfo, bulletsSpecInfo, chosenBullets,
  chosenBulletsSec, chosenBulletsSpec, setOrSwapCurUnitBullet, bulletsStatus, bulletsStatusSec, bulletsStatusSpec,
  secBulletsSlots
from "%rGui/respawn/playerActivity.nut" import sendPlayerActivityToServer
from "%rGui/respawn/respawnState.nut" import selSlot, hasUnseenShellsBySlot
from "%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut" import mkCutBg


const WND_UID = "respawn_choose_bullet_wnd"
let wndKey = {}

let openedSlot = Watched(-1)
let openParams = mkWatched(persist, "openParams", null)
let curSlotName = mkWatched(persist, "curSlotName", "")
let isBulletSec = Computed(@() openedSlot.get() >= BULLETS_PRIM_SLOTS)
let isBulletSpec = Computed(@() openedSlot.get() >= BULLETS_PRIM_SLOTS + secBulletsSlots.get())
let savedSlotName = Computed(function() {
  let bullets = isBulletSpec.get()
      ? chosenBulletsSpec.get()
    : isBulletSec.get()
      ? chosenBulletsSec.get()
    : chosenBullets.get()
  return openParams.get()?.slotIdx == null ? curSlotName.get()
    : (bullets?[openParams.get().slotIdx % (BULLETS_PRIM_SLOTS + (isBulletSpec.get() ? secBulletsSlots.get() : 0))].name ?? curSlotName.get())
})
let wndAABB = Watched(null)

function close(){
  openedSlot.set(-1)
  openParams.set(null)
  sendPlayerActivityToServer()
}
savedSlotName.subscribe(@(v) curSlotName.set(v))
chosenBullets.subscribe(@(_) curSlotName.set(savedSlotName.get()))
chosenBulletsSec.subscribe(@(_) curSlotName.set(savedSlotName.get()))
chosenBulletsSpec.subscribe(@(_) curSlotName.set(savedSlotName.get()))
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
  let { fromUnitTags = null } = isBulletSpec.get() ? bulletsSpecInfo.get()
    : isBulletSec.get() ? bulletsSecInfo.get()
    : bulletsInfo.get()
  let allStatus = isBulletSpec.get() ? bulletsStatusSpec.get()
    : isBulletSec.get() ? bulletsStatusSec.get()
    : bulletsStatus.get()
  let status = allStatus?[curSlotName.get()] ?? 0
  let { reqModification = null, reqLevel = 0 } = fromUnitTags?[curSlotName.get()]
  let reqLevelFinal = selSlot.get()?.modPresetCfg?[reqModification].reqLevel ?? reqLevel
  let isEnoughLevel = reqLevelFinal <= (selSlot.get()?.level ?? 0)
  let children = savedSlotName.get() == curSlotName.get()
      ? textButtonCommon(utf8ToUpper(loc("mainmenu/btnClose")),
        close,
        { ovr = { key = "closeButton" }}) 
    : (status & BS_UNLOCKED) != 0
      ? textButtonPrimary(applyText,
          applyBullet,
          { ovr = { key = "applyButton" }}) 
    : !isEnoughLevel
      ? textButtonInactive(applyText,
        @() openMsgBox({ text = loc("msg/reqUnitLevelToUse", { reqLevel = reqLevelFinal }) }),
        { ovr = { key = "errorButton" }}) 
    : textButtonInactive(applyText,
        @() openMsgBox({ text = loc("respawn/need_to_buy_weapon") }),
        { ovr = { key = "errorButton" }}) 
  return {
    watch = [savedSlotName, curSlotName, bulletsInfo, bulletsSecInfo, bulletsSpecInfo, isBulletSec, isBulletSpec, selSlot]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    size = const [FLEX, hdpx(110)]
    children
  }
}

function onClickBulletBtn(name) {
  sendPlayerActivityToServer()
  curSlotName.set(name)
}

function bulletContent() {
  let bInfo = Computed(@() isBulletSpec.get()
      ? bulletsSpecInfo.get()
    : isBulletSec.get()
      ? bulletsSecInfo.get()
    : bulletsInfo.get())
  let bStatus = Computed(@() isBulletSpec.get()
      ? bulletsStatusSpec.get()
    : isBulletSec.get()
      ? bulletsStatusSec.get()
    : bulletsStatus.get())
  let cBullets = Computed(@() isBulletSpec.get()
      ? chosenBulletsSpec.get()
    : isBulletSec.get()
      ? chosenBulletsSec.get()
    : chosenBullets.get())
  return @() {
    watch = [bInfo, bStatus, cBullets]
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = hdpx(5)
    children = [
      mkBulletsList({
        bInfo,
        bulletsStatus = bStatus,
        chosenBullets = cBullets,
        openedSlot,
        selSlot,
        hasUnseenShells = hasUnseenShellsBySlot,
        curSlotName,
        onClickBtn = onClickBulletBtn
      })
      mkCurListBulletInfo(bInfo, curSlotName, selSlot, bStatus)
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
    size = FLEX
    children = [
      mkCutBg([bulletBox])
      {
        size = FLEX
        padding = wndBox == null ? null
          : [wndBox.t, sw(100) - wndBox.r, sh(100) - wndBox.b, wndBox.l]
        children = window
      }
    ]
  }
}

let openImpl = @() addModalWindow({
  key = WND_UID
  size = FLEX
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