from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile


return Computed(@() (serverConfigs.get()?.gameProfile.minBattlesToShowEvents ?? 0) <=
  (servProfile.get()?.sharedStatsByCampaign ?? {}).reduce(@(res, v) max((v?.battles ?? 0), res), 0))