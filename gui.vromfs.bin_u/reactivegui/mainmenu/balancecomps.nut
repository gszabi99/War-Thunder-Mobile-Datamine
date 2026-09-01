from "%globalsDarg/darg_library.nut" import *
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/currenciesState.nut" import balance, WP, GOLD, WARBOND, isBalanceReceived
from "%appGlobals/itemsState.nut" import SPARE
from "%appGlobals/loginState.nut" import isAuthorized
from "%appGlobals/pServer/campaign.nut" import isProfileReceived
from "%appGlobals/pServer/seasonCurrencies.nut" import currencyToFullId
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%rGui/ads/adsState.nut" import isAdsVisible
from "%rGui/components/currencyComp.nut" import mkCurrencyComp, CS_GAMERCARD
from "%rGui/mainMenu/balanceAnimations.nut" import mkBalanceDiffAnims, mkBalanceHiglightAnims
from "%rGui/shop/goodsPreviewState.nut" import GPT_PREMIUM
from "%rGui/style/gradients.nut" import gradCircularSmallHorCorners, gradCircCornerOffset
from "%rGui/style/stdColors.nut" import goodTextColor2, badTextColor2, hoverColor
from "%rGui/textFormatByLang.nut" import decimalFormat


let visibleBalance = hardPersistWatched("balance.visibleBalance", {})
let changeOrders = hardPersistWatched("balance.changeOrders", {})
let items = Computed(@() servProfile.get()?.items ?? {})
isAuthorized.subscribe(function(_) {
  visibleBalance.set({})
  changeOrders.set({})
})

let incomeSounds = {
  [WP] = "meta_coins_income",
  [GOLD] = "meta_buy_gold",
  [WARBOND] = "meta_warbond_income",
  [SPARE] = "meta_backup_income",
  [GPT_PREMIUM] = "meta_premium_income"
}

let hoverBg = {
  size = const [pw(120), FLEX]
  color = hoverColor
  opacity = 1
  rendObj = ROBJ_9RECT
  image = gradCircularSmallHorCorners
  screenOffs = hdpx(100)
  texOffs = gradCircCornerOffset
}

let initCurrencyBalance = @(currencyId) currencyId in visibleBalance.get()  || !currencyId ? null
  : visibleBalance.mutate(@(v) v[currencyId] <- balance.get()?[currencyId])
let initItemBalance = @(itemId) itemId in visibleBalance.get() ? null
  : visibleBalance.mutate(@(v) v[itemId] <- items.get()?[itemId].count
      ?? (isProfileReceived.get() ? 0 : null))

function applyChanges(changes) {
  if (changes.len() != 0)
    changeOrders.mutate(function(list) {
      foreach (id, info in changes) {
        let idList = id in list ? clone list[id] : []
        idList.append(info)
        list[id] <- idList
      }
    })
}

local prevBalance = clone balance.get()
balance.subscribe(function(b) {
  let changes = {}
  let visBalanceApply = {}
  foreach (id, val in visibleBalance.get()) {
    let cur = b?[id] ?? 0
    if (val == null) {
      visBalanceApply[id] <- cur
      continue
    }
    let diff = cur - (prevBalance?[id] ?? 0)
    if (diff != 0)
      changes[id] <- { cur, diff }
  }
  prevBalance = clone balance.get()
  applyChanges(changes)
  if (visBalanceApply.len() > 0)
    visibleBalance.set(visibleBalance.get().__merge(visBalanceApply))
})

local prevItems = clone items.get()
items.subscribe(function(it) {
  let changes = {}
  let visBalanceApply = {}
  foreach (id, val in visibleBalance.get()) {
    let cur = it?[id].count ?? 0
    if (val == null) {
      visBalanceApply[id] <- cur
      continue
    }
    let diff = cur - (prevItems?[id].count ?? 0)
    if (diff != 0)
      changes[id] <- { cur, diff }
  }
  prevItems = clone items.get()
  applyChanges(changes)
  if (visBalanceApply.len() > 0)
    visibleBalance.set(visibleBalance.get().__merge(visBalanceApply))
})

function onChangeAnimFinish(id, change) {
  if (change != changeOrders.get()?[id][0] || id not in visibleBalance.get())
    return
  visibleBalance.mutate(@(v) v[id] = change.cur)
  changeOrders.mutate(function(v) {
    let list = clone v[id]
    list.remove(0)
    v[id] = list
  })
  anim_start($"balance_{id}")
}

let diffStylePos = CS_GAMERCARD.__merge({
  iconSize = hdpxi(60)
  iconGap = hdpx(16)
  fontStyle = fontMedium
  textColor = goodTextColor2
})
let diffStyleNeg = diffStylePos.__merge({ textColor = badTextColor2 })

function getSoundForChange (id, change){
  if (change.diff > 0)
    return incomeSounds?[id] ?? "meta_consumables_income"
  return "meta_coins_outcome"
}

let mkChangeView = @(id, change) {
  key = change
  zOrder = Layers.Upper
  hplace = ALIGN_RIGHT
  vplace = ALIGN_CENTER
  children = mkCurrencyComp(change.diff > 0 ? $"+{decimalFormat(change.diff)}" : change.diff, id,
    change.diff > 0 ? diffStylePos : diffStyleNeg)
  transform = {}
  animations = mkBalanceDiffAnims(@() onChangeAnimFinish(id, change))
  sound = { attach = getSoundForChange(id, change) }
}

let plus = {
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  pos = const [pw(30), ph(30)]
  rendObj = ROBJ_TEXT
  color = 0xFFFFFFFF
  text = "+"
}.__update(fontBigShaded)

function mkBalance(baseId, style, onClick, initBalance) {
  let id = Computed(@() currencyToFullId.get()?[baseId] ?? baseId)
  id.subscribe(@(v) initBalance(v))

  let visCount = Computed(@() visibleBalance.get()?[id.get()]
    ?? (isBalanceReceived.get() ? 0 : loc("leaderboards/notAvailable")))
  let nextChange = Computed(@() isAdsVisible.get() ? null : changeOrders.get()?[id.get()][0])
  let stateFlags = Watched(0)
  let currencyOvr = {}
  local imgChild = null
  if (onClick != null) {
    currencyOvr.__update({
      behavior = Behaviors.Button
      onClick
      onElemState = @(sf) stateFlags.set(sf)
      sound = { click  = "meta_shop_buttons" }
    })
    imgChild = plus
  }
  return {
    key = baseId
    onAttach = @() initBalance(id.get())
    children = [
      @() {
        watch = stateFlags
        size = FLEX
        children = stateFlags.get() & S_HOVER ? hoverBg : null
      }
      {
        children = [
          @() mkCurrencyComp(visCount.get(), id.get(), style, imgChild)
            .__update(currencyOvr,
              {
                watch = [visCount, stateFlags, id]
                transform = {
                  scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.95, 0.95] : [1, 1]
                }
                animations = mkBalanceHiglightAnims($"balance_{id.get()}")
              })
          @() {
            watch = [nextChange, id]
            size = 0 
            hplace = ALIGN_RIGHT
            vplace = ALIGN_BOTTOM
            children = nextChange.get() == null ? null
              : mkChangeView(id.get(), nextChange.get())
          }
        ]
      }
    ]
  }
}

function mkCurrencyBalance(currencyId, onClick = null, style = CS_GAMERCARD) {
  return mkBalance(currencyId, style, onClick, initCurrencyBalance)
}

function mkItemsBalance(itemId, onClick = null, style = CS_GAMERCARD) {
  return mkBalance(itemId, style, onClick, initItemBalance)
}

return {
  mkCurrencyBalance
  mkItemsBalance
}