require ecs
require jsonwriter
require DagorTime
require DagorSystem
require DagorDataBlock
require CurrentCircuit
require app
require SystemInfo


def calc_segment_add_val(ms : float;
                         ms_norm : float)
  
  return ms / ms_norm


[es(on_event=EventLevelLoaded)]
def mk_battle_perfstat_es(evt : Event)
  var hasBattlePerfstat = false
  find_query() <| $ [es(REQUIRE=battle_perfstat)] ()
    hasBattlePerfstat = hasBattlePerfstat
    return true
  if !hasBattlePerfstat
    createEntitySync("battle_perfstat")


[es(tag=gameClient, on_appear)]
def client_perf_stat_init_es(evt : Event;
                             var battle_perfstat__refTime : int64&)
  print("[BQ] Init battle perfstat")
  battle_perfstat__refTime = DagorTime::ref_time_ticks()


[es(tag=gameClient, no_order)]
def client_perf_stat_update_es(info : UpdateStageInfoAct;
                               var battle_perfstat__peakMemoryKb : int&;
                               var battle_perfstat__refTime : int64&;
                               var battle_perfstat__segment_0_5 : float&;
                               var battle_perfstat__segment_5_15 : float&;
                               var battle_perfstat__segment_15_25 : float&;
                               var battle_perfstat__segment_25_30 : float&;
                               var battle_perfstat__segment_30_35 : float&;
                               var battle_perfstat__segment_35_40 : float&;
                               var battle_perfstat__segment_40_50 : float&;
                               var battle_perfstat__segment_50_60 : float&;
                               var battle_perfstat__segment_60_80 : float&;
                               var battle_perfstat__segment_80_100 : float&;
                               var battle_perfstat__segment_100_110 : float&;
                               var battle_perfstat__segment_110_120 : float&;
                               var battle_perfstat__segment_120_130 : float&;
                               var battle_perfstat__segment_130_150 : float&;
                               var battle_perfstat__segment_150_200 : float&;
                               var battle_perfstat__segment_200_plus : float&;
                               battle_perfstat__normalizationValue : float)
  let memoryUsedKb = get_memory_allocated_kb(true)
  if battle_perfstat__peakMemoryKb < memoryUsedKb
    battle_perfstat__peakMemoryKb = memoryUsedKb

  let frameMsec = float(DagorTime::get_time_usec(battle_perfstat__refTime)) / 1000.0
  battle_perfstat__refTime = DagorTime::ref_time_ticks()
  let fps = 1000.0 / frameMsec

  if 200.0 <= fps
    battle_perfstat__segment_200_plus += calc_segment_add_val(frameMsec, battle_perfstat__normalizationValue)
  elif 150.0 <= fps
    battle_perfstat__segment_150_200 += calc_segment_add_val(frameMsec, battle_perfstat__normalizationValue)
  elif 130.0 <= fps
    battle_perfstat__segment_130_150 += calc_segment_add_val(frameMsec, battle_perfstat__normalizationValue)
  elif 120.0 <= fps
    battle_perfstat__segment_120_130 += calc_segment_add_val(frameMsec, battle_perfstat__normalizationValue)
  elif 110.0 <= fps
    battle_perfstat__segment_110_120 += calc_segment_add_val(frameMsec, battle_perfstat__normalizationValue)
  elif 100.0 <= fps
    battle_perfstat__segment_100_110 += calc_segment_add_val(frameMsec, battle_perfstat__normalizationValue)
  elif 80.0 <= fps
    battle_perfstat__segment_80_100 += calc_segment_add_val(frameMsec, battle_perfstat__normalizationValue)
  elif 60.0 <= fps
    battle_perfstat__segment_60_80 += calc_segment_add_val(frameMsec, battle_perfstat__normalizationValue)
  elif 50.0 <= fps
    battle_perfstat__segment_50_60 += calc_segment_add_val(frameMsec, battle_perfstat__normalizationValue)
  elif 40.0 <= fps
    battle_perfstat__segment_40_50 += calc_segment_add_val(frameMsec, battle_perfstat__normalizationValue)
  elif 35.0 <= fps
    battle_perfstat__segment_35_40 += calc_segment_add_val(frameMsec, battle_perfstat__normalizationValue)
  elif 30.0 <= fps
    battle_perfstat__segment_30_35 += calc_segment_add_val(frameMsec, battle_perfstat__normalizationValue)
  elif 25.0  <= fps
    battle_perfstat__segment_25_30 += calc_segment_add_val(frameMsec, battle_perfstat__normalizationValue)
  elif 15.0 <= fps
    battle_perfstat__segment_15_25 += calc_segment_add_val(frameMsec, battle_perfstat__normalizationValue)
  elif 5.0 <= fps
    battle_perfstat__segment_5_15 += calc_segment_add_val(frameMsec, battle_perfstat__normalizationValue)
  else
    battle_perfstat__segment_0_5 += calc_segment_add_val(frameMsec, battle_perfstat__normalizationValue)