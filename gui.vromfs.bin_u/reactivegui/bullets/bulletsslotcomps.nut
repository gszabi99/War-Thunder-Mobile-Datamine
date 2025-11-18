from "%globalsDarg/darg_library.nut" import *
let { deferOnce } = require("dagor.workcycle")
let { mkCustomButton } = require("%rGui/components/textButton.nut")
let { mkPriorityUnseenMarkWatch } = require("%rGui/components/unseenMark.nut")
let { slider, sliderValueSound, sliderBtn, mkSliderKnob } = require("%rGui/components/slider.nut")
let { bg, bulletsBlockWidth, headerSlotHeight } = require("%rGui/respawn/respawnComps.nut")
let { bulletsAABB } = require("%rGui/respawn/respawnAnimState.nut")
let { showRespChooseWnd } = require("%rGui/respawn/respawnChooseBulletWnd.nut")
let mkBulletSlot = require("%rGui/bullets/mkBulletSlot.nut")
let { hoverColor, selectColor } = require("%rGui/style/stdColors.nut")

let padding = hdpx(8)
let btnSize = evenPx(80)
let knobSize = evenPx(50)
let sliderGap = knobSize / 2 + (0.1 * btnSize).tointeger()
let sliderWidth = bulletsBlockWidth - 2 * (btnSize + sliderGap + padding)
let arrowSize = [hdpxi(50), hdpxi(50)]

let arrowBtnImage = @(isOpened) {
  rendObj = ROBJ_IMAGE
  size = arrowSize
  flipX = !isOpened
  image = Picture($"ui/gameuiskin#arrow_icon.svg:{arrowSize[0]}:{arrowSize[1]}:P")
}

function onHeaderClick(key, slotIdx) {
  if (slotIdx != null)
    showRespChooseWnd(slotIdx, gui_scene.getCompAABBbyKey(key), gui_scene.getCompAABBbyKey("respawnWndContent"))
}

function bulletHeader(selSlot, bSlot, bSet, bInfo, chosenBullets, hasUnseenShells, openedSlot) {
  let fromUnitTags = Computed(@() bInfo.get()?.fromUnitTags[bSlot.get()?.name])
  let { idx = -1 } = bSlot.get()
  let key = $"respBulletsHeader{idx}"
  let hasUnseenBullets = Computed(@() (bSlot.get()?.idx ?? 0) > 0
    && hasUnseenShells.get()?[selSlot.get()?.id ?? 0].findvalue(@(v) v) != null)
  return @() {
    watch = [bSet, fromUnitTags]
    onAttach = @() deferOnce(function() {
      let aabb = gui_scene.getCompAABBbyKey(key)
      if (aabb != null)
        bulletsAABB.mutate(@(v) v.__update({ [idx] = aabb }))
    })
    size = [bulletsBlockWidth, headerSlotHeight]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    children = [
      {
        key
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          @() mkBulletSlot(chosenBullets, bSet.get(), fromUnitTags.get(), {}, {}, { watch = [fromUnitTags, bSet] })
          @() {
            watch = openedSlot
            size = [flex(), headerSlotHeight]
            rendObj = ROBJ_BOX
            borderWidth = openedSlot.get() < 0 || idx != openedSlot.get() ? 0 : hdpxi(4)
          }
        ]
      }
      @() {
        key = $"respBulletsBtn{idx}" 
        size = flex()
        watch = openedSlot
        rendObj = ROBJ_SOLID
        color = 0x99000000
        children = [
          mkCustomButton(arrowBtnImage(
            openedSlot.get() < 0 || idx != openedSlot.get()), @() onHeaderClick(key, idx),
            {
              ovr = {
                size = [flex(), headerSlotHeight]
                fillColor = selectColor
              }
            })
          mkPriorityUnseenMarkWatch(hasUnseenBullets, { margin = hdpx(7) })
        ]
      }
    ]
  }
}

let btnBgOvr = { size = [btnSize, btnSize] }
let inactiveBtnOvr = { color = 0x30303030 }

let mkBtnTextCtor = @(override) @(ovrW) @(sf) @() {
  watch = ovrW
  rendObj = ROBJ_TEXT
  color = sf & S_HOVER ? hoverColor : 0xFFFFFFFF
}.__update(fontMedium, override, ovrW.get())
let btnTextDec = mkBtnTextCtor({ text = "-", pos = [0, -hdpx(4)] })
let btnTextInc = mkBtnTextCtor({ text = "+" })

let mkKnobCtor = @(sliderKnobSize) @(relValue, stateFlags, fullW)
  mkSliderKnob(relValue, stateFlags, fullW, { size = [sliderKnobSize, sliderKnobSize] })

let mkBulletSlider = @(size, count, unitValue, maxValue, onChange) @() {
  watch = [unitValue, maxValue]
  children = slider(count,
    {
      size
      unit = unitValue.get()
      min = 0
      max = maxValue.get()
      onChange
    },
    mkKnobCtor(size[1])
  ).__update({ vplace = ALIGN_TOP })
}

function mkBulletSliderWithBtns(bSlot, maxCount, maxBullets, withExtraBullets, bStep, bLeftSteps, cardStyle, onChangeSlider) {
  let count = Computed(@() bSlot.get()?.count ?? 0)
  let unitValue = Computed(@() withExtraBullets.get() ? maxBullets.get() : bStep.get())
  let maxValue = Computed(@() withExtraBullets.get() ? maxBullets.get() : maxCount.get() * bStep.get())
  let minOvr = Computed(@() count.get() == 0 ? inactiveBtnOvr : {})
  let maxOvr = Computed(@() (bLeftSteps.get() == 0 || count.get() >= maxValue.get()) ? inactiveBtnOvr : {})
  function onChange(value) {
    if (bSlot.get() == null)
      return
    let newVal = clamp(value, 0, !withExtraBullets.get()
      ? (count.get() + bLeftSteps.get() * bStep.get())
      : maxBullets.get())
    if (newVal == count.get())
      return
    sliderValueSound()
    let { name, idx } = bSlot.get()
    onChangeSlider(idx, name, newVal)
  }
  return @() bg.__merge({
    watch = cardStyle
    size = [ flex(), cardStyle.get().slotSliderHeight ]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = sliderGap
    padding = [padding, 0]
    children = [
      sliderBtn(btnTextDec(minOvr),
        @() onChange(count.get() - bStep.get()),
        Computed(@() btnBgOvr.__merge(minOvr.get())))
      mkBulletSlider([sliderWidth, knobSize], count, unitValue, maxValue, onChange)
      sliderBtn(btnTextInc(maxOvr),
        @() onChange(count.get() + bStep.get()),
        Computed(@() btnBgOvr.__merge(maxOvr.get())))
    ]
  })
}

function mkBulletSliderSlot(idx, selSlot, bInfo, bullets, bTotalSteps, bStep, maxBullets, withExtraBullets, bLeftSteps, hasUnseenShells, openedSlot, cardStyle, onChangeSlider) {
  let bSlot = Computed(@() bullets.get()?[idx])
  let bSet = Computed(@() bInfo.get()?.bulletSets[bSlot.get()?.name])
  let maxCount = Computed(@() min(bTotalSteps.get(),
    bInfo.get()?.fromUnitTags[bSlot.get()?.name]?.maxCount ?? bTotalSteps.get()))
  let maxCountByStep = Computed(@() maxCount.get() * bStep.get())
  let maxBulletsWithExtraCount = Computed(@() maxBullets.get()?[idx])
  let maxCountText = Computed(@() $"{!withExtraBullets.get() ? maxCountByStep.get() : maxBulletsWithExtraCount.get()}")
  let countText = Computed(@() $"{bSlot.get()?.count ?? 0}/{maxCountText.get()}")

  return @() {
    watch = bTotalSteps
    children = [
      {
        flow = FLOW_VERTICAL
        children = [
          bulletHeader(selSlot, bSlot, bSet, bInfo, bullets, hasUnseenShells, openedSlot)
          bTotalSteps.get() <= 1 ? null
            : mkBulletSliderWithBtns(bSlot, maxCount, maxBulletsWithExtraCount, withExtraBullets,
                bStep, bLeftSteps, cardStyle, onChangeSlider)
          bg.__merge({
            size = [flex(), bTotalSteps.get() <= 1 ? SIZE_TO_CONTENT : 0]
            children = @() {
              watch = countText
              rendObj = ROBJ_TEXT
              pos = [0, bTotalSteps.get() <= 1 ? 0 : -hdpx(40)]
              hplace = ALIGN_CENTER
              text = countText.get()
              color = 0xFFFFFFFF
            }.__update(fontTiny)
          })
        ]
      }
    ]
  }
}

return {
  mkBulletSliderSlot = kwarg(mkBulletSliderSlot)
  mkBulletSlider
}