from "%globalsDarg/darg_library.nut" import *
let { decorators, campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { myUserName } = require("%appGlobals/profileStates.nut")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")
let { doesLocTextExist } = require("dagor.localize")

let isDecoratorsSceneOpened = mkWatched(persist, "isDecoratorsSceneOpened", false)

let allDecorators = Computed(@() campConfigs.value?.allDecorators ?? {})
let myDecorators = Computed(@() decorators.value?.filter(@(d) d.name in allDecorators.value) ?? {})

let allTitles = Computed(@() allDecorators.value?.filter(@(dec) dec.dType == "title") ?? {})
let allFrames = Computed(@() allDecorators.value?.filter(@(dec) dec.dType == "nickFrame") ?? {})

let availTitles = Computed(@() decorators.value?.filter(@(frame) frame.name in allTitles.value) ?? {})
let availNickFrames = Computed(@() decorators.value?.filter(@(frame) frame.name in allFrames.value) ?? {})

let chosenTitle = Computed(@() availTitles.value.findvalue(@(v) v.isCurrent))
let chosenNickFrame = Computed(@() availNickFrames.value.findvalue(@(v) v.isCurrent))

let myNameWithFrame = Computed(@() frameNick(myUserName.value, chosenNickFrame.value?.name))

let function getReceiveReason(decName){
  if(decName == null)
    return null
  let locId = $"decor/{decName}/receiveReason"
  if(doesLocTextExist(locId))
    return loc(locId)
  return null
}

return {
  isDecoratorsSceneOpened
  openDecoratorsScene = @() isDecoratorsSceneOpened(true)

  chosenNickFrame
  chosenTitle
  availTitles
  availNickFrames
  allDecorators
  myDecorators
  allTitles
  allFrames
  myNameWithFrame
  getReceiveReason
}