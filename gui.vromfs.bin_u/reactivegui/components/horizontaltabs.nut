from "%globalsDarg/darg_library.nut" import *
from "%darg/helpers/bitmap.nut" import mkBitmapPictureLazy
from "%rGui/components/selectedLine.nut" import opacityTransition
from "%rGui/style/gradients.nut" import gradTexSize, mkGradientCtorRadial
from "%rGui/style/stdColors.nut" import selectColor, tabBgColor


const iconSizeDef = hdpxi(60)
const tabHeight = hdpx(120)

const textColor = 0xFFFFFFFF

let bgGradient = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(selectColor, 0, 35, 15, 30, -35))

let mkTabContent = @(content, isActive, isHover, ovr = {}) {
  size = FLEX_H
  children = [
    {
      size = FLEX
      rendObj = ROBJ_SOLID
      color = tabBgColor
    }
    @() {
      watch = [isActive, isHover]
      size = FLEX
      rendObj = ROBJ_IMAGE
      image = bgGradient()
      flipY = true
      opacity = isActive.get() ? 1
        : isHover.get() ? 0.5
        : 0
      transitions = opacityTransition
    }
  ].append(content)
}.__update(ovr)

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

function mkTabImageChild(image) {
  return image == null ? null
    : image instanceof Watched ? @() mkTabImage(image.get(), 1.0).__update({ watch = image })
    : mkTabImage(image, 1.0)
}

function mkTabTextChild(locId) {
  return {
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    vplace = ALIGN_CENTER
    color = textColor
    text = loc(locId)
  }.__update(fontTinyAccented)
}

function tabData(tab, idx) {
  let { id = idx, locId  = "", image = null, isVisible = null } = tab
  return {
    id
    isVisible
    isAutoWidth = false
    content = {
      size = [FLEX, tabHeight]
      padding = const [hdpx(10), hdpx(20)]
      children = {
        size = FLEX
        flow = FLOW_HORIZONTAL
        halign = ALIGN_CENTER
        gap = hdpx(20)
        children = [mkTabImageChild(image), mkTabTextChild(locId)]
      }
    }
  }
}


function tabDataSelectedText(tab, idx, curTabIdx, ovr = {}) {
  let { id = idx, locId  = "", image = null, isVisible = null } = tab
  let { height = tabHeight } = ovr
  let imageChild = mkTabImageChild(image)
  let textChild = mkTabTextChild(locId)
  return {
    id
    isVisible
    isAutoWidth = true
    content = {
      size = [SIZE_TO_CONTENT, height]
      padding = const [hdpx(10), hdpx(20)]
      children = @() {
        watch = curTabIdx
        size = SIZE_TO_CONTENT
        flow = FLOW_HORIZONTAL
        halign = ALIGN_CENTER
        gap = hdpx(20)
        children = [imageChild, curTabIdx.get() == id ? textChild : null]
      }
    }.__update(ovr)
  }
}

function mkTab(data, curTabIdx) {
  let stateFlags = Watched(0)
  let isActive = Computed(@() curTabIdx.get() == data.id || (stateFlags.get() & S_ACTIVE) != 0)
  let isHover = Computed(@() stateFlags.get() & S_HOVER)

  return {
    size = data.isAutoWidth ? SIZE_TO_CONTENT : FLEX_H
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags.set(v)
    clickableInfo = loc("mainmenu/btnSelect")
    onClick = @() curTabIdx.set(data.id)
    sound = { click = "choose" }
    children = mkTabContent(data.content, isActive, isHover, data.isAutoWidth ? { size = SIZE_TO_CONTENT } : {})
  }
}

let tabsRoot = {
  size = FLEX_H
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(8)
}

function mkTabsRoot(tabsData, curTabIdx, ovr = {}) {
  let watch = tabsData.map(@(t) t?.isVisible).filter(@(v) v != null)
  let root = tabsRoot.__merge(ovr)
  return watch.len() == 0 ? root.__merge({ children = tabsData.map(@(tab) mkTab(tab, curTabIdx)) })
    : @() root.__merge({
        watch
        children = tabsData
          .filter(@(tab) tab?.isVisible.get() ?? true)
          .map(@(tab) mkTab(tab, curTabIdx))
      })
}

function mkHorizontalTabs(tabs, curTabIdx) {
  return mkTabsRoot(tabs.map(@(tab, idx) tabData(tab, idx)), curTabIdx)
}

function mkHorizontalTabsSelectedText(tabs, curTabIdx, halign = null, height = tabHeight) {
  return mkTabsRoot(
    tabs.map(@(tab, idx) tabDataSelectedText(tab, idx, curTabIdx, { height })),
    curTabIdx,
    halign == null ? {} : { halign })
}

return { mkHorizontalTabs, mkHorizontalTabsSelectedText }