from "%globalsDarg/darg_library.nut" import *
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { balance, WP, GOLD, WARBOND } = require("%appGlobals/currenciesState.nut")
let { SPARE } = require("%appGlobals/itemsState.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { isProfileReceived } = require("%appGlobals/pServer/campaign.nut")
let { isAuthorized } = require("%appGlobals/loginState.nut")
let { mkCurrencyComp, CS_GAMERCARD } = require("%rGui/components/currencyComp.nut")
let { gradCircularSmallHorCorners, gradCircCornerOffset } = require("%rGui/style/gradients.nut")
let { goodTextColor2, badTextColor2 } = require("%rGui/style/stdColors.nut")
let { mkBalanceDiffAnims, mkBalanceHiglightAnims } = require("balanceAnimations.nut")
let { isAdsVisible } = require("%rGui/ads/adsState.nut")
let { GPT_PREMIUM } = require("%rGui/shop/goodsPreviewState.nut")

let visibleBalance = hardPersistWatched("balance.visibleBalance", {})
let changeOrders = hardPersistWatched("balance.changeOrders", {})
let items = Computed(@() servProfile.value?.items ?? {})
isAuthorized.subscribe(function(_) {
  visibleBalance({})
  changeOrders({})
})

let incomeSounds = {
  [WP] = "meta_coins_income",
  [GOLD] = "meta_buy_gold",
  [WARBOND] = "meta_warbond_income",
  [SPARE] = "meta_backup_income",
  [GPT_PREMIUM] = "meta_premium_income"
}

let hoverBg = {
  size = [pw(120), flex()]
  color = 0x8052C4E4
  opacity = 1
  rendObj = ROBJ_9RECT
  image = gradCircularSmallHorCorners
  screenOffs = hdpx(100)
  texOffs = gradCircCornerOffset
}

let initCurrencyBalance = @(currencyId) currencyId in visibleBalance.value  || !currencyId ? null
  : visibleBalance.mutate(@(v) v[currencyId] <- balance.value?[currencyId])
let initItemBalance = @(itemId) itemId in visibleBalance.value ? null
  : visibleBalance.mutate(@(v) v[itemId] <- items.value?[itemId].count
      ?? (isProfileReceived.value ? 0 : null))

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

local prevBalance = clone balance.value
balance.subscribe(function(b) {
  let changes = {}
  let visBalanceApply = {}
  foreach (id, val in visibleBalance.value) {
    let cur = b?[id] ?? 0
    if (val == null) {
      visBalanceApply[id] <- cur
      continue
    }
    let diff = cur - (prevBalance?[id] ?? 0)
    if (diff != 0)
      changes[id] <- { cur, diff }
  }
  prevBalance = clone balance.value
  applyChanges(changes)
  if (visBalanceApply.len() > 0)
    visibleBalance(visibleBalance.value.__merge(visBalanceApply))
})

local prevItems = clone items.value
items.subscribe(function(it) {
  let changes = {}
  let visBalanceApply = {}
  foreach (id, val in visibleBalance.value) {
    let cur = it?[id].count ?? 0
    if (val == null) {
      visBalanceApply[id] <- cur
      continue
    }
    let diff = cur - (prevItems?[id].count ?? 0)
    if (diff != 0)
      changes[id] <- { cur, diff }
  }
  prevItems = clone items.value
  applyChanges(changes)
  if (visBalanceApply.len() > 0)
    visibleBalance(visibleBalance.value.__merge(visBalanceApply))
})

function onChangeAnimFinish(id, change) {
  if (change != changeOrders.value?[id][0] || id not in visibleBalance.value)
    return
  visibleBalance.mutate(@(v) v[id] = change.cur)
  changeOrders.mutate(@(v) v[id].remove(0))
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
  pos = [pw(30), ph(30)]
  rendObj = ROBJ_TEXT
  color = 0xFFFFFFFF
  text = "+"
}.__update(fontBigShaded)

function mkBalance(id, style, onClick, onAttach) {
  let visCount = Computed(@() visibleBalance.value?[id])
  let nextChange = Computed(@() isAdsVisible.value ? null : changeOrders.value?[id][0])
  let stateFlags = Watched(0)
  let currencyOvr = {
    watch = [visCount, stateFlags]
    transform = {}
    animations = mkBalanceHiglightAnims($"balance_{id}")
  }
  local imgChild = null
  if (onClick != null) {
    currencyOvr.__update({
      behavior = Behaviors.Button
      onClick
      onElemState = @(sf) stateFlags(sf)
      sound = { click  = "meta_shop_buttons" }
    })
    imgChild = plus
  }
  return {
    key = id
    onAttach
    children = [
      @() {
        watch = stateFlags
        size = flex()
        children = stateFlags.value & S_HOVER ? hoverBg : null
      }
      {
        children = [
          @() mkCurrencyComp(visCount.value ?? loc("leaderboards/notAvailable"), id, style, imgChild)
            .__update(currencyOvr,
              {
                transform = {
                  scale = (stateFlags.value & S_ACTIVE) != 0 ? [0.95, 0.95] : [1, 1]
                }
              })
          @() {
            watch = nextChange
            size = [0, 0] //to not affect parent size
            hplace = ALIGN_RIGHT
            vplace = ALIGN_BOTTOM
            children = nextChange.value == null ? null
              : mkChangeView(id, nextChange.value)
          }
        ]
      }
    ]
  }
}

function mkCurrencyBalance(currencyId, onClick = null, style = CS_GAMERCARD) {
  return mkBalance(currencyId, style, onClick, @() initCurrencyBalance(currencyId))
}

function mkItemsBalance(itemId, onClick = null, style = CS_GAMERCARD) {
  return mkBalance(itemId, style, onClick, @() initItemBalance(itemId))
}

return {
  mkCurrencyBalance
  mkItemsBalance
}