require ecs
require MPlayer
require Mission
require %game.events


[es(tag=server)]
def spawn_time_count_es(evt : EventOnPlayerSpawn;
                        server_player__userId : uint64;
                        var lastSpawnTime : float&;
                        var lastBailoutTime : float&;
                        var stats__spawns : int&)
  if evt.userId == server_player__userId && lastSpawnTime < 0.0
    lastSpawnTime = float(get_total_time())
    lastBailoutTime = -1.0
    stats__spawns++
    print("[SPAWN_INFO] EventOnPlayerSpawn player (userId = int({server_player__userId}))")


[es(tag=server)]
def player_battle_time_update(act : UpdateStageInfoAct;
                              server_player__playerEid : EntityId;
                              var lastSpawnTime : float&;
                              var battleTimeTotal : float&;
                              stats__spawns : int)
  query(server_player__playerEid) <| $ [es] (m_player : MPlayer)
    if lastSpawnTime < 0.0 || stats__spawns != int(m_player.deaths)
      return
    battleTimeTotal += float(get_total_time()) - lastSpawnTime
    lastSpawnTime = -1.0
