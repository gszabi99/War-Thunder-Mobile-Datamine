from "%globalsDarg/darg_library.nut" import *
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bulletsInfo, chosenBullets, bulletStep, bulletTotalSteps, bulletLeftSteps, setCurUnitBullets,
  maxBulletsCountForExtraAmmo, hasExtraBullets, bulletsSecInfo, bulletSecStep, bulletSecLeftSteps
  chosenBulletsSec, bulletSecTotalSteps, hasExtraBulletsSec, maxBulletsSecCountForExtraAmmo
} = require("%rGui/respawn/bulletsChoiceState.nut")
let { headerMargin, headerText, header, bulletsLegend, mkBulletHeightInfo } = require("%rGui/respawn/respawnComps.nut")
let { openedSlot } = require("%rGui/respawn/respawnChooseBulletWnd.nut")
let { selSlot, hasUnseenShellsBySlot } = require("%rGui/respawn/respawnState.nut")
let { unitPlatesGap } = require("%rGui/unit/components/unitPlateComp.nut")
let { mkBulletSliderSlot } = require("%rGui/bullets/bulletsSlotComps.nut")


let choiceCount = Computed(@() chosenBullets.get().len())
let choiceSecCount = Computed(@() chosenBulletsSec.get().len())
let bulletCardStyle = mkBulletHeightInfo(choiceCount, choiceSecCount)

function respawnBullets() {
  let res = {
    watch = [bulletsInfo, bulletsSecInfo, choiceCount, choiceSecCount, bulletCardStyle]
    animations = wndSwitchAnim
  }
  let bulletSliderSlots = []
  if (bulletsInfo.get() != null)
    bulletSliderSlots.extend(array(choiceCount.get()).map(@(_, idx)
      mkBulletSliderSlot({
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
  if (bulletsSecInfo.get() != null)
    bulletSliderSlots.extend(array(choiceSecCount.get()).map(@(_, idx)
      mkBulletSliderSlot({
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
      })))
  return bulletSliderSlots.len() == 0 ? res : res.__update({
    flow = FLOW_HORIZONTAL
    children = [
      {
        margin = headerMargin
        flow = FLOW_VERTICAL
        gap = unitPlatesGap
        children = [
          header(headerText(loc("respawn/chooseBullets")))
          {
            flow = FLOW_VERTICAL
            gap = bulletCardStyle.get().gapHeight
            children = bulletSliderSlots
          }
        ]
      }
      bulletsLegend
    ]
  })
}

return respawnBullets
