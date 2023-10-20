from "%globalsDarg/darg_library.nut" import *

let itemWidth = hdpx(280)
let itemHeight = hdpx(340)
let itemGap = hdpx(20)
let itemBigHeight = 2 * itemHeight + itemGap
let itemBigWidth = 2 * itemWidth + itemGap
let backItemOffset = hdpx(10)

let BEFORE_APPEAR = -1 //used only for animated show after switch full period
let BEFORE_7_DAY = 0
let AFTER_7_DAY = 1
let AFTER_14_DAY = 2 //previos blocks

let SLOT_COMMON = ""
let SLOT_BIG = "big"
let SLOT_HUGE = "huge"

let completeAnimDelay = 1.1
let animTime = 0.3
let disappearAnimTime = 0.2
let animOffsetTime = 0.1

let defaultPlace = {
  size = [itemWidth, itemHeight]
  slotType = SLOT_COMMON
  transformByState = {}
}

let rewardsPlaces = [
  {}
  { transformByState = { [BEFORE_7_DAY] = { translate = [itemWidth + itemGap, 0] } } }
  { transformByState = { [BEFORE_7_DAY] = { translate = [2 * (itemWidth + itemGap), 0] } } }
  { transformByState = { [BEFORE_7_DAY] = { translate = [0, itemHeight + itemGap] } } }
  { transformByState = { [BEFORE_7_DAY] = { translate = [itemWidth + itemGap, itemHeight + itemGap] } } }
  { transformByState = { [BEFORE_7_DAY] = { translate = [2 * (itemWidth + itemGap), itemHeight + itemGap] } } }
  //day 7 big reward
  {
    slotType = SLOT_BIG
    size = [itemWidth, itemBigHeight]
    transformByState = {
      [BEFORE_7_DAY] = { translate = [3 * (itemWidth + itemGap), 0] },
      [AFTER_7_DAY] = { translate = [0, 0], animDelay = 0.0 },
    }
  }
  {
    transformByState = {
      [BEFORE_7_DAY] = { translate = [3 * (itemWidth + itemGap) + backItemOffset, backItemOffset] },
      [AFTER_7_DAY] = { translate = [itemWidth + itemGap, 0],
        animDelay = animOffsetTime
      },
    }
  }
  {
    transformByState = {
      [BEFORE_7_DAY] = { translate = [3 * (itemWidth + itemGap) + backItemOffset, backItemOffset] },
      [AFTER_7_DAY] = { translate = [2 * (itemWidth + itemGap), 0],
        animDelay = 2 * animOffsetTime
      },
    }
  }
  {
    transformByState = {
      [BEFORE_7_DAY] = { translate = [3 * (itemWidth + itemGap) + backItemOffset, backItemOffset] },
      [AFTER_7_DAY] = { translate = [3 * (itemWidth + itemGap), 0],
        animDelay = 3 * animOffsetTime
      },
    }
  }
  {
    transformByState = {
      [BEFORE_7_DAY] = { translate = [3 * (itemWidth + itemGap) + backItemOffset, itemHeight + itemGap + backItemOffset] },
      [AFTER_7_DAY] = { translate = [itemWidth + itemGap, itemHeight + itemGap],
        animDelay = 4 * animOffsetTime
      },
    }
  }
  {
    transformByState = {
      [BEFORE_7_DAY] = { translate = [3 * (itemWidth + itemGap) + backItemOffset, itemHeight + itemGap + backItemOffset] },
      [AFTER_7_DAY] = { translate = [2 * (itemWidth + itemGap), itemHeight + itemGap]
        animDelay = 5 * animOffsetTime
      },
    }
  }
  {
    transformByState = {
      [BEFORE_7_DAY] = { translate = [3 * (itemWidth + itemGap) + backItemOffset, itemHeight + itemGap + backItemOffset] },
      [AFTER_7_DAY] = { translate = [3 * (itemWidth + itemGap), itemHeight + itemGap],
        animDelay = 6 * animOffsetTime
      },
    }
  }
  //day 14 biggest reward
  {
    slotType = SLOT_HUGE
    size = [itemBigWidth, itemBigHeight]
    transformByState = {
      [BEFORE_7_DAY] = { translate = [4 * (itemWidth + itemGap), 0] },
      [AFTER_7_DAY] = { translate = [4 * (itemWidth + itemGap), 0] },
    }
  }
].map(function(v, idx) {
  let res = defaultPlace.__merge(v)
  let offsetY = res.transformByState?[BEFORE_7_DAY].translate[1] ?? 0
  let disappear = {
    opacity = 0.0,
    translate = [-itemBigWidth, offsetY],
    animTime = disappearAnimTime
  }
  let defValue = {
    opacity = 1.0,
    translate = [0.0, 0.0],
    animTime,
    animDelay = idx * animOffsetTime
  }
  res.transformByState <- {
    [BEFORE_APPEAR] = {
      opacity = 0.0
      translate = [
        4 * (itemWidth + itemGap) + itemBigWidth - res.size[0] + backItemOffset,
        offsetY + backItemOffset
      ]
    },
    [BEFORE_7_DAY] = defValue,
    [AFTER_7_DAY] = disappear,
    [AFTER_14_DAY] = disappear,
  }.map(function(val, k) {
      if (k not in res.transformByState)
        return val
      return defValue.__merge(res.transformByState[k])
    })
  return res
})

let FULL_DAYS = rewardsPlaces.len()
let moveCardsFullTime = animTime + FULL_DAYS * animOffsetTime
let moveCardsHalfTime = animTime + FULL_DAYS / 2 * animOffsetTime

return {
  FULL_DAYS
  BEFORE_APPEAR
  BEFORE_7_DAY
  AFTER_7_DAY
  AFTER_14_DAY
  SLOT_COMMON
  SLOT_BIG
  SLOT_HUGE

  itemWidth
  itemHeight
  itemGap
  itemBigHeight
  itemBigWidth
  backItemOffset
  rewardsPlaces

  completeAnimDelay
  moveCardsFullTime
  moveCardsHalfTime
}