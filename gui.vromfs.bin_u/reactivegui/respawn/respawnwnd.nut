from "%globalsDarg/darg_library.nut" import *
let { get_mission_time } = require("mission")
let { eventbus_send } = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { AIR } = require("%appGlobals/unitConst.nut")
let { hudCustomRules } = require("%appGlobals/clientState/missionState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { isRespawnAttached, respawnSlots, respawn, cancelRespawn, selSlotContentGenId,
  selSlot, selSlotUnitType, playerSelectedSlotIdx, sparesNum, unitListScrollHandler, hasSkins,
  needRespawnSlotsAndWeaponry, spawnScoreCosts, isUseSpawnScore
} = require("%rGui/respawn/respawnState.nut")
let { mkSpawnScore, spawnScoreBalance } = require("%rGui/respawn/spawnScore.nut")
let { bulletsToSpawn, hasLowBullets, hasZeroBullets, chosenBullets, hasChangedCurSlotBullets, hasZeroMainBullets
} = require("%rGui/respawn/bulletsChoiceState.nut")
let { slotAABB, selSlotLinesSteps, lineSpeed } = require("%rGui/respawn/respawnAnimState.nut")
let { isRespawnInProgress, isRespawnStarted, respawnUnitInfo, timeToRespawn, respawnUnitItems,
  hasPredefinedReward, dailyBonus, respawnsLeft, respawnsTotalInitial
} = require("%appGlobals/clientState/respawnStateBase.nut")
let { getUnitPresentation, getUnitName } = require("%appGlobals/unitPresentation.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { markTextColor, badTextColor2, textColor, commonTextColor } = require("%rGui/style/stdColors.nut")
let { mkMenuButton } = require("%rGui/hud/menuButton.nut")
let { infoTooltipButton } = require("%rGui/components/infoButton.nut")
let { textButtonCommon, mkCustomButton, iconButtonPrimary, mkButtonTextMultiline } = require("%rGui/components/textButton.nut")
let { defButtonHeight, BATTLE, INACTIVE } = require("%rGui/components/buttonStyles.nut")
let { scoreBoardType, scoreBoardCfgByType, scoreBoardHeight } = require("%rGui/hud/scoreBoard.nut")
let { unitPlateSmall, mkUnitBg, mkUnitSelectedGlow, mkPlateText, mkUnitLevel,
  mkUnitImage, mkUnitTexts, mkUnitSlotLockedLine, unitSlotLockedByQuests,
  mkUnitSelectedUnderline, mkUnitInfo, plateTextsSmallPad, mkUnitDailyBonus
} = require("%rGui/unit/components/unitPlateComp.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { logerrHintsBlock } = require("%rGui/hudHints/hintBlocks.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { respawnMap, visibleRespawnBases } = require("%rGui/respawn/respawnMap.ui.nut")
let respawnBullets = require("%rGui/respawn/respawnBullets.nut")
let respawnAirWeaponry = require("%rGui/respawn/respawnAirWeaponry.nut")
let { bg, headerText, headerHeight, header, gap, contentOffset, unitListHeight, skinPadding
} = require("%rGui/respawn/respawnComps.nut")
let { mkAnimGrowLines, mkAGLinesCfgOrdered } = require("%rGui/components/animGrowLines.nut")
let { SPARE } = require("%appGlobals/itemsState.nut")
let { mkCurrencyComp, mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { mkConsumableSpend } = require("%rGui/hud/weaponsButtonsAnimations.nut")
let { mySpawnScore } = require("%rGui/hud/localMPlayer.nut")
let { respawnSkins, skinSize, skinGap } = require("%rGui/respawn/respawnSkins.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")
let { openUnitWeaponPresetWnd } = require("%rGui/unit/unitWeaponPresetsWnd.nut")
let { sendPlayerActivityToServer } = require("%rGui/respawn/playerActivity.nut")
let { selLineSize } = require("%rGui/components/selectedLineUnits.nut")
let { CS_RESPAWN, CS_GAMERCARD } = require("%rGui/components/currencyStyles.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { getEquippedWeapon } = require("%rGui/unitMods/equippedSecondaryWeapons.nut")
let { mkWeaponPreset } = require("%rGui/unit/unitSettings.nut")
let { loadUnitWeaponSlots } = require("%rGui/weaponry/loadUnitBullets.nut")
let { mkTooltipText } = require("%rGui/tooltip.nut")


let MAX_DEF_SLOTS = 4

let mapMaxSize = hdpx(610)
let unitListGradientSize = [gap, saBorders[1]]
let scoreIconSize = hdpxi(30)
let tooltipIconSize = hdpxi(32)

let lockColor = 0xFF9C9EA0
let destroyedColor = 0xFFEE5353

let needCancel = Computed(@() isRespawnStarted.get() && !isRespawnInProgress.get() && respawnSlots.get().len() > 1)
let showLowBulletsWarning = Watched(true)
let startRespawnTime = mkWatched(persist, "startRespawnTime", -1)
isRespawnStarted.subscribe(function(v) {
  if (v)
    startRespawnTime.set(get_mission_time())
})
let needSpareBalance = Computed(@() !!hudCustomRules.get()?.allowSpare && !!respawnUnitItems.get()?.spare)

let spareBalance = @() {
  watch = sparesNum
  children = [
    mkCurrencyComp(sparesNum.get(), SPARE)
    mkConsumableSpend(SPARE, hdpx(20), hdpx(80), @(count) sparesNum.set(sparesNum.get() - count))
  ]
}



let balanceBlock = @() {
  watch = needSpareBalance
  size = FLEX_V
  hplace = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  gap = hdpx(10)
  children = [
    spawnScoreBalance
    needSpareBalance.get() ? spareBalance : null
  ]
}

let topPanel = {
  size = [FLEX, scoreBoardHeight]
  children = [
    { size = FLEX_V, children = logerrHintsBlock }
    @() {
      watch = scoreBoardType
      size = FLEX
      children = scoreBoardCfgByType?[scoreBoardType.get()].comp
    }
    mkMenuButton(1.0, { onClick = @() eventbus_send("openFlightMenuInRespawn", {}) })
    balanceBlock
  ]
}

function onSlotClick(slot) {
  
  sendPlayerActivityToServer()
  if (slot.canSpawn) {
    playerSelectedSlotIdx.set(slot.id)
    return
  }
  let name = colorize(markTextColor, getUnitName(slot.name))
  openMsgBox((slot?.reqLevel ?? 0) > 0 ? { text  = loc("msg/requirePlatoonLevel", { level = slot.reqLevel, name }) }
    : slot?.isLocked ? { text  = loc("msg/requireUnlockByQuests", { name }) }
    : { text  = loc("msg/unitAlreadyUsedInBattle", { name }) })
}

let sparePrice = {
  hplace = ALIGN_RIGHT
  vplace = ALIGN_CENTER
  padding = const [hdpx(10), hdpx(20), 0, 0]
  children = mkCurrencyImage(SPARE, CS_RESPAWN.iconSize)
}

let notEnoughScoreStyle = { color = badTextColor2 }
function mkSlotScorePrice(slot) {
  let { name, canSpawn } = slot
  if (!canSpawn)
    return null

  let score = Computed(@() spawnScoreCosts.get()?[name] ?? 0)
  let isEnough = Computed(@() score.get() <= mySpawnScore.get())
  return @() {
    watch = [score, isEnough]
    vplace = ALIGN_BOTTOM
    margin = [ 0, 0, plateTextsSmallPad, plateTextsSmallPad ]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = hdpx(5)
    children = score.get() <= 0 ? null
      : [
          {
            size = scoreIconSize
            rendObj = ROBJ_IMAGE
            image = Picture($"ui/gameuiskin#icon_spawn_points.svg:{scoreIconSize}:P")
            keepAspect = true
          }
          mkPlateText(score.get(), isEnough.get() ? {} : notEnoughScoreStyle)
        ]
  }
}

function mkSlotPlate(slot, baseUnit) {
  let p = getUnitPresentation(slot.name)
  let isSelected = Computed(@() selSlot.get()?.id == slot.id)
  let unit = baseUnit.__merge(slot)
  let { canSpawn, isSpawnBySpare, mRank } = slot
  return {
    key = slot
    behavior = Behaviors.Button
    onClick = @() onSlotClick(slot)
    sound = { click = "choose" }
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      mkUnitSelectedUnderline(unit, isSelected, { margin = 0, size = [FLEX, selLineSize] })
      {
        size = unitPlateSmall
        children = [
          mkUnitBg(unit, !canSpawn)
          canSpawn ? mkUnitSelectedGlow(unit, isSelected) : null
          mkUnitImage(unit, !canSpawn)
          mkUnitTexts(unit, loc(p.locId), !canSpawn)
          mkSlotScorePrice(slot)
          unit.rewardedMasteryTier > 0 ? mkUnitLevel(unit.level, unit.rewardedMasteryTier) : null
          canSpawn
              ? mkUnitInfo(mRank == 0 ? baseUnit : unit, { padding = [0, plateTextsSmallPad * 2, 0, 0] })
            : slot?.isLocked && (slot?.reqLevel ?? 0) <= 0
              ? unitSlotLockedByQuests
            : mkUnitSlotLockedLine(slot)
          canSpawn && isSpawnBySpare ? sparePrice : null
          unit?.hasDailyBonus
            ? mkUnitDailyBonus(Computed(@() !hasPredefinedReward.get()),
              Computed(@() dailyBonus.get()?.wpMul ?? 1),
              Computed(@() dailyBonus.get()?.expMul ?? 1),
              Computed(@() (serverConfigs.get()?.campaignCfg[unit?.campaign].totalSlots ?? 0) > 0))
            : null
        ]
      }
    ]
  }
}

let mkRespToolipText = @(text) mkTooltipText(text).__update(fontTinyAccented, { color = commonTextColor })

let mkIcon = @(image) {
  size = tooltipIconSize
  rendObj = ROBJ_IMAGE
  image = Picture($"{image}:{tooltipIconSize}:p")
  keepAspect = KEEP_ASPECT_FIT
}
let tankIcon = mkIcon("ui/gameuiskin#unit_tank.svg")
let spareIcon = mkIcon("ui/gameuiskin#shop_consumables_spare.svg")
let destroyedIcon = mkIcon("ui/gameuiskin#unit_tank.svg").__update({ color = destroyedColor })
let lockIcon = mkIcon("ui/gameuiskin#lock_icon.svg").__update({ size = hdpxi(30), color = lockColor })

let tankStackIcon = mkIcon("ui/gameuiskin#unit_tank_stack.svg").__update({ size = hdpxi(26) })
let spareStackIcon = mkIcon("ui/gameuiskin#shop_consumables_spare_stack.svg")
let destroyedStackIcon = mkIcon("ui/gameuiskin#unit_tank_stack.svg").__update({ size = hdpxi(26), color = destroyedColor })
let lockStackIcon = mkIcon("ui/gameuiskin#lock_icon_stack.svg").__update({ size = hdpxi(30), color = lockColor })

let mkTooltipRow = @(iconComp, text) {
  flow = FLOW_HORIZONTAL
  gap = hdpx(5)
  children = [
    iconComp
    mkRespToolipText(text)
  ]
}

function tooltipContentCtor() {
  sendPlayerActivityToServer()
  let res = {
    flow = FLOW_VERTICAL
    children = [
      mkTooltipRow(tankIcon, loc("respawn/spawnsCounter/type/available"))
      mkTooltipRow(spareIcon, loc("respawn/spawnsCounter/type/spare"))
      mkTooltipRow(destroyedIcon, loc("respawn/spawnsCounter/type/destroyed"))
      mkTooltipRow(lockIcon, loc("respawn/spawnsCounter/type/notAvailable"))
    ]
  }

  let unitsLeft = min(respawnsLeft.get(), respawnSlots.get().filter(@(slot) slot.canSpawn && !slot.isSpawnBySpare).len())
  let hasMaxSlots = respawnSlots.get().len() >= min(respawnsTotalInitial.get(), MAX_DEF_SLOTS)
  let hasEnoughSpares = sparesNum.get() >= (respawnsLeft.get() - unitsLeft)
  if (hasMaxSlots && hasEnoughSpares)
    return res

  let hint = !hasMaxSlots && !hasEnoughSpares ? loc("respawn/spawnsCounter/tooltip/all")
    : !hasMaxSlots ? loc("respawn/spawnsCounter/tooltip/unitNoSpare")
    : hasEnoughSpares ? loc("respawn/spawnsCounter/tooltip/unit")
    : loc("respawn/spawnsCounter/tooltip/spare")
  res.children.append(mkRespToolipText("".concat("\n\n", colorize(textColor, hint))))
  return res
}

let mkStack = @(amount, baseIconComp, stackIconComp, contentGap) {
  flow = FLOW_HORIZONTAL
  gap = contentGap
  valign = ALIGN_CENTER
  children = amount == 1 ? baseIconComp
    : [
        baseIconComp
        {
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          gap = contentGap - hdpx(4)
          children = array(amount - 1).map(@(_) stackIconComp)
        }
      ]
}

function mkDoubleStack(amount, baseIconComp, stackIconComp, secAmount, secBaseIconComp, secStackIconComp, contentGap) {
  let iconComp = amount == 0 ? secBaseIconComp : baseIconComp
  return {
    flow = FLOW_HORIZONTAL
    gap = contentGap
    valign = ALIGN_CENTER
    children = amount + secAmount <= 1 ? iconComp
      : [
          iconComp
          {
            valign = ALIGN_CENTER
            halign = ALIGN_CENTER
            flow = FLOW_HORIZONTAL
            gap = contentGap - hdpx(4)
            children = [].extend(
              amount > 1 ? array(amount - 1).map(@(_) stackIconComp) : [],
              secAmount > 1 && amount == 0 ? array(secAmount - 1).map(@(_) secStackIconComp)
                : secAmount > 0 ? array(secAmount).map(@(_) secStackIconComp)
                : []
            )
          }
        ]
  }
}

let slotsBlockTitle = @(unit, respSlots) function() {
  let { unitType = "" } = unit
  let hasSpawnCounter = !isUseSpawnScore.get() && respawnsTotalInitial.get() > 0
  let text = hasSpawnCounter ? loc("respawn/spawnsCounter")
    : unitType == "" ? ""
    : loc($"respawn/squad/{unitType}")
  if (!hasSpawnCounter)
    return header(headerText(text), { watch = [respawnsTotalInitial, isUseSpawnScore] })

  let unitsLeft = min(respawnsLeft.get(),
    respSlots.filter(@(slot) slot.canSpawn && !slot.isSpawnBySpare).len())
  let sparesLeft = min(respawnsLeft.get() - unitsLeft,
    sparesNum.get(),
    unitsLeft + respSlots.filter(@(slot) slot.canSpawn && slot.isSpawnBySpare).len())
  let unitsDestroyed = respawnsTotalInitial.get() - respawnsLeft.get()
  let unitsNotAvailable = respawnsLeft.get() - unitsLeft - sparesLeft

  return header(
    {
      size = FLEX
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      padding = hdpx(10)
      gap
      children = [
        {
          size = FLEX_H
          valign = ALIGN_CENTER
          halign = ALIGN_RIGHT
          flow = FLOW_HORIZONTAL
          children = [
            headerText(text).__update({ size = FLEX_H, hplace = ALIGN_LEFT, halign = ALIGN_LEFT })
            infoTooltipButton(tooltipContentCtor, {}, { onClick = @() sendPlayerActivityToServer() })
          ]
        }
        {
          size = FLEX
          valign = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          gap = { size = FLEX }
          children = [
            {
              flow = FLOW_HORIZONTAL
              children = [
                unitsLeft <= 0 && unitsDestroyed <= 0 ? null
                  : mkDoubleStack(unitsLeft, tankIcon, tankStackIcon,
                      unitsDestroyed, destroyedIcon, destroyedStackIcon, -hdpx(5))
                sparesLeft <= 0 ? null
                  : mkStack(sparesLeft, spareIcon, spareStackIcon, -hdpx(13))
              ].filter(@(v) v != null)
            }
            {
              flow = FLOW_HORIZONTAL
              children = unitsNotAvailable <= 0 ? null
                : mkStack(unitsNotAvailable, lockIcon, lockStackIcon, -hdpx(15))
            }
          ]
        }
      ]
    }
    { watch = [respawnsTotalInitial, sparesNum, isUseSpawnScore, respawnsLeft], size = [FLEX, hdpx(100)] })
}

let pannableArea = verticalPannableAreaCtor(unitListHeight + unitListGradientSize[0] + unitListGradientSize[1],
  unitListGradientSize)

function slotsBlock() {
  let title = slotsBlockTitle(respawnUnitInfo.get(), respawnSlots.get())
  let list = respawnSlots.get().map(@(slot) mkSlotPlate(slot, respawnUnitInfo.get()))
  return {
    watch = [respawnSlots, respawnUnitInfo]
    size = [unitPlateSmall[0], SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap
    children = respawnUnitInfo.get() == null ? null
      : list.len() <= MAX_DEF_SLOTS ? [ title ].extend(list)
      : [
          title
          {
            size = [FLEX, unitListHeight]
            children = [
              pannableArea(
                {
                  size = FLEX_H
                  flow = FLOW_VERTICAL
                  gap
                  children = list
                },
                {},
                { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler = unitListScrollHandler })
              mkScrollArrow(unitListScrollHandler, MR_B, scrollArrowImageSmall,
                { vplace = ALIGN_TOP, pos = [0, unitListHeight] })
            ]
          }
        ]
  }
}

let map = @() {
  watch = visibleRespawnBases
  size = FLEX_H
  maxHeight = mapMaxSize + headerHeight + gap
  maxWidth = mapMaxSize
  flow = FLOW_VERTICAL
  gap
  children = [
    visibleRespawnBases.get().len() > 0 ? header(headerText(loc("respawn/choose_respawn_point"))) : null
    bg.__merge({
      size = const [FLEX, pw(100)]
      padding = gap
      children = respawnMap
    })
  ]
}

function cancelBtn() {
  local btnText = loc("Cancel")
  if (timeToRespawn.get() > 0)
    btnText = "".concat(btnText,
      loc("ui/parentheses/space", {
        text = $"{timeToRespawn.get()}{loc("mainmenu/seconds")}" }))
  return {
    watch = timeToRespawn
    children = textButtonCommon(utf8ToUpper(btnText), cancelRespawn, { hotkeys = [btnBEscUp] })
  }
}

let mkText = @(text, override = {}) {
  rendObj = ROBJ_TEXT
  text
}.__update(fontTiny, override)

let skinsList = @() {
  watch = hasSkins
  children = !hasSkins.get() ? null : {
    flow = FLOW_VERTICAL
    gap
    children = [
      header(headerText(loc("skins/select")))
      {
        size = [((skinSize + skinGap) * 4 - skinGap) + skinPadding * 2, skinSize + skinPadding * 2]
        padding = skinPadding
        rendObj = ROBJ_SOLID
        color = 0x99000000
        clipChildren = true
        children = {
          size = FLEX
          behavior = Behaviors.Pannable
          touchMarginPriority = TOUCH_BACKGROUND
          skipDirPadNav = true
          xmbNode = XmbContainer()
          children = respawnSkins
        }
      }
    ]
  }
}

let vehicleActionLangKeys = {
  [AIR] = "mainmenu/flightAgain"
}

function toBattleButton(onClick, styleOvr) {
  let needShowSpareDesc = Computed(@() selSlot.get()?.isSpawnBySpare ?? false)
  let spawnCost = Computed(@() spawnScoreCosts.get()?[selSlot.get()?.name] ?? 0)
  let btnStyle = Computed(@() isUseSpawnScore.get() && spawnCost.get() > mySpawnScore.get() ? INACTIVE : BATTLE)
  return @() {
    watch = [selSlotUnitType, needShowSpareDesc, spawnCost, btnStyle]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_BOTTOM
    gap
    children = [
      skinsList
      {
        flow = FLOW_VERTICAL
        gap
        halign = ALIGN_CENTER
        children = [
          needShowSpareDesc.get()
            ? mkText(utf8ToUpper(loc(vehicleActionLangKeys?[selSlotUnitType.get()] ?? "mainmenu/driveAgain")))
            : null
          mkCustomButton({
              flow = FLOW_VERTICAL
              halign = ALIGN_CENTER
              gap = hdpx(5)
              children = [
                mkButtonTextMultiline(utf8ToUpper(loc("mainmenu/toBattle/short")), fontTinyAccentedShadedBold)
                needShowSpareDesc.get() ? mkCurrencyComp(1, SPARE, CS_GAMERCARD) : null
                spawnCost.get() <= 0 ? null : mkSpawnScore(spawnCost.get(), CS_GAMERCARD)
              ]
            },
            onClick,
            btnStyle.get().__merge(styleOvr))
        ]
      }
    ]
  }
}

function toBattle() {
  if (chosenBullets.get().len() == 0) 
    respawn(selSlot.get(), bulletsToSpawn.get())
  else if (hasZeroBullets.get())
    openMsgBox({ text = loc("respawn/zero_ammo") })
  else if (hasZeroMainBullets.get())
    openMsgBox({ text = loc("respawn/zero_main_ammo") })
  else if (hasLowBullets.get() && hasChangedCurSlotBullets.get() && showLowBulletsWarning.get()) {
    openMsgBox({
      text = loc("respawn/low_ammo")
      buttons = [
        { id = "cancel", isCancel = true }
        { text = utf8ToUpper(loc("mainmenu/toBattle/short")), styleId = "BATTLE",
          cb = @() respawn(selSlot.get(), bulletsToSpawn.get()) }
      ]
    })
    showLowBulletsWarning.set(false)
  }
  else
    respawn(selSlot.get(), bulletsToSpawn.get())
}

function showSpawnScoreMsgIfNeed() {
  if (!isUseSpawnScore.get())
    return false
  let cost = spawnScoreCosts.get()?[selSlot.get()?.name] ?? 0
  if (cost <= mySpawnScore.get())
    return false
  openMsgBox({ text = loc("multiplayer/noSpawnScore", { cost = colorize(markTextColor, cost) }) })
  return true
}

function checkAndBattle() {
  if (showSpawnScoreMsgIfNeed())
    return

  if (selSlot.get()?.unitClass != "bomber")
    return toBattle()

  let allWSlots = loadUnitWeaponSlots(selSlot.get()?.name)
  let { weaponPreset, setWeaponPreset } = mkWeaponPreset(Watched(selSlot.get().name))
  let equippedWeaponsBySlots = allWSlots.map(@(wSlot, idx) getEquippedWeapon(
      weaponPreset.get(),
      idx,
      wSlot?.wPresets ?? {},
      selSlot.get()?.mods))
  let isEmpty = equippedWeaponsBySlots.filter(@(s, idx) s != null && idx != 0).len() == 0

  if (!isEmpty)
    return toBattle()

  openMsgBox({
    text = loc("weapons/secondaryWeaponNotSet")
    buttons = [
      { text = loc("btn/doNotSet"),
        isCancel = true
        cb = toBattle
      }
      {
        text = loc("btn/setDefault"),
        function cb() {
          let preset = equippedWeaponsBySlots.map(
            @(equippedWeapon, idx) equippedWeapon != null ? equippedWeapon.name
              : (allWSlots[idx].wPresets.findvalue(@(w) w.isDefault)?.name ?? ""))
          setWeaponPreset(preset)
          toBattle()
        }
        styleId = "PRIMARY",
        multiLine = true
      }
    ]
  })
}

let buttons = @() {
  watch = [needCancel, isRespawnStarted, selSlot, selSlotUnitType, isGamepad]
  vplace = ALIGN_BOTTOM
  valign = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  gap
  children = [
    selSlotUnitType.get() != AIR ? null
      : iconButtonPrimary("ui/gameuiskin#icon_weapon_preset.svg", @() openUnitWeaponPresetWnd(selSlot.get()), {
        ovr = {
          size = isGamepad.get()
            ? [defButtonHeight * 2, defButtonHeight]
            : [defButtonHeight, defButtonHeight]
          minWidth = defButtonHeight
        }
        hotkeys = ["^J:Y | Enter"]
      }),
    !(selSlot.get()?.canSpawn ?? false) ? null
      : !isRespawnStarted.get() ? toBattleButton(checkAndBattle, { hotkeys = ["^J:X | Enter"] })
      : needCancel.get() ? cancelBtn
      : spinner
  ]
}

let rightBlock = {
  size = FLEX
  halign = ALIGN_RIGHT
  margin = const [0, 0, 0, hdpx(20)]
  children = [
    map
    buttons
  ]
}

let updateSlotAABB = @() slotAABB.set(selSlot.get() == null ? null
  : gui_scene.getCompAABBbyKey(selSlot.get()))
selSlot.subscribe(@(_) deferOnce(updateSlotAABB))

let weaponryBlockByUnitType = {
  [AIR] = respawnAirWeaponry,
}

let respawnBulletsPlace = @() {
  watch = [slotAABB, selSlotUnitType, selSlot]
  size = FLEX_V
  onAttach = @() deferOnce(updateSlotAABB)
  children = {
    key = slotAABB.get()
    onAttach = @() selSlotContentGenId.set(selSlotContentGenId.get() + 1)
    children = selSlotUnitType.get() == null ? null
      : (weaponryBlockByUnitType?[selSlotUnitType.get()](selSlot.get()) ?? respawnBullets)
  }
}

let content = @() {
  watch = needRespawnSlotsAndWeaponry
  key = "respawnWndContent"
  size = FLEX
  flow = FLOW_HORIZONTAL
  children = !needRespawnSlotsAndWeaponry.get() ? null
    : [
        slotsBlock
        respawnBulletsPlace
        rightBlock
      ]
}

let animLines = @() {
  watch = selSlotLinesSteps
  size = FLEX
  children = selSlotLinesSteps.get() == null ? null
    : mkAnimGrowLines(mkAGLinesCfgOrdered(selSlotLinesSteps.get(), lineSpeed))
}

return bgShaded.__merge({
  key = {}
  size = FLEX
  onAttach = @() isRespawnAttached.set(true)
  onDetach = @() isRespawnAttached.set(false)
  children = [
    {
      size = FLEX
      padding = saBordersRv
      flow = FLOW_VERTICAL
      gap = contentOffset
      children = [
        topPanel
        content
      ]
    }
    animLines
  ]
  animations = wndSwitchAnim
})
