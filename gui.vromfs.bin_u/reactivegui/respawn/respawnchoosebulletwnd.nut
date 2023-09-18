from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("math")
let { defer } = require("dagor.workcycle")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { bulletsInfo, chosenBullets, setOrSwapUnitBullet, visibleBullets } = require("bulletsChoiceState.nut")
let { selSlot } = require("respawnState.nut")
let { createHighlight } = require("%rGui/tutorial/tutorialWnd/tutorialUtils.nut")
let { darkCtor } = require("%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut")
let mkBulletSlot = require("mkBulletSlot.nut")
let { textButtonPrimary, textButtonCommon } = require("%rGui/components/textButton.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let getBulletStats = require("bulletStats.nut")
let { mkAnimGrowLines, mkAGLinesCfgOrdered } = require("%rGui/components/animGrowLines.nut")
let { getAmmoNameText, getAmmoNameShortText, getAmmoTypeText, getAmmoAdviceText
} = require("%rGui/weaponry/weaponsVisual.nut")
let hasAddons = require("%appGlobals/updater/hasAddons.nut")
let { arrayByRows, isEqual } = require("%sqstd/underscore.nut")


let WND_UID = "respawn_choose_bullet_wnd"
let bulletSlotSize = [hdpxi(350), hdpxi(105)]
let minWndWidth = hdpx(700)
let minBulletWidth = max(bulletSlotSize[0], hdpx(150))
let bulletHeight = bulletSlotSize[1]
let statRowHeight = hdpx(28)
let lockedColor = 0xFFF04005
let wndKey = {}

let maxColumns = 2
let slotsGap = hdpx(5)
let bulletsColumnsCount = @(bSetsCount) min(maxColumns, bSetsCount)
let bulletsListWidth = @(columns) max((minBulletWidth * columns) + slotsGap, minWndWidth)

let openParams = mkWatched(persist, "openParams", null)
let curSlotName = mkWatched(persist, "curSlotName", "")
let savedSlotName = Computed(@() chosenBullets.value?[openParams.value?.slotIdx].name ?? "")
let wndAABB = Watched(null)
let usedBullets = Computed(function() {
  let { slotIdx = null } = openParams.value
  if (slotIdx == null)
    return null
  let res = {}
  foreach (idx, slot in chosenBullets.value)
    if (idx != slotIdx)
      res[slot.name] <- true
  return res
})

let hasBulletsVideo = Computed(@() hasAddons.value?.pkg_video ?? false)

let close = @() openParams(null)
savedSlotName.subscribe(@(v) curSlotName(v))
chosenBullets.subscribe(@(_) curSlotName(savedSlotName.value))
openParams.subscribe(@(_) wndAABB(null))
curSlotName.subscribe(@(_) defer( function() {
  let aabb = gui_scene.getCompAABBbyKey(wndKey)
  if (!isEqual(aabb, wndAABB.value))
    wndAABB(aabb)
}))

let function mkBulletButton(name, bSet, fromUnitTags, columns) {
  let isCurrent = Computed(@() name == curSlotName.value)
  let color = Computed(@() (fromUnitTags?.reqLevel ?? 0) > (selSlot.value?.level ?? 0) ? lockedColor
    : name in usedBullets.value ? 0xFF808080
    : 0xFFFFFFFF)
  let children = [
    @() mkBulletSlot(bSet, fromUnitTags,
      {
        watch = isCurrent
        size = columns < 2 ? [minWndWidth, bulletHeight] : bulletSlotSize
        halign = columns < 2 ? ALIGN_CENTER : null
        vplace = ALIGN_BOTTOM
        hplace = ALIGN_LEFT
        color = isCurrent.value ? 0xFF51C1D1 : 0x80296169
      })
    @() {
      watch = color
      hplace = ALIGN_LEFT
      rendObj = ROBJ_TEXT
      color = color.value
      padding = [0, 0, 0, hdpx(10)]
      text = getAmmoNameShortText(bSet)
      maxWidth = pw(100)
      behavior = Behaviors.Marquee
      delay = 0.5
      speed = hdpx(20)
    }.__update(fontTiny)
  ]
  let onClick = @() curSlotName(name)

  return @() {
    watch = isCurrent
    behavior = Behaviors.Button
    onClick
    children
    transitions = [{ prop = AnimProp.color, duration = 0.3, easing = InOutQuad }]
  }
}

let function bulletsList() {
  if (bulletsInfo.value == null)
    return { watch = bulletsInfo }
  let { bulletSets, bulletsOrder, fromUnitTags } = bulletsInfo.value
  let visibleBulletsList = bulletsOrder.filter(@(name) visibleBullets.value?[name] ?? false)
  let numberBullets = visibleBulletsList.len()
  let columns = bulletsColumnsCount(numberBullets)
  let rows = ceil(numberBullets.tofloat()/columns)
  return {
    watch = [bulletsInfo, visibleBullets]
    size = [bulletsListWidth(columns), bulletHeight * rows]
    flow = FLOW_VERTICAL
    gap = slotsGap
    children = arrayByRows(
      visibleBulletsList
        .map(@(name) mkBulletButton(name, bulletSets[name], fromUnitTags?[name], columns)), columns)
      .map(@(item) {
        flow = FLOW_HORIZONTAL
        children = item
        gap = slotsGap
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

let function mkShellVideo(videos, width) {
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

let function curBulletInfo() {
  if (bulletsInfo.value == null)
    return { watch = bulletsInfo }

  let { bulletSets, fromUnitTags, unitName } = bulletsInfo.value
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
    watch = [bulletsInfo, curSlotName]
    size = [flex(), SIZE_TO_CONTENT]
    minHeight = hdpx(500)
    padding = hdpx(15)
    flow = FLOW_VERTICAL
    children
  }
}

let function applyBullet() {
  setOrSwapUnitBullet(openParams.value?.slotIdx, curSlotName.value)
  close()
}

let applyText = utf8ToUpper(loc("msgbox/btn_choose"))
let function applyButton() {
  let { fromUnitTags = null } = bulletsInfo.value
  let { reqLevel = 0 } = fromUnitTags?[curSlotName.value]
  let isEnoughLevel = reqLevel <= (selSlot.value?.level ?? 0)
  let children = savedSlotName.value == curSlotName.value ? null
    : !isEnoughLevel ? textButtonCommon(applyText, @() openMsgBox({ text = loc("msg/reqPlatoonLevelToUse", { reqLevel }) }))
    : textButtonPrimary(applyText, applyBullet)
  return {
    watch = [savedSlotName, curSlotName, bulletsInfo, selSlot]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    size = [flex(), hdpx(110)]
    children
  }
}

let window = {
  key = wndKey
  onAttach = @() defer(@() wndAABB(gui_scene.getCompAABBbyKey(wndKey)))
  stopMouse = true
  vplace = ALIGN_CENTER
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_SOLID
  color = 0xA0000000
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  padding = [0, 0, hdpx(15), 0]
  maxHeight = saSize[1]
  children = [
    bulletsList
    curBulletInfo
    applyButton
  ]
}

let mkBg = @(box) box == null
  ? darkCtor({ t = 0, b = sh(100), l = 0, r = sw(100) })
  : {
      size = flex()
      children = createHighlight([box], @(_) null, darkCtor)
    }

let function animLines() {
  let res = { watch = [wndAABB, openParams] }
  if (openParams.value == null || wndAABB.value == null)
    return res

  let { bulletBox } = openParams.value
  let { t, b, r, l } = bulletBox
  let w = wndAABB.value
  let midY = (t + b) / 2
  let wMidY = (w.t + w.b) / 2
  //bulletBox
  let lines = [
    [
      [l, midY, l, t],
      [l, midY, l, b],
    ],
    [
      [l, t, r, t],
      [l, b, r, b],
    ],
    [
      [r, t, r, midY],
      [r, b, r, midY],
    ],
  ]

  //middleLine and left window line
  if (midY >= w.t && midY <= w.b)
    lines.append(
      [[r, midY, w.l, midY]],
      [
        [w.l, midY, w.l, w.t],
        [w.l, midY, w.l, w.b],
      ])
  else {
    let midX = (r + w.l) / 2
    lines.append(
      [[r, midY, midX, midY]],
      [[midX, midY, midX, wMidY]],
      [[midX, wMidY, w.l, wMidY]],
      [
        [w.l, wMidY, w.l, w.t],
        [w.l, wMidY, w.l, w.b],
      ])
  }

  //finalize window
  lines.append(
    [
      [w.l, w.t, w.r, w.t],
      [w.l, w.b, w.r, w.b],
    ],
    [
      [w.r, w.t, w.r, wMidY],
      [w.r, w.b, w.r, wMidY],
    ])

  return res.__update({
    size = flex()
    children = mkAnimGrowLines(mkAGLinesCfgOrdered(lines, hdpx(5000)))
  })
}

let function content() {
  if (openParams.value == null)
    return { watch = openParams }

  let { wndBox, bulletBox } = openParams.value
  return {
    watch = openParams
    size = flex()
    children = [
      mkBg(bulletBox)
      {
        size = flex()
        padding = wndBox == null ? null
          : [wndBox.t, sw(100) - wndBox.r, sh(100) - wndBox.b, wndBox.l]
        children = window
      }
      animLines
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

return @(slotIdx, bulletBox, wndBox) openParams({ slotIdx, bulletBox, wndBox })