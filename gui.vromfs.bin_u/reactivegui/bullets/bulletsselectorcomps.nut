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
let { BS_UNLOCKED, BS_VISIBLE, BS_ONLY_EXTERNAL_SLOT, BS_BR_PICKUP } = require("bulletsConst.nut")
let { selectColor, textColor } = require("%rGui/style/stdColors.nut")


let slotBGImage = mkBitmapPictureLazy(gradTexSize, gradTexSize, mkGradientCtorRadial(selectColor, 0, 20, 55, 35, 0))

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

let separator = { size = const [ FLEX, hdpx(10) ] }

let mkStatTextarea = @(text, color = 0xFFC0C0C0) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  color
}.__update(fontVeryTiny)

let mkStatRow = @(nameText, valText, color = 0xFFC0C0C0) {
  size = [FLEX, statRowHeight]
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
          size = FLEX
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

let mkCurListBulletInfo = @(bInfo, curSlotName, selSlot, bStatus) function() {
  if (bInfo.get() == null)
    return { watch = bInfo }

  let { bulletSets, fromUnitTags, unitName } = bInfo.get()
  let { caliber = 0.0 } = bulletSets.findvalue(@(_) true)
  let bSet = bulletSets?[curSlotName.get()]
  let tags = fromUnitTags?[curSlotName.get()]
  let { reqModification = null, reqLevel = 0 } = tags
  let reqLevelFinal = selSlot.get()?.modPresetCfg?[reqModification].reqLevel ?? reqLevel
  let status = bStatus.get()?[curSlotName.get()] ?? 0

  let columns = bulletsColumnsCount(bulletSets.len())
  let bulletName = getAmmoNameText(bSet)

  let adviceText = getAmmoAdviceText(bSet)
  let children = [
    {
      size = FLEX_H
      margin = const [0, 0, hdpx(10), 0]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = textColor
      text = loc($"bulletNameWithCaliber", { caliber, bulletName })
    }.__update(fontTiny),
    mkStatTextarea(getAmmoTypeText(bSet)),
    adviceText != "" ? mkStatTextarea(adviceText) : null,
    mkShellVideo(bSet?.shellAnimations ?? [], bulletsListWidth(columns)),
    separator,
    (status & BS_UNLOCKED) != 0 ? null
      : reqLevelFinal > (selSlot.get()?.level ?? 0) ? mkStatRow(loc("requiredUnitLevel"), reqLevelFinal, lockedColor)
      : mkStatTextarea(loc("respawn/need_to_buy_weapon"), lockedColor)
  ]

  return {
    watch = [bInfo, curSlotName, bStatus]
    key = "curBulletInfo" 
    size = FLEX_H
    minHeight = hdpx(500)
    padding = hdpx(15)
    flow = FLOW_VERTICAL
    children = children.filter(@(c) c != null)
      .extend(getBulletStats(bSet, tags, unitName).map(@(s) mkStatRow(s.nameText, s.valueText)))
  }
}

let mkBulletButton = kwarg(function mkBtn(chosenBullets, name, bSet, status, fromUnitTags, id,
  slot, hasUnseenShells, curSlotName, onClick
) {
  let isCurrent = Computed(@() name == curSlotName.get())
  let isLockedSlot = (status & BS_UNLOCKED) == 0
  let hasUnseenBullets = Computed(@() hasUnseenShells.get()?[slot?.id ?? 0][name])
  let reqLevel = slot.modPresetCfg?[fromUnitTags?.reqModification].reqLevel ?? fromUnitTags?.reqLevel ?? 0
  let isLockedByLevel = isLockedSlot && reqLevel > slot.level
  let children = [
    {
      valign = ALIGN_TOP
      children = [
        @() mkBulletSlot(chosenBullets, bSet, fromUnitTags,
          {
            color = isCurrent.get() ? textColor : 0x402C2C2C
            opacity = isLockedSlot ? 0.5 : 1
            rendObj = isCurrent.get() ? ROBJ_IMAGE : ROBJ_SOLID
            image = isCurrent.get() ? slotBGImage() : null
          },
          { key = $"{name}_icon" }, 
          {
            watch = isCurrent
            key = name 
          })
        @() {
          watch = isCurrent
          size = const [hdpx(7), FLEX]
          rendObj = ROBJ_BOX
          fillColor = selectColor
          opacity = isCurrent.get() ? 1 : 0
          transitions = opacityTransition
          hplace = id % 2 != 0 ? ALIGN_RIGHT : ALIGN_LEFT
          pos = [id % 2 != 0 ? hdpx(7) : hdpx(-7), 0]
        }
        !isLockedSlot ? null
          : isLockedByLevel
            ? {
                rendObj = ROBJ_IMAGE
                pos = [0, -hdpx(5)]
                size = hdpxi(70)
                image = Picture("ui/gameuiskin#lock_unit.svg")
                keepAspect = KEEP_ASPECT_FIT
                vplace = ALIGN_BOTTOM
                children = {
                  rendObj = ROBJ_TEXT
                  text = reqLevel
                  hplace = ALIGN_CENTER
                  vplace = ALIGN_CENTER
                  pos = [hdpx(1), hdpx(10)]
                }.__update(fontVeryTiny)
              }
          : null
        {
          size = const [FLEX, hdpx(98)]
          rendObj = ROBJ_BOX
          borderWidth = isLockedSlot ? 0 : hdpxi(4)
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

let mkBulletsList = @(bInfo, bulletsStatus, chosenBullets, openedSlot, selSlot, hasUnseenShells, curSlotName, onClickBtn) function() {
  if (bInfo.get() == null || selSlot.get() == null)
    return { watch = [bInfo, selSlot] }

  let { bulletSets, bulletsOrder, fromUnitTags } = bInfo.get()
  let visibleBulletsList = bulletsOrder.filter(function(name) {
    let status = bulletsStatus.get()?[name] ?? 0
    return (status & BS_VISIBLE) != 0 && (status & BS_BR_PICKUP) == 0
      && (openedSlot.get() != 0 || (status & BS_ONLY_EXTERNAL_SLOT) == 0)
  })

  let numberBullets = visibleBulletsList.len()
  let columns = max(1, bulletsColumnsCount(numberBullets))
  let rows = ceil(numberBullets.tofloat() / columns)
  let rowsWithBullets = arrayByRows(
    visibleBulletsList.map(@(name, id) mkBulletButton({
      chosenBullets,
      name,
      bSet = bulletSets[name],
      fromUnitTags = fromUnitTags?[name],
      status = bulletsStatus.get()?[name]
      id,
      slot = selSlot.get(),
      hasUnseenShells,
      curSlotName,
      onClick = onClickBtn
    })),
    columns)
  return {
    watch = [bInfo, selSlot, bulletsStatus, openedSlot]
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
      size = FLEX
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