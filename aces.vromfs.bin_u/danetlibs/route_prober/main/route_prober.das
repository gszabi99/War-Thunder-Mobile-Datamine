require auth
require ClientNet
require CurrentCircuit
require DagorDataBlock
require DagorMath
require DagorRandom
require DagorSystem
require DagorTime
require %danetlibs.route_prober.main.net_events
require daslib/algorithm
require ecs
require jsonwriter
require net
require OnlineStorage
require statsd

let MAIN_HOST_ROUTE_ID : uint = 0u
let PERMILLE_PER_PERCENT : int = 10
















let DEFAULT_PERCENT_RTT_SUM_THRESHOLD : int = 100
let DEFAULT_PERCENT_DIFF_SUM_MIN : int = -100

let PERCENT_DIFF_SUM_MAX : int = 100
let PERCENT_DIFF_SUM_NEUTRAL : int = 0
let PERCENT_DIFF_SUM_DECAY_FACTOR : float = 0.95 


let ECHO_HISTORY_MAX_LENGTH : int = 10
let DEFAULT_ECHO_PERIOD_SECONDS : float = 1.
let RTT_MAX : uint = uint(INT_MAX)


def get_rtt_estimation(echo_history : UInt32List) : uint
  if length(echo_history) == 0 
    return RTT_MAX
  var rttSum : uint = 0u
  for rtt in echo_history
    rttSum += rtt
  let rttAvg : uint = rttSum / uint(length(echo_history))
  var deviationSum : uint = 0u
  for rtt in echo_history
    deviationSum += max(rtt, rttAvg) - min(rtt, rttAvg)
  
  let rttMad = deviationSum / uint(length(echo_history))
  return rttAvg + rttMad

def get_circuit_param(param : string; fallback : int) : int
  return get_circuit_conf() |> datablock_get_block_by_name("route_prober") |> datablock_getInt(param, fallback)

def get_circuit_param(param : string; fallback : float) : float
  return get_circuit_conf() |> datablock_get_block_by_name("route_prober") |> datablock_getReal(param, fallback)

def get_settings(param : string; fallback : bool) : bool
  return dgs_get_settings() |> datablock_get_block_by_name("net") |> datablock_getBool(param, fallback)

def get_settings(param : string; fallback : int) : int
  return dgs_get_settings() |> datablock_get_block_by_name("net") |> datablock_getInt(param, fallback)


def is_matching_experiment_enabled(chance : float) : bool
  let session : uint64 = get_session_id()
  var seed : int = int(session)
  let r : float = _frnd(seed)
  return r < chance

def get_percent_diff(x : uint; y : uint) : int
  
  let m : int = max(int(x), int(y))
  return (m != 0) ? 100 * (int(x) - int(y)) / m : 0

def try_launch_route_prober(add_rtt : int) : void
  let routeCount : uint = get_server_route_count()
  let mainHostUrl = get_server_route_host(MAIN_HOST_ROUTE_ID)
  print("RP: Route evaluation of {int(routeCount)} routes; add rtt {add_rtt}; main host {mainHostUrl}")

  
  statsd_counter("route_prober.start", 1, "routes", "{int(routeCount)}", "host_url", mainHostUrl)

  if routeCount < 2u
    return

  createEntity("route_prober") <| $(var init : ComponentsInitializer&)
    init |> set("route_count", routeCount)
    init |> set("diff_sum_min", get_circuit_param("diff_sum_min", DEFAULT_PERCENT_DIFF_SUM_MIN))
    init |> set("rtt_sum_threshold", get_circuit_param("rtt_sum_threshold", DEFAULT_PERCENT_RTT_SUM_THRESHOLD))
    init |> set("echo_period_seconds", get_circuit_param("echo_period_seconds", DEFAULT_ECHO_PERIOD_SECONDS))
    init |> set("add_rtt", uint(add_rtt))

  for route_id in urange(routeCount)
    createEntity("route_stats") <| $(var init : ComponentsInitializer&)
      init |> set("route_id", route_id)

def get_diff_bucket_str(rtt_diff : int) : string
  let buckets = fixed_array<int>(-9000, -500, -200, -100, -75, -50, -40, -30, -20, -15, -10, -5, 0, 5, 10, 15, 20, 30, 40, 50, 75, 100, 200, 500, 9000)
  var lb = lower_bound(buckets, rtt_diff) 
  if lb == length(buckets)
    lb -= 1
  return "_{buckets[lb]}" 

def save_availability_data(count : int;
                           rttList : array<uint>;
                           availabilityList : array<bool>;
                           add_rtt : uint) : void
  jw_writer() <| $(var jw : JsonWriter)
    jw_start_obj(jw)

    jw_key_value(jw, "platform", get_platform_string_id())
    jw_key_value(jw, "session", get_session_id())
    jw_key_value(jw, "country", get_country_code())
    jw_key_value(jw, "add", add_rtt)

    jw_key(jw, "addr")
    jw_start_array(jw)
    for i in range(count)
      jw_value(jw, get_server_route_host(uint(i)))
    jw_end_array(jw)

    jw_key(jw, "rtt")
    jw_start_array(jw)
    for i in range(count)
      jw_value(jw, rttList[i])
    jw_end_array(jw)

    jw_key(jw, "avail")
    jw_start_array(jw)
    for i in range(count)
      jw_value(jw, availabilityList[i])
    jw_end_array(jw)

    jw_end_obj(jw)
    add_bigquery_record("route_availability", jw.result)
    print("RP: reporting connectivity to BQ: {jw.result}")
    

def report_route_prober_statistics(add_rtt : uint) : void
  var mainRouteRtt : uint = RTT_MAX
  var mainRouteAvailable : bool = false
  var bestProxyRtt : uint = RTT_MAX
  var bestProxyAvailable : bool = false
  var availableRoutes : uint = 0u

  query() <| $ [es(REQUIRE=routeStats)] (route_id : uint; rtt_estimation : uint; last_echoes_mask : int)
    if route_id == MAIN_HOST_ROUTE_ID
      mainRouteRtt = rtt_estimation
      mainRouteAvailable = (last_echoes_mask != 0)
    elif rtt_estimation < bestProxyRtt
      bestProxyRtt = rtt_estimation
      bestProxyAvailable = (last_echoes_mask != 0)
    if last_echoes_mask != 0
      ++availableRoutes

  let rtt_diff : int = int(mainRouteRtt) - int(bestProxyRtt)
  let percent_diff : int = get_percent_diff(mainRouteRtt, bestProxyRtt)
  print("RP: Reporting RTT diff {rtt_diff} ({percent_diff}%)")

  
  statsd_counter("route_prober.pct_diff", 1, "bucket", get_diff_bucket_str(percent_diff))
  statsd_counter("route_prober.rtt_diff", 1, "bucket", get_diff_bucket_str(rtt_diff))

  let mainHostUrl = get_server_route_host(MAIN_HOST_ROUTE_ID)
  statsd_counter("route_prober.availability", 1,
                 "main", "{mainRouteAvailable ? 1 : 0}",
                 "proxy", "{bestProxyAvailable ? 1 : 0}",
                 "host_url", mainHostUrl)

  let count = int(get_server_route_count())
  var rttList : array<uint>
  var availabilityList : array<bool>
  rttList |> resize(count)
  availabilityList |> resize(count)

  query() <| $ [es(REQUIRE=routeStats)] (route_id : uint; rtt_estimation : uint; last_echoes_mask : int)
    rttList[route_id] = rtt_estimation
    availabilityList[route_id] = (last_echoes_mask != 0)

  
  save_availability_data(count, rttList, availabilityList, add_rtt)

def report_route_availability(routeId : uint; lastEchoesMask : int) : void
  let hostUrl = get_server_route_host(routeId)
  statsd_counter(((lastEchoesMask != 0) ? "net.responsive_route" : "net.unresponsive_route"), 1, "addr", hostUrl)

def report_midgame_switch(target : uint) : void
  print("RP: Midgame switch to #{int(target)}")
  let switchToProxy : int = ((target == MAIN_HOST_ROUTE_ID) ? 0 : 1)
  statsd_counter("route_prober.switch", 1, "to", "{switchToProxy}", "host_url", get_server_route_host(MAIN_HOST_ROUTE_ID))

def report_final_best() : void
  let finalBest : uint = get_current_server_route_id()
  let mainHostUrl = get_server_route_host(MAIN_HOST_ROUTE_ID)
  let finalIsProxy : int = ((finalBest == MAIN_HOST_ROUTE_ID) ? 0 : 1)
  print("RP: Final best route is #{int(finalBest)}")
  statsd_counter("route_prober.final", 1, "route", "{finalIsProxy}", "host_url", mainHostUrl)

[es(tag=netClient, no_order)]
def try_launch_route_prober_from_settings(evt : EventOnConnectedToServer)
  if get_settings("useServerRouteEvaluation", false)
    try_launch_route_prober(get_settings("addRtt", 0))

[es(tag=netClient, no_order)]
def try_launch_route_prober_from_matching_params(evt : MatchingRoomExtraParams)
  if !get_settings("useServerRouteEvaluation", false) && is_matching_experiment_enabled(evt.routeEvaluationChance)
    let ddosSimulationEnabled : bool = is_matching_experiment_enabled(evt.ddosSimulationChance)
    try_launch_route_prober(ddosSimulationEnabled ? evt.ddosSimulationAddRtt : 0)

[es(tag=netClient, no_order, on_disappear, REQUIRE=routeProber)]
def cleanup_route_prober(evt : Event)
  report_final_best()

[es(no_order, REQUIRE=routeProber)]
def route_prober_timers(info : UpdateStageInfoAct;
                        route_count : uint;
                        echo_period_seconds : float;
                        evaluation_period_seconds : float;
                        var next_evaluation : float&;
                        var next_echo_broadcast : float&)
  next_echo_broadcast -= info.dt
  if next_echo_broadcast <= 0.f
    next_echo_broadcast = echo_period_seconds
    
    for route_id in urange(route_count)
      send_echo_msg(route_id)

  next_evaluation -= info.dt
  if next_evaluation <= 0.f
    next_evaluation = evaluation_period_seconds
    broadcastEvent(ChangeServerRoute(currentIsUnresponsive = false))

[es(no_order, REQUIRE=routeStats)]
def receive_echo_response(response : NetEchoReponse; route_id : uint; var echo_history : UInt32List&; var last_echoes_mask : int&)
  if response.routeId != route_id
    return

  echo_history |> push(response.rttOrTimeout)

  let success = (response.result == int(EchoResponseResult.SUCCESS))
  last_echoes_mask = ((last_echoes_mask << 1) | (success ? 1 : 0)) & ~(1 << ECHO_HISTORY_MAX_LENGTH)

  if length(echo_history) > ECHO_HISTORY_MAX_LENGTH
    erase(echo_history, 0)
  elif length(echo_history) == ECHO_HISTORY_MAX_LENGTH 
    report_route_availability(route_id, last_echoes_mask)

[es(tag=netClient, no_order)]
def evaluate_server_route(evt : ChangeServerRoute)
  let hasRouteProber = find_query() <| $ [es(REQUIRE=routeProber)] (diff_sum_min : int;
                                                                    rtt_sum_threshold : int;
                                                                    add_rtt : uint;
                                                                    echo_period_seconds : float;
                                                                    var statistics_reported : bool&;
                                                                    var next_evaluation : float&)
    let currentRoute : uint = get_current_server_route_id()
    var currentRttEstimation : uint = RTT_MAX
    var minEchoHistory : int = ECHO_HISTORY_MAX_LENGTH

    query() <| $ [es(REQUIRE=routeStats)] (route_id : uint;
                                           echo_history : UInt32List;
                                           var rtt_estimation : uint&)
      rtt_estimation = get_rtt_estimation(echo_history)
      if route_id == MAIN_HOST_ROUTE_ID
        rtt_estimation = min(rtt_estimation + add_rtt, RTT_MAX)

      if route_id == currentRoute && !evt.currentIsUnresponsive 
        currentRttEstimation = rtt_estimation
      minEchoHistory = min(minEchoHistory, length(echo_history))

    let forceChange : bool = evt.currentIsUnresponsive
    var bestRoute : uint = currentRoute
    var bestRttEstimation : uint = currentRttEstimation
    var maxDiffSum : int = diff_sum_min

    if !forceChange && minEchoHistory < ECHO_HISTORY_MAX_LENGTH
      next_evaluation = float(ECHO_HISTORY_MAX_LENGTH - minEchoHistory) * echo_period_seconds
      print("RP: not enough echo packets {minEchoHistory} / {ECHO_HISTORY_MAX_LENGTH}; trying again in {next_evaluation}s")
      return true

    query() <| $ [es(REQUIRE=routeStats)] (route_id : uint;
                                           rtt_estimation : uint;
                                           var rtt_diff_sum : int&)
      if route_id == currentRoute
        return
      let rttDiff : int = get_percent_diff(currentRttEstimation, rtt_estimation)
      
      
      
      
      
      
      rtt_diff_sum = int(float(rtt_diff_sum) * PERCENT_DIFF_SUM_DECAY_FACTOR)
      rtt_diff_sum = clamp(rtt_diff_sum + rttDiff, diff_sum_min, PERCENT_DIFF_SUM_MAX)
      maxDiffSum = max(maxDiffSum, rtt_diff_sum)
      if (forceChange && rtt_estimation < bestRttEstimation) || (!forceChange && rtt_diff_sum >= rtt_sum_threshold)
        bestRoute = route_id
        bestRttEstimation = rtt_estimation

    print("RP: Current server route #{int(currentRoute)} available={!evt.currentIsUnresponsive} "
        + "rtt estimation={int(currentRttEstimation)} best route #{int(bestRoute)} "
        + "rtt estimation={int(bestRttEstimation)} max diff sum={maxDiffSum}")

    if bestRoute != currentRoute
      report_midgame_switch(bestRoute)
      switch_server_route(bestRoute)
      query() <| $ [es(REQUIRE=routeStats)] (var rtt_diff_sum : int&)
        rtt_diff_sum = PERCENT_DIFF_SUM_NEUTRAL

    
    if !statistics_reported && !forceChange
      report_route_prober_statistics(add_rtt)
      statistics_reported = true

    return true

  if !hasRouteProber && evt.currentIsUnresponsive 
    let serverRouteCount : uint = get_server_route_count()
    if serverRouteCount > 1u
      switch_server_route((get_current_server_route_id() + 1u) % serverRouteCount)
