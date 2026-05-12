
from "%scripts/dagui_library.nut" import *
from "math" import round
from "string" import format
from "console" import register_command
from "%sqstd/platform.nut" import is_pc
from "%sqstd/math.nut" import round_by_value
from "%globalScripts/systemConfig.nut" import getSystemConfigOption, setSystemConfigOption
from "%appGlobals/safeArea.nut" import debugSafeAreaW, SAFEAREA_DEFAULT, SAFEAREA_W_DYNAMICISLAND, SAFEAREA_W_PIXEL9
import "%scripts/debugTools/applyRendererSettingsChange.nut" as applyRendererSettingsChange

let IS_ENABLED = is_pc

let MAX_RES_SIDE = 4000
let SWDI = SAFEAREA_W_DYNAMICISLAND
let SWG9 = SAFEAREA_W_PIXEL9

let needCycleShortListByAR = mkWatched(persist, "needCycleShortListByAR", true)

let androidPresetsH = [ 688, 1080 ]

let androidScreens = [
  [ 1600,  720, null, { Android = "" } ],
  [ 2316,  904, null, { Samsung = "Galaxy Z Fold5 outer" } ],
  [ 1440, 1080, null, { Android = "" } ],
  [ 1920, 1080, null, { Android = "" } ],
  [ 2340, 1080, null, { Android = "" } ],
  [ 2400, 1080, null, { Android = "" } ],
  [ 2424, 1080, SWG9, { Google = "Pixel 10" } ],
  [ 2484, 1116, null, { Oppo = "Find N3 foldable outer" } ],
  [ 1920, 1200, null, { Android = "Tablet" } ],
  [ 2000, 1200, null, { Android = "Tablet" } ],
  [ 2712, 1220, null, { Android = "" } ],
  [ 2760, 1256, null, { Huawei = "Mate XT Ultimate outer" } ],
  [ 2844, 1260, null, { Huawei = "Pura 70 Ultra" } ],
  [ 2856, 1280, SWG9, { Google = "Pixel 10 Pro" } ],
  [ 2832, 1316, null, { Huawei = "Mate 70 Pro" } ],
  [ 2992, 1344, SWG9, { Google = "Pixel 9 Pro Fold outer" } ],
  [ 3120, 1440, null, { Android = "" } ],
  [ 2560, 1600, null, { Android = "Tablet" } ],
  [ 3840, 1644, null, { Sony = "Xperia 1" } ],
  [ 2800, 1752, null, { Samsung = "Galaxy Tab S" } ],
  [ 2960, 1848, null, { Samsung = "Galaxy Tab S10 Ultra" } ],
  [ 3000, 1920, null, { Android = "Tablet" } ],
  [ 2184, 1968, null, { Samsung = "Galaxy Z Fold7 inner" } ],
  [ 2800, 2000, null, { Android = "Tablet" } ],
  [ 3048, 2032, null, { Huawei = "Mate XT Ultimate inner" } ],
  [ 2152, 2076, SWG9, { Google = "Pixel 10 Pro Fold inner" } ],
]

let appleScreens = [
  [ 1136,  640, null, { iPhone = "SE (1 Gen)", iPod = "touch (7 Gen)" } ],
  [ 1334,  750, null, { iPhone = "8, 7, 6s, 6, SE (2 Gen), SE (3 Gen)" } ],
  [ 1792,  828, null, { iPhone = "11, XR" } ],
  [ 1920, 1080, null, { iPhone = "8 Plus, 7 Plus, 6s Plus, 6 Plus" } ],
  [ 2340, 1080, null, { iPhone = "13 mini, 12 mini" } ],
  [ 2436, 1125, null, { iPhone = "11 Pro, XS, X" } ],
  [ 2532, 1170, null, { iPhone = "14, 13 Pro, 13, 12 Pro, 12" } ],
  [ 2556, 1179, SWDI, { iPhone = "16, 15 Pro, 15, 14 Pro" } ],
  [ 2622, 1206, SWDI, { iPhone = "17 Pro, 17, 16 Pro" } ],
  [ 2688, 1242, null, { iPhone = "11 Pro Max, XS Max" } ],
  [ 2266, 1488, null, { iPad = "mini (6-7 Gen)" } ],
  [ 2048, 1536, null, { iPad = "(5-6 Gen), Pro 9.7\", Air 2, mini 5, mini 4" } ],
  [ 2160, 1620, null, { iPad = "(7-9 Gen)" } ],
  [ 2360, 1640, null, { iPad = "(10 Gen), Air (4-5 Gen), Air 11\" (M2)" } ],
  [ 2224, 1668, null, { iPad = "Pro 10.5\", Air (3 Gen)" } ],
  [ 2388, 1668, null, { iPad = "Pro 11\" (1-5 Gen)" } ],
  [ 2732, 2048, null, { iPad = "Pro 13\" (M4), Air 13\" (M2), Pro 12.9\" (1-6 Gen)" } ],
  [ 2778, 1284, null, { iPhone = "14 Plus, 13 Pro Max, 12 Pro Max" } ],
  [ 2796, 1290, SWDI, { iPhone = "16 Plus, 15 Pro Max, 15 Plus, 14 Pro Max" } ],
  [ 2868, 1320, SWDI, { iPhone = "17 Pro Max, 16 Pro Max" } ],
]

let getCurResolution = @() getSystemConfigOption("video/resolution")

function getAspectRatio(w, h, needRounded) {
  let ar = 1.0 * w / h
  return needRounded ? round_by_value(ar, 0.1) : ar
}

function mkResolutionInfo(resCfg) {
  let w = resCfg[0]
  let h = resCfg[1]
  assert(w >= h, "Need exchange W and H")
  let saW = resCfg[2]
  let devices = resCfg[3].map(@(m) [ m ])
  return {
    w
    h
    saW
    devices
    ar = getAspectRatio(w, h, false)
    arRounded = getAspectRatio(w, h, true)
    mp = round_by_value(w * h / 1000000.0, 0.1)
  }
}

function mkAndroidResolutions(resInfoList, presetsH, needFull) {
  let res = []
  foreach (v in resInfoList)
    foreach (ph in presetsH) {
      let realW = v.w
      let realH = v.h
      let h = min(ph, realH)
      let w = round(v.ar * h).tointeger()
      let resInfo = "".concat($"({realW}x{realH}", !needFull ? "" : $" @ {ph}p", ")")
      let devices = v.devices.map(@(models) models.map(@(m) " ".join([ m, resInfo ], true)))
      res.append(v.__merge({ w, h, devices }))
      if (!needFull)
        break
    }
  return res
}

let findByResolution = @(list, v) list.findvalue(@(c) c.w == v.w && c.h == v.h && c.saW == v.saW)
let findByArRounded  = @(list, v) list.findvalue(@(c) c.arRounded == v.arRounded)

let mkReduceResolutionsFunc = @(findFunc) function reduceResolutions(res, v) {
  let dest = findFunc(res, v)
  if (dest == null)
    res.append(v)
  else {
    foreach (d, models in v.devices) {
      dest.devices[d] <- dest.devices?[d] ?? []
      foreach (m in models)
        if (!dest.devices[d].contains(m))
          dest.devices[d].append(m)
    }
  }
  return res
}

function mkDesc(cfg, needFull) {
  let { devices, saW, ar, arRounded, mp } = cfg
  let arStr = needFull ? format("%.2f", ar) : format("%.1f", arRounded)
  let modelsList = devices.topairs().map(@(v) " ".concat(v[0], ", ".join(v[1])))
  let baseDesc = needFull ? $"SafeAreaW {saW ?? SAFEAREA_DEFAULT}, AR {arStr}, {mp}MP" : $"AR {arStr}"
  return " // ".join([ baseDesc, "; ".join(modelsList) ])
}

let sortResolutions = @(a, b) a.ar <=> b.ar || a.mp <=> b.mp || a.h <=> b.h || a.w <=> b.w || a.saW <=> b.saW

function parseResolution(resolutionStr) {
  let sizeArr = resolutionStr.split("x").apply(@(v) v.strip().tointeger())
  return { w = sizeArr[0], h = sizeArr[1] }
}

let mkScreenResolutionsInfoList = @(needFull) appleScreens.map(mkResolutionInfo)
  .extend(mkAndroidResolutions(androidScreens.map(mkResolutionInfo), androidPresetsH, needFull))
  .map(@(v) v.__merge(needFull ? {} : { saW = SAFEAREA_DEFAULT }))
  .sort(sortResolutions)
  .reduce(mkReduceResolutionsFunc(needFull ? findByResolution : findByArRounded), [])
  .map(@(v) v.__merge({ resolution = $"{v.w} x {v.h}", desc = mkDesc(v, needFull) }))

let screenResolutionsListFull = mkScreenResolutionsInfoList(true)
let screenResolutionsListShort = mkScreenResolutionsInfoList(false)

function setResolution(curResolution, resCfg, prefix = "") {
  if (!IS_ENABLED)
    return
  let { resolution, saW, desc } = resCfg
  debugSafeAreaW.set(saW)
  let cb = @() console_print(" ".join([ prefix, $"Set resolution: \"{resolution}\" // {desc}" ], true))
  if (resolution == curResolution)
    return cb()
  setSystemConfigOption("video/resolution", resolution)
  applyRendererSettingsChange(true, cb)
}

function cmdChange(w, h) {
  if (type(w) != "integer" || w <= 0 || w > MAX_RES_SIDE || type(h) != "integer" || h <= 0 || h > MAX_RES_SIDE) {
    console_print($"Params W and H must be integers, from 1 to {MAX_RES_SIDE}")
    return
  }
  let curResolution = getCurResolution()
  let resCfg = screenResolutionsListFull.findvalue(@(v) v.w == w && v.h == h)
    ?? { resolution = $"{w} x {h}", saW = null, desc = "Unknown device" }
  setResolution(curResolution, resCfg)
}

function cmdChangeToPrevNext(isNext) {
  let list = needCycleShortListByAR.get() ? screenResolutionsListShort : screenResolutionsListFull
  let listLen = list.len()
  let curResolution = getCurResolution()
  let { w, h } = parseResolution(curResolution)
  let arRounded = getAspectRatio(w, h, true)
  let curIdx = list.findindex(@(v) v.w == w && v.h == h)
    ?? list.findindex(@(v) v.arRounded == arRounded)
    ?? (listLen + (isNext ? -1 : 1))
  let newIdx = (listLen + curIdx + (isNext ? 1 : -1)) % listLen
  let resCfg = list[newIdx]
  setResolution(curResolution, resCfg, $"[{newIdx + 1}/{listLen}]")
}

function cmdChangeByNum(num) {
  let listLen = screenResolutionsListFull.len()
  if (type(num) != "integer" || num <= 0 || num > listLen) {
    console_print($"Param NUM must be integer, from 1 to {listLen}")
    return
  }
  let curResolution = getCurResolution()
  let resCfg = screenResolutionsListFull[num - 1]
  setResolution(curResolution, resCfg, $"[{num}]")
}

function cmdPrintList() {
  foreach (i, v  in screenResolutionsListFull)
    console_print($"[{i+1}] \"{v.resolution}\" // {v.desc}")
  console_print(" ")
  console_print("To set resolution by list number, use command: ui.debug.window_resolution.change_by_num")
}

function cmdUseFullListForPrevAndNext() {
  let needByAR = !needCycleShortListByAR.get()
  needCycleShortListByAR.set(needByAR)
  let listName = needByAR ? "SHORT (stacked by aspect ratios)" : "FULL (all resolutions)"
  console_print($"Command ui.debug.window_resolution.change_to_prev/next now uses list: {listName}")
}

if (IS_ENABLED) {
  register_command(cmdChange, "ui.debug.window_resolution.change")
  register_command(@() cmdChangeToPrevNext(true),  "ui.debug.window_resolution.change_to_next")
  register_command(@() cmdChangeToPrevNext(false), "ui.debug.window_resolution.change_to_prev")
  register_command(cmdChangeByNum, "ui.debug.window_resolution.change_by_num")
  register_command(cmdPrintList, "ui.debug.window_resolution.print_list")
  register_command(cmdUseFullListForPrevAndNext, "ui.debug.window_resolution.use_full_list_for_prev_and_next")
}
