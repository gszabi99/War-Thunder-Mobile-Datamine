from "%globalsDarg/darg_library.nut" import *
let { registerScene, setSceneBg } = require("%rGui/navState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { increase_calendar_value, isCalendarRewardInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { wndSwitchAnim }= require("%rGui/style/stdAnimations.nut")
let { REWARD_STYLE_MEDIUM, mkRewardPlate, mkRewardReceivedMark } = require("%rGui/rewards/rewardPlateComp.nut")
let { subCalendar, subCalendarProfile, canReceiveSubCalendarReward, subCalendarValue } = require("calendarState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { getRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { simpleHorGrad } = require("%rGui/style/gradients.nut")
let { textButtonSecondary, textButtonInactive } = require("%rGui/components/textButton.nut")
let { secondsToTimeAbbrString } = require("%appGlobals/timeToText.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")

const WND_UID = "subCalendarWnd"
const wndGap = hdpx(40)

const bgColor = 0xFF000000
const fillColor = 0xFFFFFFFF

function calcTimeToNextReward(valueTime, interval, time) {
  if (valueTime <= 0)
    return 0
  let remain = (valueTime + interval) - time
  return remain > 0 ? remain : 0
}

let isOpened = mkWatched(persist, "isOpened", false)
let close = @() isOpened.set(false)

let header = {
  pos = [-saBordersRv[1], 0]
  rendObj = ROBJ_IMAGE
  image = simpleHorGrad
  color = 0x80000000
  padding = const [hdpx(20), hdpx(50), hdpx(17), saBordersRv[1]]
  flipX = true
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(20)
  children = [
    backButton(close)
    {
      rendObj = ROBJ_TEXT
      text = loc("monthlyLoginCalendar/header")
    }.__update(fontBig)
  ]
}

let progressBar = @(r, prevValue) function() {
  let groupSize = r.value - prevValue

  if (groupSize <= 1) {
    return {
      size = const [flex(), hdpx(10)]
      rendObj = ROBJ_FRAME
      borderWidth = hdpx(2)
      color = bgColor
      fillColor = r.value > subCalendarValue.get() ? 0xFF000000 : 0xFFFFFFFF
    }
  }

  let progressCount = clamp(subCalendarValue.get().tointeger() - prevValue, 0, groupSize)
  let progress = groupSize > 0 ? (1.0 * progressCount) / groupSize : 0

  return {
    watch = subCalendarValue
    size = const [flex(), hdpx(10)]
    padding = hdpx(2)
    rendObj = ROBJ_SOLID
    color = bgColor
    children = {
      size = [ pw(100 * progress), flex() ]
      rendObj = ROBJ_SOLID
      color = fillColor
    }
  }
}


function calcSlotsCount(r, prevValue) {
  let groupSize = r.value - prevValue
  return groupSize > 1 ? 2 : 1
}

let reward = @(r, prevValue) function() {
  let slotsCount = calcSlotsCount(r, prevValue)

  let viewInfo = getRewardsViewInfo(r.rewards)?[0].__update({slots = slotsCount})
  if (viewInfo == null)
    return null
  return {
    watch = subCalendarValue
    flow = FLOW_VERTICAL
    children = [
      {
        size = const [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_SOLID
        color = 0x80000000
        halign = ALIGN_CENTER
        children = {
          size = const [flex(), SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXT
          halign = ALIGN_CENTER
          text = loc("enumerated_day", { number = r.value })
        }.__update(fontTinyAccented)
      }
      progressBar(r, prevValue)
      {
        children = [
          mkRewardPlate(viewInfo, REWARD_STYLE_MEDIUM)
          
          r.value <= subCalendarValue.get()
            ? mkRewardReceivedMark(REWARD_STYLE_MEDIUM)
            : null
        ]
      }
    ]
  }
}

let btnBlock = {
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  children = [
    @() {
      watch = subCalendarValue
      rendObj = ROBJ_TEXT
      text = loc("enumerated_day", { number = subCalendarValue.get() })
    }.__update(fontMedium)
    @() canReceiveSubCalendarReward.get()
      ? { watch = canReceiveSubCalendarReward }
      : {
          watch = [serverTime, subCalendar, subCalendarProfile, canReceiveSubCalendarReward]
          rendObj = ROBJ_TEXT
          text = secondsToTimeAbbrString(calcTimeToNextReward(
            subCalendarProfile.get()?.valueTime ?? 0, subCalendar.get()?.interval ?? 0, serverTime.get()))
        }.__update(fontTinyAccented)
    mkSpinnerHideBlock(isCalendarRewardInProgress,
      @() {
        watch = canReceiveSubCalendarReward
        children = !canReceiveSubCalendarReward.get()
          ? textButtonInactive(utf8ToUpper( loc("msgbox/btn_check_in")),
            @() openMsgBox({
              text = loc("subs/updateIn",
                { time = secondsToTimeAbbrString(calcTimeToNextReward(
                  subCalendarProfile.get()?.valueTime ?? 0, subCalendar.get()?.interval ?? 0, serverTime.get())) })
            }),
            { hotkeys = ["^J:X"] })
          : textButtonSecondary(utf8ToUpper( loc("msgbox/btn_check_in")),
            @() increase_calendar_value("subscription_daily"),
            { hotkeys = ["^J:X"] })
      })
  ]
}


function packRewardsRows(stages) {
  let slotsArr = []
  let prevValues = []
  local prevValue = 0
  local totalSlots = 0
  foreach (s in stages) {
    prevValues.append(prevValue)
    let slotsCount = calcSlotsCount(s, prevValue)
    slotsArr.append(slotsCount)
    totalSlots += slotsCount
    prevValue = s.value
  }

  local cols = ((totalSlots + 1) / 2).tointeger()
  if (cols <= 0)
    cols = 1

  let rows = []
  local cur = []
  local rem = 0

  foreach (i, r in stages) {
    let s = slotsArr[i]

    if (s > rem) {
      cur = []
      rows.append(cur)
      rem = cols
    }

    cur.append({r = r, prevValue = prevValues[i]})
    rem -= s
  }

  return rows
}


let rewardBlock = {
  flow = FLOW_VERTICAL
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = @() {
    watch = subCalendar
    flow = FLOW_VERTICAL
    gap = wndGap
    children = subCalendar.get() == null ? null
      : packRewardsRows(subCalendar.get().stages).map(@(row) @() {
        flow = FLOW_HORIZONTAL
        gap = hdpx(10)
        children = row.map(@(item) reward(item.r, item.prevValue))
      })
  }
}


let subCalendarWndScene = {
  key = WND_UID
  padding = saBordersRv
  size = flex()
  onClick = close
  children = {
  size = flex()
    children = [
      header
      rewardBlock
      btnBlock
    ]
  }
  animations = wndSwitchAnim
}

registerScene(WND_UID, subCalendarWndScene, close, isOpened)
setSceneBg(WND_UID, "ui/images/sub_calendar_bg.avif")

return @() isOpened.set(true)