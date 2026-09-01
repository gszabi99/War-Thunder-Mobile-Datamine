from "%globalsDarg/darg_library.nut" import *
from "app" import exitGame
from "dagor.system" import dgs_get_settings
from "dagor.workcycle" import resetTimeout




let quitAfterTime = dgs_get_settings()?.debug.quitAfterTimeInMenu ?? 0.0
if (quitAfterTime > 0)
  resetTimeout(quitAfterTime, @() exitGame())
