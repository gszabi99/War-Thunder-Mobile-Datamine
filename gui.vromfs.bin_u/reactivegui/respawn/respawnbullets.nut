from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
from "%rGui/bullets/bulletsSlotComps.nut" import mkBulletSliderSlot, mkBulletLockedSlot
from "%rGui/respawn/bulletsChoiceState.nut" import bulletsInfo, chosenBullets, brPickupPrimIdx, bulletStep, bulletTotalSteps,
  bulletLeftSteps, setCurUnitBullets, isFakeSecondary, maxBulletsCountForExtraAmmo, hasExtraBullets, bulletsSecInfo,
  bulletSecStep, bulletSecLeftSteps, isFakeSpecial, chosenBulletsSec, bulletSecTotalSteps, hasExtraBulletsSec,
  maxBulletsSecCountForExtraAmmo, maxBulletsSpecCountForExtraAmmo, bulletsSpecInfo, bulletSpecStep, bulletSpecLeftSteps,
  chosenBulletsSpec, bulletSpecTotalSteps, hasExtraBulletsSpec
from "%rGui/respawn/respawnChooseBulletWnd.nut" import openedSlot
from "%rGui/respawn/respawnComps.nut" import headerMargin, headerText, header, bulletsLegend, mkBulletHeightInfo, gap,
  baseBulletsContentHeight, bulletsBlockWidth, bulletsBottomFade
from "%rGui/respawn/respawnState.nut" import selSlot, hasUnseenShellsBySlot
from "%rGui/respawn/respawnAnimState.nut" import bulletsScrollHandler, bulletsViewportAABB
from "%rGui/components/pannableArea.nut" import verticalPannableAreaCtor
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


const maxSlotsWithoutScroll = 4

let choiceCount = Computed(@() chosenBullets.get().len())
let choiceSecCount = Computed(@() chosenBulletsSec.get().len())
let choiceSpecCount = Computed(@() chosenBulletsSpec.get().len())
let bulletCardStyle = mkBulletHeightInfo(choiceCount, choiceSecCount, choiceSpecCount)
let bulletsPannableArea = verticalPannableAreaCtor(baseBulletsContentHeight, [0, bulletsBottomFade])

const bulletsScrollKey = "respBulletsScroll"
let captureBulletsViewport = @() deferOnce(function() {
  let aabb = gui_scene.getCompAABBbyKey(bulletsScrollKey)
  if (aabb != null)
    bulletsViewportAABB.set(aabb)
})

function respawnBullets() {
  let res = {
    watch = [bulletsInfo, isFakeSecondary, choiceCount, choiceSecCount, bulletCardStyle, isFakeSpecial, choiceSpecCount,
      brPickupPrimIdx]
    animations = wndSwitchAnim
  }
  let bulletSliderSlots = []
  if (bulletsInfo.get() != null)
    bulletSliderSlots.extend(array(choiceCount.get()).map(@(_, idx)
      idx == brPickupPrimIdx.get() 
        ? mkBulletLockedSlot({ idx, bInfo = bulletsInfo, bullets = chosenBullets, iconImage = "icon_air_drop" })
        : mkBulletSliderSlot({
            idx,
            selSlot,
            bInfo = bulletsInfo,
            bullets = chosenBullets,
            bTotalSteps = bulletTotalSteps,
            bStep = bulletStep,
            maxBullets = maxBulletsCountForExtraAmmo,
            withExtraBullets = hasExtraBullets,
            bLeftSteps = bulletLeftSteps,
            hasUnseenShells = hasUnseenShellsBySlot,
            openedSlot,
            cardStyle = bulletCardStyle,
            onChangeSlider = setCurUnitBullets
          })))

  let buildSecSlots = @() array(choiceSecCount.get())
    .map(@(_, idx) mkBulletSliderSlot({
      idx,
      selSlot,
      bInfo = bulletsSecInfo,
      bullets = chosenBulletsSec,
      bTotalSteps = bulletSecTotalSteps,
      bStep = bulletSecStep,
      maxBullets = maxBulletsSecCountForExtraAmmo,
      withExtraBullets = hasExtraBulletsSec,
      bLeftSteps = bulletSecLeftSteps,
      hasUnseenShells = hasUnseenShellsBySlot,
      openedSlot,
      cardStyle = bulletCardStyle,
      onChangeSlider = setCurUnitBullets
    }))

  let buildSpecSlots = @() array(choiceSpecCount.get())
    .map(@(_, idx) mkBulletSliderSlot({
      idx,
      selSlot,
      bInfo = bulletsSpecInfo,
      bullets = chosenBulletsSpec,
      bTotalSteps = bulletSpecTotalSteps,
      bStep = bulletSpecStep,
      maxBullets = maxBulletsSpecCountForExtraAmmo,
      withExtraBullets = hasExtraBulletsSpec,
      bLeftSteps = bulletSpecLeftSteps,
      hasUnseenShells = hasUnseenShellsBySlot,
      openedSlot,
      cardStyle = bulletCardStyle,
      onChangeSlider = setCurUnitBullets
    }))

  
  if (!isFakeSecondary.get())
    bulletSliderSlots.extend(buildSecSlots())
  if (!isFakeSpecial.get())
    bulletSliderSlots.extend(buildSpecSlots())
  if (isFakeSecondary.get())
    bulletSliderSlots.extend(buildSecSlots())
  if (isFakeSpecial.get())
    bulletSliderSlots.extend(buildSpecSlots())
  if (bulletSliderSlots.len() == 0)
    return res

  let needScroll = bulletSliderSlots.len() > maxSlotsWithoutScroll

  let bulletsContent = {
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = bulletCardStyle.get().gapHeight
    children = bulletSliderSlots
  }

  return res.__update({
    flow = FLOW_HORIZONTAL
    children = [
      {
        margin = headerMargin
        flow = FLOW_VERTICAL
        gap
        children = [
          header(headerText(loc("respawn/chooseBullets")))
          {
            key = bulletsScrollKey
            size = [bulletsBlockWidth, baseBulletsContentHeight]
            onAttach = captureBulletsViewport
            children = needScroll
              ? bulletsPannableArea(bulletsContent, {},
                  { behavior = [Behaviors.Pannable, Behaviors.WheelScroll, Behaviors.ScrollEvent], scrollHandler = bulletsScrollHandler })
              : bulletsContent
          }
        ]
      }
      bulletsLegend
    ]
  })
}

return respawnBullets
