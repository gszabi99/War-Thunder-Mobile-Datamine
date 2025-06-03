require ecs
require net
require DagorSystem
require MPlayer
require %game.events

def find_server_player_eid(player_eid)
  var resultEid = INVALID_ENTITY_ID
  find_query() <| $ [es] (eid : EntityId; server_player__playerEid : EntityId)
    if server_player__playerEid == player_eid
      resultEid = eid
      return true
    return false
  return resultEid

[es(tag=server, on_appear, track=server_player__connId)]
def init_server_player(evt : Event;
                       server_player__playerId : int;
                       server_player__connId : int;
                       server_player__userId : uint64;
                       var replication : NetObject)
  
  
  print("[ServerPlayer]: Player with id {server_player__playerId} ({server_player__userId}) controls replication for {server_player__connId} connection.")
  replication |> net_object_setControlledBy(server_player__connId)

[es(tag=server)]
def create_server_player_es(evt : EventOnPlayerConnected;
                            eid aka player_eid : EntityId;
                            m_player : MPlayer;
                            player_id : int;
                            connId : int;
                            server_player__template : string)
  if evt.userId != m_player.userId
    return

  var serverPlayerEid = find_server_player_eid(player_eid)
  if !!serverPlayerEid
    query(serverPlayerEid) <| $ [es] (var server_player__connId : int&; server_player__userId : uint64)
      if server_player__userId == m_player.userId
        print("[ServerPlayer]: Restore the server player with id {player_id} for user {m_player.userId} and connection id {connId}")
        server_player__connId = connId
        return
      print("[ServerPlayer]: Server player with id {player_id} not same with userId {m_player.userId} and need recreating")
      destroyEntity(serverPlayerEid)
      serverPlayerEid = INVALID_ENTITY_ID
    if serverPlayerEid != INVALID_ENTITY_ID
      return

  if connId < 0
    print("[ServerPlayer]: Cannot create server player with id {player_id} for user {m_player.userId} due to connection is not created")
    return

  print("[ServerPlayer]: Create a server player with id {player_id} for user {m_player.userId} and connection id {connId}")

  createEntitySync(server_player__template) <| $(var init)
    init |> set("server_player__playerEid", player_eid)
    init |> set("server_player__playerId", player_id)
    init |> set("server_player__connId", connId)
    init |> set("server_player__userId", m_player.userId)

[es(tag=server, on_disappear)]
def destroy_server_player_es(evt : Event; eid aka player_eid : EntityId; player_id : int; m_player : MPlayer)
  print("[ServerPlayer]: Destroy the server player with id {player_id} for user {m_player.userId}")
  player_eid |> find_server_player_eid() |> destroyEntity()

[es(tag=server, track=connId)]
def server_player_on_connection_close_es(evt : Event;
                                         eid aka player_eid : EntityId;
                                         player_id : int;
                                         connId : int;
                                         m_player : MPlayer)
  if connId < 0
    print("[ServerPlayer]: The server player with id {player_id} for user {m_player.userId} has been disconnected")
    player_eid |> find_server_player_eid() |> query() <| $ [es] (var server_player__connId : int&)
      server_player__connId = INVALID_CONNECTION_ID

[es(tag=netClient, on_appear)]
def init_server_player_on_client_es(evt : Event;
                                    eid aka server_player_eid : EntityId;
                                    server_player__localTemplate : string;
                                    server_player__playerId : int;
                                    var replication : NetObject;
                                    var server_player__playerEid : EntityId&)
  let isOk = find_query() <| $ [es] (eid aka player_eid : EntityId; player_id : int; m_player : MPlayer)
    if player_id == server_player__playerId
      server_player__playerEid = player_eid
      print("[ServerPlayer]: The server player with id {player_id} for user {m_player.userId} has been created on the client")

      let localPlayer = player_get_local()
      if localPlayer != null && localPlayer.userId == m_player.userId
        
        let SERVER_CONN_ID = 0
        replication |> net_object_setControlledBy(SERVER_CONN_ID)

        addSubTemplate(server_player_eid, server_player__localTemplate)

      return true
    return false

  if !isOk
    print("[ServerPlayer]: The server player with id {server_player__playerId} is not found on the client!")
