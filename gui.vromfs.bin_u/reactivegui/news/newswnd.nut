from "%globalsDarg/darg_library.nut" import *
let { clearTimer, setInterval } = require("dagor.workcycle")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { registerScene } = require("%rGui/navState.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let scrollbar = require("%rGui/components/scrollbar.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { formatText, selectorBtnW } = require("%rGui/news/textFormatters.nut")
let { isNewsWndOpened, curArticleId, curArticleIdx, playerSelectedArticleId, nextArticle, prevArticle,
  newsfeed, curArticleContent, articlesPerPage, pagesCount, curPageIdx,
  unreadArticles, markCurArticleSeen, closeNewsWnd
} = require("%rGui/news/newsState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")

let textColor = 0xFFFFFFFF
let contentBgColor = 0x990C1113
let tagRedColor = 0xC8C80000

let btnActive = 0xFFCFCFCF
let btnHovActive = 0xFFFFFFFF
let activeTextColor = 0xFF333333

let scrollHandler = ScrollHandler()
let scrollStep = hdpx(75)
let selectorBtnH = hdpx(110)
let selectorBtnMinGap = hdpx(10)
let selectorBtnGap = Watched(selectorBtnMinGap)
let selectorImgSize = hdpxi(92)

let scrollWatch = Watched(0)
let moreInfoUrl = $"https://wtmobile.com/{loc("current_lang")}"

let pagesStripW = hdpx(11)
let pagesStripGap = hdpx(30)
let pageH = hdpx(100)

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

let newMarkH = hdpxi(28)
let newMarkTexOffs = [ 0, newMarkH / 2, 0, newMarkH / 10 ]
let newMark = {
  size  = [ SIZE_TO_CONTENT, newMarkH ]
  rendObj = ROBJ_9RECT
  image = Picture($"ui/gameuiskin#tag_popular.svg:{newMarkH}:{newMarkH}:P")
  keepAspect = KEEP_ASPECT_NONE
  screenOffs = newMarkTexOffs
  texOffs = newMarkTexOffs
  color = tagRedColor
  padding = const [ 0, hdpx(20), 0, hdpx(10) ]
  children = {
    rendObj = ROBJ_TEXT
    color = 0xFFFFFFFF
    fontFx = FFT_GLOW
    fontFxFactor = hdpx(64)
    fontFxColor = 0xFF000000
    text = utf8ToUpper(loc("newsWnd/new_article_mark/short"))
    vplace = ALIGN_CENTER
  }.__update(fontVeryTinyShaded)
}

let pinIconSize = hdpxi(20)
let pinIcon = {
  rendObj = ROBJ_IMAGE
  size = [pinIconSize, pinIconSize]
  hplace = ALIGN_RIGHT
  margin = hdpx(5)
  image = Picture($"ui/gameuiskin#pin.svg:{pinIconSize}:{pinIconSize}:P")
  color = 0x40404040
  keepAspect = true
}

let thumbMaskPic = Picture($"ui/gameuiskin#circle.svg:{selectorImgSize}:{selectorImgSize}")
let mkThumbnailImg = @(thumb) {
  size = [selectorImgSize, selectorImgSize]
  rendObj = ROBJ_MASK
  image = thumbMaskPic
  children = {
    size = flex()
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
        size = flex()
        rendObj = ROBJ_SOLID
        color = contentBgColor
      }
      pinned > 0 ? pinIcon : null
      {
        size = flex()
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
        size = flex()
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
  let isSelected = Computed(@() curArticleId.value == id)
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
  size = [selectorBtnW + pagesStripGap + pagesStripW, flex()]
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
  size = flex()
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

let mkContent = @(content, title) {
  size = FLEX_H
  padding = const [hdpx(30), hdpx(75)]
  children = formatText(content.len() == 0 ? missedArticleText
    : [mkArticleTitle(title)].extend(content).append(seeMoreUrl))
}

let articleContent = @() {
  watch = curArticleContent
  size = flex()
  rendObj = ROBJ_SOLID
  color = contentBgColor
  children = curArticleContent.value == null ? articleLoading
    : [
        scrollbar.makeSideScroll(mkContent(curArticleContent.get().content, curArticleContent.get().title), {
          scrollHandler = scrollHandler
          joystickScroll = false
        })
        scrollArticleBtn("^J:R.Thumb.Up | PageUp", -1)
        scrollArticleBtn("^J:R.Thumb.Down | PageDown", 1)
      ]
}
let wndHeaderGap = hdpx(30)
let wndHeader = {
  size = FLEX_H
  valign = ALIGN_CENTER
  children = [
    backButton(function() {
      closeNewsWnd()
    })
    {
      rendObj = ROBJ_TEXT
      size = FLEX_H
      halign = ALIGN_CENTER
      color = textColor
      text = loc("newsWnd/header")
      margin = const [0, 0, 0, hdpx(15)]
    }.__update(fontBig)
  ]
}

function calcLayoutParams() {
  let selectorHeightPx = saSize[1] - calc_comp_size(wndHeader)[1] - wndHeaderGap
  articlesPerPage.set(max(1, ((selectorHeightPx + selectorBtnMinGap) / (selectorBtnH + selectorBtnMinGap)).tointeger()))
  let gapsCount = articlesPerPage.get() - 1
  selectorBtnGap.set(gapsCount > 0
    ? max(selectorBtnMinGap, ((selectorHeightPx - (selectorBtnH * articlesPerPage.get())) / gapsCount).tointeger())
    : 0)
}
calcLayoutParams()

let newsWnd = bgShaded.__merge({
  key = {}
  size = flex()
  padding = saBordersRv
  onDetach = markCurArticleSeen
  flow = FLOW_VERTICAL
  gap = wndHeaderGap
  children = [
    wndHeader
    {
      size = flex()
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
