from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { G_ITEM, G_BOOSTER } = require("%appGlobals/rewardType.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { campConfigs, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { convert_items, ItemConversionInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { getCurrencyImage } = require("%appGlobals/config/currencyPresentation.nut")
let { getBoosterIcon } = require("%appGlobals/config/boostersPresentation.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { mkColoredGradientY } = require("%rGui/style/gradients.nut")
let { textColor, selectColor } = require("%rGui/style/stdColors.nut")
let { openMsgBox, msgBoxText } = require("%rGui/components/msgBox.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { textButtonPrimary, textButtonInactive } = require("%rGui/components/textButton.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeaderWithClose } = require("%rGui/components/modalWnd.nut")
let { mkSliderKnob, sliderWithButtons } = require("%rGui/components/slider.nut")
let { mkRewardPlate } = require("%rGui/rewards/rewardPlateComp.nut")
let { REWARD_STYLE_MEDIUM } = require("%rGui/rewards/rewardStyles.nut")


let WND_UID = "barter"

let leftImgSize = hdpxi(140)
let rightImgSize = hdpxi(200)
let knobHeight = evenPx(31)
let sliderTouchableHeight = knobHeight + hdpx(44)
let sliderWidth = hdpx(518)

let knobGrad = mkColoredGradientY(0xFFFFFFFF, 0xFF555555)

let getRType = @(name, sConfigs) name in sConfigs?.allBoosters ? G_BOOSTER
  : name in sConfigs?.allItems ? G_ITEM
  : null

let closeBarterWnd = @() removeModalWindow(WND_UID)

let knobCtor = @(relValue, stateFlags, fullW) mkSliderKnob(relValue, stateFlags, fullW,
  {
    rendObj = ROBJ_BOX
    size = [evenPx(13), knobHeight]
    borderColor = 0xFF000000
    borderWidth = hdpx(2)
    children = {
      rendObj = ROBJ_IMAGE
      size = flex()
      image = knobGrad
    }
  })

let txt = @(text) {
  text
  rendObj = ROBJ_TEXT
  behavior = Behaviors.Marquee
  color = textColor
}.__merge(fontTinyShaded)

function mkFromRow(conversionInfo, fromAllTotal) {
  let { fromName, from, to } = conversionInfo
  let rType = Computed(@() getRType(fromName, serverConfigs.get()))
  let imagePath = Computed(@() rType.get() == G_BOOSTER ? getBoosterIcon(fromName) : getCurrencyImage(fromName))
  let count = Computed(@() rType.get() == G_BOOSTER ? (servProfile.get()?.boosters[fromName].battlesLeft ?? 0)
    : rType.get() == G_ITEM ? (servProfile.get()?.items[fromName].count ?? 0)
    : 0)
  let fromTotal = Computed(@() min(fromAllTotal.get()?[fromName] ?? 0, count.get()))
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    gap = hdpx(60)
    children = [
      {
        flow = FLOW_VERTICAL
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = [
          @() {
            watch = imagePath
            size = [leftImgSize, leftImgSize]
            rendObj = ROBJ_IMAGE
            image = Picture($"{imagePath.get()}:{leftImgSize}:{leftImgSize}:P")
            keepAspect = true
          }
          @() txt(from * fromTotal.get()).__update({ watch = fromTotal })
        ]
      }
      @() {
        watch = count
        key = count
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        gap = hdpx(32)
        children = sliderWithButtons(fromTotal,
          {
            size = SIZE_TO_CONTENT
            hplace = ALIGN_RIGHT
            vplace = ALIGN_TOP
            valign = ALIGN_BOTTOM
            flow = FLOW_HORIZONTAL
            children = [
              txt(from)
              txt(" >>> ").__update({ color = selectColor })
              txt(to).__update({ color = selectColor })
            ]
          },
          {
            min = 0
            max = count.get()
            onChange = @(v) fromAllTotal.mutate(@(f) f[fromName] <- v)
            knobCtor
            size = [sliderWidth, sliderTouchableHeight]
          })
      }
    ]
  }
}

function mkBarterContent(itemId, prices, fromAllTotal) {
  let toTotal = Computed(@() prices.get()
    .reduce(@(res, p) res += (fromAllTotal.get()?[p.fromName] ?? 0) * p.to, 0))
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    gap = hdpx(20)
    children = [
      @() {
        watch = prices
        flow = FLOW_VERTICAL
        gap = hdpx(20)
        children = prices.get().values().map(@(p) mkFromRow(p, fromAllTotal))
      }
      {
        flow = FLOW_VERTICAL
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = [
          {
            size = [rightImgSize, rightImgSize]
            rendObj = ROBJ_IMAGE
            image = Picture($"{getCurrencyImage(itemId)}:{rightImgSize}:{rightImgSize}:P")
            keepAspect = true
          }
          @() txt(toTotal.get()).__update({ watch = toTotal })
        ]
      }
    ]
  }
}

let mkItemPlates = @(items) {
  flow = FLOW_HORIZONTAL
  gap = hdpx(12)
  children = items.map(@(v) mkRewardPlate(v, REWARD_STYLE_MEDIUM))
}

function tryConvertItems(itemId, prices, fromTotal) {
  let from = {}
  let to = {}
  let itemConversions = []
  foreach (fromName, fromAmount in fromTotal) {
    if (fromAmount <= 0)
      continue
    let toAmount = fromAmount * (prices?[fromName].to ?? 0)
    itemConversions.append({ fromName, fromAmount, toName = itemId, toAmount })
    if (itemId not in to)
      to[itemId] <- {
        slots = 1,
        rType = G_ITEM,
        count = 0,
        id = itemId
      }
    to[itemId].count += toAmount
    if (fromName not in from)
      from[fromName] <- {
        slots = 1,
        rType = getRType(fromName, serverConfigs.get())
        count = 0,
        id = fromName
      }
    from[fromName].count += fromAmount
  }
  if (itemConversions.len() <= 0)
    return

  openMsgBox({
    uid = "confirmBarter"
    text = {
      size = flex()
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      gap = hdpx(4)
      children = [
        msgBoxText(loc("item/conversion/needQuestion"))
        mkItemPlates(from.values())
        msgBoxText(loc("item/conversion/needQuestion/for"))
        mkItemPlates(to.values())
      ]
    }
    buttons = [
      { id = "cancel", isCancel = true }
      { id = "apply", styleId = "PRIMARY", isDefault = true,
        function cb() {
          convert_items(curCampaign.get(), itemConversions)
          closeBarterWnd()
        }
      }
    ]
  })
}

return function openBarterImpl(itemId) {
  let fromAllTotal = Watched({})
  let prices = Computed(function() {
    let res = {}
    foreach (fromName, items in (campConfigs.get()?.itemConversionsCfg ?? {})) {
      let v = items.findvalue(@(_, k) k == itemId)
      if (v != null)
        res[fromName] <- v.__merge({ fromName })
    }
    return res
  })
  let canApply = Computed(@() null != fromAllTotal.get().findvalue(@(v) v > 0))
  addModalWindow(bgShaded.__merge({
    key = WND_UID
    size = flex()
    children = modalWndBg.__merge({
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      children = [
        modalWndHeaderWithClose(utf8ToUpper(loc("item/conversion/btn_barter")), closeBarterWnd)
        @() {
          watch = canApply
          flow = FLOW_VERTICAL
          halign = ALIGN_CENTER
          gap = hdpx(40)
          padding = const [hdpx(40), hdpx(60)]
          children = [
            mkBarterContent(itemId, prices, fromAllTotal)
            mkSpinnerHideBlock(ItemConversionInProgress, !canApply.get()
              ? textButtonInactive(utf8ToUpper(loc("mainmenu/btnApply")), @() null)
              : textButtonPrimary(utf8ToUpper(loc("mainmenu/btnApply")),
                  @() !canApply.get() ? null : tryConvertItems(itemId, prices.get(), fromAllTotal.get())))
          ]
        }
      ]
    })
  }))
}