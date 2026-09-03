from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import clearTimer, setInterval
from "%sqstd/string.nut" import utf8ToUpper
import "%darg/helpers/mkFormatAst.nut" as mkFormatAst
from "%appGlobals/activeControls.nut" import isGamepad
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/gradientDefComps.nut" import headerGradientWithRightBlock, headerHeightInSafeArea
from "%rGui/components/mkDropDownMenu.nut" import mkDropMenuBtn
import "%rGui/components/scrollbar.nut" as scrollbar
from "%rGui/components/spinner.nut" import spinner
from "%rGui/language.nut" import wtmobLngId
from "%rGui/navState.nut" import registerScene
from "%rGui/news/newsState.nut" import isNewsWndOpened, curArticleId, curArticleIdx, playerSelectedArticleId,
  nextArticle, prevArticle, newsfeed, curArticleContent, articlesPerPage, pagesCount, curPageIdx, unreadArticles,
  markCurArticleSeen, closeNewsWnd, curNewsStyle, fontsCfg
from "%rGui/news/textFormatters.nut" import formatText, selectorBtnW, formatters, filterFormat
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/stdColors.nut" import tabBgColor


const textColor = 0xFFFFFFFF
const tagRedColor = 0xC8C80000

const btnActive = 0xFFCFCFCF
const btnHovActive = 0xFFFFFFFF
const activeTextColor = 0xFF333333

let scrollHandler = ScrollHandler()
const scrollStep = hdpx(75)
const selectorBtnH = hdpx(110)
const selectorBtnMinGap = hdpx(10)
let selectorBtnGap = Watched(selectorBtnMinGap)
const selectorImgSize = hdpxi(92)

let scrollWatch = Watched(0)
let moreInfoUrl = $"https://wtmobile.com/{wtmobLngId}"

const pagesStripW = hdpx(11)
const pagesStripGap = hdpx(30)
const pageH = hdpx(100)

function mkPage(startArticleIdx, isSelected) {
  let stateFlags = Watched(0)
  return @() {
    watch = [isSelected, stateFlags]
    size = [isSelected.get() ? pagesStripW : (0.5 * pagesStripW), pageH]
    rendObj = ROBJ_SOLID
    color = (isSelected.get() || (stateFlags.get() & S_HOVER)) ? 0xFFFFFFFF : 0xFFBEBEBE
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.8, 0.8] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = Linear }]
    sound = { click  = "click" }
    function onClick() {
      markCurArticleSeen()
      playerSelectedArticleId.set(newsfeed.get()?[startArticleIdx].id)
    }
  }
}

function pagesStrip() {
  let children = []
  for (local i = 0; i < pagesCount.get(); i++) {
    let startArticleIdx = i * articlesPerPage.get()
    let isSelected = Computed(@() curArticleIdx.get() >= startArticleIdx && curArticleIdx.get() < startArticleIdx + articlesPerPage.get())
    children.append(mkPage(startArticleIdx, isSelected))
  }
  return {
    watch = [pagesCount, articlesPerPage]
    size = FLEX_V
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = pagesStripW
    children
  }
}

const newMarkH = hdpxi(28)
let newMarkTexOffs = [ 0, newMarkH / 2, 0, newMarkH / 10 ]
let newMark = {
  size  = const [ SIZE_TO_CONTENT, newMarkH ]
  rendObj = ROBJ_9RECT
  image = Picture($"ui/gameuiskin#tag_popular.svg:{newMarkH}:{newMarkH}:P")
  screenOffs = newMarkTexOffs
  texOffs = newMarkTexOffs
  color = tagRedColor
  padding = const [ 0, hdpx(20), 0, hdpx(10) ]
  children = {
    rendObj = ROBJ_TEXT
    color = 0xFFFFFFFF
    text = utf8ToUpper(loc("newsWnd/new_article_mark/short"))
    vplace = ALIGN_CENTER
  }.__update(fontVeryTinyShaded)
}

const pinIconSize = hdpxi(20)
let pinIcon = {
  rendObj = ROBJ_IMAGE
  size = const [pinIconSize, pinIconSize]
  hplace = ALIGN_RIGHT
  margin = hdpx(5)
  image = Picture($"ui/gameuiskin#pin.svg:{pinIconSize}:{pinIconSize}:P")
  color = 0x40404040
  keepAspect = true
}

let thumbMaskPic = Picture($"ui/gameuiskin#circle.svg:{selectorImgSize}:{selectorImgSize}:P")
let mkThumbnailImg = @(thumb) {
  size = const [selectorImgSize, selectorImgSize]
  rendObj = ROBJ_MASK
  image = thumbMaskPic
  children = {
    size = FLEX
    rendObj = ROBJ_IMAGE
    image = Picture(thumb)
    keepAspect = KEEP_ASPECT_FILL
    imageHalign = ALIGN_CENTER
    imageValign = ALIGN_CENTER
  }
}

let opacityTransition = [{ prop = AnimProp.opacity, duration = 0.3, easing = InOutQuad }]

function articleTabBase(info, sf, isSelected, isUnseen) {
  let isActive = isSelected || (sf & S_ACTIVE) != 0
  let isHovered = sf & S_HOVER
  let { shortTitle, title, thumb, pinned } = info
  return {
    size = [selectorBtnW, selectorBtnH]
    children = [
      {
        size = FLEX
        rendObj = ROBJ_SOLID
        color = tabBgColor
      }
      pinned > 0 ? pinIcon : null
      {
        size = FLEX
        rendObj = ROBJ_BOX
        fillColor = isActive && isHovered ? btnHovActive
          : !isHovered && isActive ? btnActive
          : 0
        borderColor = textColor
        borderWidth = isActive ? 0 : hdpx(2)
        opacity = isActive ? 1
          : isHovered ? 0.5
          : 0
        transitions = opacityTransition
      }
      {
        size = FLEX
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        padding = const [hdpx(4), hdpx(12), hdpx(4), hdpx(4)]
        gap = hdpx(10)
        children = [
          thumb == null ? null : mkThumbnailImg(thumb)
          {
            size = FLEX_H
            maxHeight = ph(100)
            behavior = [Behaviors.TextArea, Behaviors.Marquee]
            rendObj = ROBJ_TEXTAREA
            halign = ALIGN_RIGHT
            color = isActive ? activeTextColor : textColor
            text = shortTitle ?? title

            
            orientation = O_VERTICAL
            speed = hdpx(30)
            delay = defMarqueeDelay
          }.__update(fontTiny)
        ]
      }
      @() { watch = isUnseen }.__update(isUnseen.get() ? newMark : {})
    ]
  }
}

function articleTab(info) {
  let stateFlags = Watched(0)
  let { id } = info
  let isSelected = Computed(@() curArticleId.get() == id)
  let isUnseen = Computed(@() unreadArticles.get()?[id] ?? false)
  return @() {
    watch = [isSelected, stateFlags]
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = Linear }]
    sound = { click  = "click" }
    function onClick() {
      markCurArticleSeen()
      playerSelectedArticleId.set(id)
    }
    children = articleTabBase(info, stateFlags.get(), isSelected.get(), isUnseen)
  }
}

let tabsHotkeys = [
  ["J:LB", nextArticle, loc("mainmenu/btnPagePrev")],
  ["J:RB", prevArticle, loc("mainmenu/btnPageNext")],
]
let articleSelector = @() {
  watch = [newsfeed, curPageIdx, articlesPerPage, selectorBtnGap, isGamepad]
  size = [selectorBtnW + pagesStripGap + pagesStripW, FLEX]
  flow = FLOW_HORIZONTAL
  gap = pagesStripGap
  children = newsfeed.get().len() == 0 ? null : [
    {
      size = FLEX_V
      flow = FLOW_VERTICAL
      gap = selectorBtnGap.get()
      children = newsfeed.get()
        .slice(curPageIdx.get() * articlesPerPage.get(), (curPageIdx.get() + 1) * articlesPerPage.get())
        .map(articleTab)
    }
    newsfeed.get().len() <= articlesPerPage.get() ? null : pagesStrip
    !isGamepad.get() || newsfeed.get().len() <= 1 ? null : { hotkeys = tabsHotkeys }
  ]
}

let missedArticleText = formatText([loc("NoUpdateInfo")])

let seeMoreUrl = {
  t = "url"
  url = moreInfoUrl
  v = loc("visitGameSite", "See game website for more details")
  margin = const [hdpx(50), 0, 0, 0]
}

function scrollArticle() {  
  let element = scrollHandler.elem
  if (element != null)
    scrollHandler.scrollToY(element.getScrollOffsY() + scrollWatch.get() * scrollStep)
}

scrollWatch.subscribe(function(value) {
  clearTimer(scrollArticle)
  if (value == 0)
    return

  scrollArticle()
  setInterval(0.1, scrollArticle)
})

let scrollArticleBtn = @(hotkey, watchValue) {
  behavior = Behaviors.Button
  onElemState = @(sf) scrollWatch.set((sf & S_ACTIVE) ? watchValue : 0)
  hotkeys = [[hotkey]]
  onDetach = @() scrollWatch.set(0)
}

curArticleContent.subscribe(@(_) scrollHandler.scrollToY(0))

let articleLoading = freeze({
  size = FLEX
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow  = FLOW_VERTICAL
  gap = hdpx(20)
  children = [
    formatText([{ v = loc("loading"), t = "h2", halign = ALIGN_CENTER }]),
    spinner
  ]
})
let mkArticleTitle = @(title) {
  behavior = Behaviors.TextArea
  rendObj = ROBJ_TEXTAREA
  size = FLEX_H
  color = textColor
  text = title
  margin = const [0, 0, hdpx(15), 0]
}.__update(fontLarge)

let mkContent = @(content, title, formatter) {
  size = FLEX_H
  padding = const [hdpx(30), hdpx(75)]
  children = formatter(content.len() == 0 ? missedArticleText
    : [mkArticleTitle(title)].extend(content).append(seeMoreUrl))
}

let articleContent = @() {
  watch = [curArticleContent, curNewsStyle]
  size = FLEX
  rendObj = ROBJ_SOLID
  color = tabBgColor
  children = curArticleContent.get() == null ? articleLoading
    : [
        scrollbar.makeSideScroll(mkContent(curArticleContent.get().content, curArticleContent.get().title, mkFormatAst({formatters, filter = filterFormat, style = curNewsStyle.get()})), {
          scrollHandler = scrollHandler
          joystickScroll = false
        })
        scrollArticleBtn("^J:R.Thumb.Up | PageUp", -1)
        scrollArticleBtn("^J:R.Thumb.Down | PageDown", 1)
      ]
}

let wndHeader = headerGradientWithRightBlock(
  [
    backButton(closeNewsWnd),
    {
      rendObj = ROBJ_TEXT
      halign = ALIGN_LEFT
      color = textColor
      text = loc("newsWnd/header")
    }.__update(fontBig)
  ],
  {
    hplace = ALIGN_RIGHT
    children = mkDropMenuBtn(@() [fontsCfg],
      Watched(0),
      "ui/gameuiskin#icon_menu_settings.svg",
      hdpx(65))
  })

function calcLayoutParams() {
  let selectorHeightPx = saSize[1] - headerHeightInSafeArea
  articlesPerPage.set(max(1, ((selectorHeightPx + selectorBtnMinGap) / (selectorBtnH + selectorBtnMinGap)).tointeger()))
  let gapsCount = articlesPerPage.get() - 1
  selectorBtnGap.set(gapsCount > 0
    ? max(selectorBtnMinGap, ((selectorHeightPx - (selectorBtnH * articlesPerPage.get())) / gapsCount).tointeger())
    : 0)
}
calcLayoutParams()

let newsWnd = bgShaded.__merge({
  key = {}
  size = FLEX
  padding = saBordersRv
  onDetach = markCurArticleSeen
  flow = FLOW_VERTICAL
  children = [
    wndHeader
    {
      size = FLEX
      flow = FLOW_HORIZONTAL
      gap = hdpx(30)
      children = [
        articleContent
        articleSelector
      ]
    }
  ]
  animations = wndSwitchAnim
})

registerScene("newsWnd", newsWnd, closeNewsWnd, isNewsWndOpened)
