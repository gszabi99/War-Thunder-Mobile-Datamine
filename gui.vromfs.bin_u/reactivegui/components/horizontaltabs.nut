from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { gradTexSize, mkGradientCtorRadial } = require("%rGui/style/gradients.nut")
let { opacityTransition } = require("%rGui/components/selectedLine.nut")
let { selectColor } = require("%rGui/style/stdColors.nut")

let iconSizeDef = hdpxi(60)
let tabHeight = hdpx(120)

let textColor = 0xFFFFFFFF
let bgColor = 0x990C1113

let bgGradient = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(selectColor, 0, 35, 15, 30, -35))

let mkTabContent = @(content, isActive, isHover) {
  size = FLEX_H
  children = [
    {
      size = flex()
      rendObj = ROBJ_SOLID
      color = bgColor
    }
    @() {
      watch = [isActive, isHover]
      size = flex()
      rendObj = ROBJ_IMAGE
      image = bgGradient()
      flipY = true
      opacity = isActive.get() ? 1
        : isHover.get() ? 0.5
        : 0
      transitions = opacityTransition
    }
  ].append(content)
}

function mkTabImage(image, imageSizeMul) {
  let size = (iconSizeDef * imageSizeMul + 0.5).tointeger()
  let blockSize = max(iconSizeDef, size)
  return {
    size = [blockSize, blockSize]
    vplace = ALIGN_CENTER
    children = {
      size = [size, size]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      rendObj = ROBJ_IMAGE
      image = Picture($"{image}:{size}:{size}:P")
      color = textColor
      keepAspect = KEEP_ASPECT_FIT
    }
  }
}

function tabData(tab, idx) {
  let { locId  = "", image = null } = tab
  return {
    id = idx
    content = {
      size = [flex(), tabHeight]
      padding = const [hdpx(10), hdpx(20)]
      children = [
        {
          size = flex()
          flow = FLOW_HORIZONTAL
          halign = ALIGN_CENTER
          gap = hdpx(20)
          children = [
            image == null ? null
              : image instanceof Watched ? @() mkTabImage(image.get(), 1.0).__update({ watch = image })
              : mkTabImage(image, 1.0)
            {
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              vplace = ALIGN_CENTER
              color = textColor
              text = loc(locId)
            }.__update(fontTinyAccented)
          ]
        }
      ]
    }
  }
}

function mkTab(data, curTabIdx) {
  let stateFlags = Watched(0)
  let isActive = Computed (@() curTabIdx.get() == data.id || (stateFlags.get() & S_ACTIVE) != 0)
  let isHover = Computed (@() stateFlags.get() & S_HOVER)

  return {
    size = FLEX_H
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags.set(v)
    clickableInfo = loc("mainmenu/btnSelect")
    onClick = @() curTabIdx.set(data.id)
    sound = { click = "choose" }
    children = mkTabContent(data.content, isActive, isHover)
  }
}

let mkHorizontalTabs = @(tabs, curTabIdx) {
  size = FLEX_H
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(8)
  children = tabs.map(@(tab, idx) mkTab(tabData(tab, idx), curTabIdx))
}

return { mkHorizontalTabs }