from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("math")
let { hasAddons } = require("%appGlobals/updater/addonsState.nut")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { getAmmoNameText, getAmmoTypeText, getAmmoAdviceText } = require("%rGui/weaponry/weaponsVisual.nut")
let { mkPriorityUnseenMarkWatch } = require("%rGui/components/unseenMark.nut")
let { gradTexSize, mkGradientCtorRadial } = require("%rGui/style/gradients.nut")
let { markShellsSeenInBattle } = require("%rGui/respawn/respawnState.nut")
let getBulletStats = require("%rGui/bullets/bulletStats.nut")
let mkBulletSlot = require("%rGui/bullets/mkBulletSlot.nut")
let { mkVisibleBulletsList } = require("calcBullets.nut")
let { selectColor } = require("%rGui/style/stdColors.nut")


let bgSlotColor = selectColor
let slotBGImage = mkBitmapPictureLazy(gradTexSize, gradTexSize, mkGradientCtorRadial(bgSlotColor, 0 , 20, 55, 35, 0))

let bulletSlotSize = [hdpxi(350), hdpxi(105)]
let minWndWidth = hdpx(700)
let minBulletWidth = max(bulletSlotSize[0], hdpx(150))
let bulletHeight = bulletSlotSize[1]
let statRowHeight = hdpx(28)
let lockedColor = 0xFFF04005
let transDuration = 0.3
let opacityTransition = [{ prop = AnimProp.opacity, duration = transDuration, easing = InOutQuad }]

let maxColumns = 2
let slotsGap = hdpx(5)

let bulletsColumnsCount = @(bSetsCount) min(maxColumns, bSetsCount)
let bulletsListWidth = @(columns) max((minBulletWidth * columns) + slotsGap, minWndWidth)

let separator = { size = const [ flex(), hdpx(10) ] }

let mkStatTextarea = @(text, color = 0xFFC0C0C0) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  color
}.__update(fontVeryTiny)

let mkStatRow = @(nameText, valText, color = 0xFFC0C0C0) {
  size = [flex(), statRowHeight]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children = [
    {
      size = FLEX_H
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

function mkShellVideo(videos, width) {
  if (videos.len() == 0)
    return null
  let hasBulletsVideo = Computed(@() hasAddons.get()?.pkg_video ?? false)
  let idx = Watched(0)
  let watch = [idx, hasBulletsVideo]
  return @() !hasBulletsVideo.get() ? { watch }
    : {
        watch
        key = videos
        size = [width, (0.25 * width + 0.5).tointeger()]
        margin = const [hdpx(10), 0, 0, 0]
        hplace = ALIGN_CENTER
        children = {
          size = flex()
          key = idx.get()
          rendObj = ROBJ_MOVIE
          behavior = Behaviors.Movie
          loop = videos.len() == 1
          keepAspect = true
          movie = $"content/pkg_video/{videos[idx.get()]}"
          onFinish = @() idx.set((idx.get() + 1) % videos.len())
        }
      }
}

let mkCurListBulletInfo = @(bInfo, curSlotName, selSlot) function() {
  if (bInfo.get() == null)
    return { watch = bInfo }

  let { bulletSets, fromUnitTags, unitName } = bInfo.get()
  let { caliber = 0.0 } = bulletSets.findvalue(@(_) true)
  let bSet = bulletSets?[curSlotName.get()]
  let tags = fromUnitTags?[curSlotName.get()]
  let { reqLevel = 0 } = tags
  let isLockedBullet = reqLevel > (selSlot.get()?.level ?? 0)
  let columns = bulletsColumnsCount(bulletSets.len())
  let bulletName = getAmmoNameText(bSet)

  let adviceText = getAmmoAdviceText(bSet)
  let children = [
    {
      size = FLEX_H
      margin = const [0, 0, hdpx(10), 0]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = 0xFFFFFFFF
      text = loc($"bulletNameWithCaliber", { caliber, bulletName })
    }.__update(fontTiny)
    mkStatTextarea(getAmmoTypeText(bSet))
    adviceText != "" ? mkStatTextarea(adviceText) : null
    mkShellVideo(bSet?.shellAnimations ?? [], bulletsListWidth(columns))
    separator
    isLockedBullet ? mkStatRow(loc("requiredPlatoonLevel"), reqLevel, lockedColor) : null
  ]

  return {
    watch = [bInfo, curSlotName]
    key = "curBulletInfo" 
    size = FLEX_H
    minHeight = hdpx(500)
    padding = hdpx(15)
    flow = FLOW_VERTICAL
    children = children.filter(@(c) c != null)
      .extend(getBulletStats(bSet, tags, unitName).map(@(s) mkStatRow(s.nameText, s.valueText)))
  }
}

let mkBulletButton = kwarg(function mkBtn(
  chosenBullets,
  name,
  bSet,
  fromUnitTags,
  id,
  selSlot,
  hasUnseenShells,
  curSlotName,
  onClick
) {
  let isCurrent = Computed(@() name == curSlotName.get())
  let isLockedSlot = Computed(@() (fromUnitTags?.reqLevel ?? 0) > (selSlot.get()?.level ?? 0))
  let hasUnseenBullets = Computed(@() hasUnseenShells.get()?[selSlot.get()?.id ?? 0][name])
  let children = [
    @() {
      watch = isLockedSlot
      valign = ALIGN_TOP
      children = [
        @() mkBulletSlot(chosenBullets, bSet, fromUnitTags,
          {
            color = isCurrent.get() ? 0xFF51C1D1 : 0x402C2C2C
            opacity = isLockedSlot.get() ? 0.5 : 1
            rendObj = isCurrent.get() ? ROBJ_IMAGE : ROBJ_SOLID
            image = isCurrent.get() ? slotBGImage() : null
          }, {
            key = $"{name}_icon" 
          }, {
            watch = [ isCurrent, isLockedSlot ]
            key = name 
          })
        @() {
          watch = isCurrent
          size = const [hdpx(7), flex()]
          rendObj = ROBJ_BOX
          fillColor = selectColor
          opacity = isCurrent.get() ? 1 : 0
          transitions = opacityTransition
          hplace = id % 2 != 0 ? ALIGN_RIGHT : ALIGN_LEFT
          pos = [id % 2 != 0 ? hdpx(7) : hdpx(-7), 0]
        }
        isLockedSlot.get()
          ? {
            rendObj = ROBJ_IMAGE
            pos = [0, -hdpx(5)]
            size = hdpxi(70)
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
          size = const [flex(), hdpx(108)]
          rendObj = ROBJ_BOX
          borderWidth = isLockedSlot.get() ? 0 : hdpxi(4)
        }
      ]
    }
    mkPriorityUnseenMarkWatch(hasUnseenBullets, { vplace = ALIGN_TOP, hplace = ALIGN_RIGHT, margin = hdpx(7) })
  ]

  return {
    behavior = Behaviors.Button
    onClick = @() onClick(name)
    children
    transitions = [{ prop = AnimProp.color, duration = 0.3, easing = InOutQuad }]
  }
})

let mkBulletsList = @(bInfo, visibleBullets, chosenBullets, openedSlot, selSlot, hasUnseenShells, curSlotName, onClickBtn) function() {
  if (bInfo.get() == null)
    return { watch = bInfo }

  let { bulletSets, bulletsOrder, fromUnitTags } = bInfo.get()
  let visibleBulletsList = mkVisibleBulletsList(bulletsOrder, fromUnitTags, visibleBullets.get(), openedSlot.get())
  let numberBullets = visibleBulletsList.len()
  let columns = bulletsColumnsCount(numberBullets)
  let rows = ceil(numberBullets.tofloat() / columns)
  let rowsWithBullets = arrayByRows(
    visibleBulletsList.map(@(name, id) mkBulletButton({
      chosenBullets,
      name,
      bSet = bulletSets[name],
      fromUnitTags = fromUnitTags?[name],
      id,
      selSlot,
      hasUnseenShells,
      curSlotName,
      onClick = onClickBtn
    })),
    columns)
  return {
    watch = [bInfo, visibleBullets, openedSlot]
    key = "bulletsList" 
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
        if (selSlot.get()?.name)
          markShellsSeenInBattle(selSlot.get().name, visibleBulletsList)
      }
    })
  }
}

return {
  mkBulletsList = kwarg(mkBulletsList)
  mkCurListBulletInfo
  mkShellVideo
}