from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { round, sqrt } = require("math")
let { deferOnce } = require("dagor.workcycle")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { isRespawnAttached, respawnSlots, respawn, cancelRespawn, selSlot, playerSelectedSlotIdx
} = require("respawnState.nut")
let { bulletsToSpawn } = require("bulletsChoiceState.nut")
let { slotAABB, selSlotLinesSteps, lineSpeed } = require("respawnAnimState.nut")
let { isRespawnInProgress, isRespawnStarted, respawnUnitInfo, timeToRespawn
} = require("%appGlobals/clientState/respawnStateBase.nut")
let { getUnitPresentation, getPlatoonName, getUnitClassFontIcon, getUnitLocId
} = require("%appGlobals/unitPresentation.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { premiumTextColor } = require("%rGui/style/stdColors.nut")
let mkMenuButton = require("%rGui/hud/mkMenuButton.nut")
let { textButtonFaded, textButtonPrimary } = require("%rGui/components/textButton.nut")
let scoreBoard = require("%rGui/hud/scoreBoard.nut")
let { unitPlateWidth, unitPlateHeight, unitSelUnderlineFullHeight, mkUnitPrice,
  mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitTexts, mkUnitSlotLockedLine, mkUnitSelectedUnderlineVert
} = require("%rGui/unit/components/unitPlateComp.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
let { logerrHintsBlock } = require("%rGui/hudHints/hintBlocks.nut")
let { mkLevelBg, unitExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let respawnMap = require("respawnMap.ui.nut")
let respawnBullets = require("respawnBullets.nut")
let { bg, headerText, header, gap, headerMarquee } = require("respawnComps.nut")
let { mkAnimGrowLines, mkAGLinesCfgOrdered } = require("%rGui/components/animGrowLines.nut")

let slotPlateWidth = unitPlateWidth + unitSelUnderlineFullHeight
let mapSize = hdpx(650)
let levelHolderSize = evenPx(84)
let rhombusSize = round(levelHolderSize / sqrt(2) / 2) * 2

let needCancel = Computed(@() isRespawnStarted.value && !isRespawnInProgress.value && respawnSlots.value.len() > 1)
let startRespawnTime = mkWatched(persist, "startRespawnTime", -1)
isRespawnStarted.subscribe(function(v) {
  if (v)
    startRespawnTime(::get_mission_time())
})

let topPanel = {
  size = [flex(), SIZE_TO_CONTENT]
  children = [
    { size = [SIZE_TO_CONTENT, flex()], children = logerrHintsBlock }
    scoreBoard
    mkMenuButton({ onClick = @() send("openFlightMenuInRespawn", {}) })
  ]
}

let function onSlotClick(slot) {
  //todo: validate spawn here
  if (slot.canSpawn) {
    playerSelectedSlotIdx(slot.id)
    return
  }
  if ("reqLevel" in slot)
    openMsgBox({ text  = loc("msg/requirePlatoonLevel", { level = slot.reqLevel, name = loc(getUnitLocId(slot.name)) }) })
}

let sparePrice = {
  size = flex()
  children = mkUnitPrice({
    fullPrice = 1,
    price = 1,
    currencyId = "spare"
  })
}

let function mkSlotPlate(slot, baseUnit) {
  let p = getUnitPresentation(slot.name)
  let isSelected = Computed(@() selSlot.value?.id == slot.id)
  let unit = baseUnit.__merge(slot)
  let { canSpawn, isSpawnBySpare } = slot
  let imgOvr = { picSaturate = canSpawn ? 1.0 : 0.0 }
  return {
    size = [slotPlateWidth, unitPlateHeight]
    behavior = Behaviors.Button
    onClick = @() onSlotClick(slot)
    sound = { click  = "choose" }
    flow = FLOW_HORIZONTAL
    children = [
      mkUnitSelectedUnderlineVert(isSelected)
      {
        key = slot
        size = [unitPlateWidth, unitPlateHeight]
        children = [
          mkUnitBg(unit, imgOvr)
          canSpawn ? mkUnitSelectedGlow(unit, isSelected) : null
          mkUnitImage(unit).__update(imgOvr)
          mkUnitTexts(unit, loc(p.locId))
          canSpawn ? null : mkUnitSlotLockedLine(slot)
          canSpawn && isSpawnBySpare ? sparePrice : null
        ]
      }
    ]
  }
}

let levelBg = mkLevelBg({
  ovr = { size = [ rhombusSize, rhombusSize ] }
  childOvr = { borderColor = unitExpColor }
})

let function platoonTitle(unit) {
  let { name, level = 0, isUpgraded = false, isPremium = false } = unit
  let isElite = isUpgraded || isPremium
  let text = "  ".concat(getPlatoonName(name, loc), getUnitClassFontIcon(unit))
  let textLength = calc_str_box(text, fontTinyAccented)[0]
  let textWidth = slotPlateWidth - levelHolderSize
  let textComp = headerText(text)
    .__update(textLength > textWidth ? headerMarquee(textWidth - hdpx(20)) : {}, { margin = [0, hdpx(20), 0, 0] })
  return header({
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(20)
    children = [
      {
        size = [ levelHolderSize, levelHolderSize ]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          levelBg
          {
            rendObj = ROBJ_TEXT
            text = level
            color = 0xFFFFFFFF
          }.__update(fontSmall)
        ]
      }
      !isElite ? textComp : textComp.__update({ color = premiumTextColor })
    ]
  })
}

let slotsBlock = @() {
  watch = [respawnSlots, respawnUnitInfo]
  size = [slotPlateWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap
  children = respawnUnitInfo.value == null ? null
    : [
        platoonTitle(respawnUnitInfo.value)
      ].extend(respawnSlots.value.map(@(slot) mkSlotPlate(slot, respawnUnitInfo.value)))
}

let map = {
  size = [mapSize, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap
  children = [
    header(headerText(loc("respawn/choose_respawn_point")))
    bg.__merge({
      size = [mapSize, mapSize]
      padding = gap
      children = respawnMap
    })
  ]
}

let cancelText = utf8ToUpper(loc("Cancel"))
let function cancelBtn() {
  local btnText = cancelText
  if (timeToRespawn.value > 0)
    btnText = "".concat(btnText,
      loc("ui/parentheses/space", {
        text = $"{timeToRespawn.value}{loc("mainmenu/seconds")}" }))
  return {
    watch = timeToRespawn
    children = textButtonFaded(btnText, cancelRespawn, { hotkeys = [btnBEscUp] })
  }
}

let waitSpinner = mkSpinner()
let buttons = @() {
  watch = [needCancel, isRespawnStarted, selSlot]
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  children = !(selSlot.value?.canSpawn ?? false) ? null
    : !isRespawnStarted.value
      ? textButtonPrimary(utf8ToUpper(loc("mainmenu/toBattle/short")),
          @() respawn(selSlot.value, bulletsToSpawn.value),
          { hotkeys = ["^J:X | Enter"] })
    : needCancel.value ? cancelBtn
    : waitSpinner
}

let rightBlock = {
  size = [SIZE_TO_CONTENT, flex()]
  children = [
    map
    buttons
  ]
}

let updateSlotAABB = @() slotAABB(selSlot.value == null ? null
  : gui_scene.getCompAABBbyKey(selSlot.value))
selSlot.subscribe(@(_) updateSlotAABB())

let function respawnBulletsPlace() {
  let res = { watch = slotAABB, onAttach = @() deferOnce(updateSlotAABB) }
  if (slotAABB.value == null)
    return res
  let contentAABB = gui_scene.getCompAABBbyKey("respawnWndContent")
  if (contentAABB == null)
    return res
  let size = calc_comp_size(respawnBullets)
  let posY = (slotAABB.value.t + slotAABB.value.b - size[1]) / 2  - contentAABB.t
  let maxY = max(0, contentAABB.b - contentAABB.t - size[1])
  return res.__update({
    size = [SIZE_TO_CONTENT, flex()]
    children = {
      key = slotAABB.value
      pos = [0, clamp(posY, 0, maxY)]
      children = respawnBullets
    }
  })
}

let content = @() {
  watch = respawnSlots
  key = "respawnWndContent"
  size = flex()
  flow = FLOW_HORIZONTAL
  children = respawnSlots.value.len() <= 1 ? null
    : [
        slotsBlock
        respawnBulletsPlace
        { size = flex() }
        rightBlock
      ]
}

let animLines = @() {
  watch = selSlotLinesSteps
  size = flex()
  children = selSlotLinesSteps.value == null ? null
    : mkAnimGrowLines(mkAGLinesCfgOrdered(selSlotLinesSteps.value, lineSpeed))
}

return bgShaded.__merge({
  key = {}
  size = flex()
  onAttach = @() isRespawnAttached(true)
  onDetach = @() isRespawnAttached(false)
  children = [
    {
      size = flex()
      padding = saBordersRv
      flow = FLOW_VERTICAL
      gap = hdpx(40)
      children = [
        topPanel
        content
      ]
    }
    animLines
  ]
  animations = wndSwitchAnim
})
