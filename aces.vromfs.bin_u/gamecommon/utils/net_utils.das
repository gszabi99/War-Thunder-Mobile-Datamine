module net_utils shared

require ecs
require net
require WTNetUnit
require math.base

def get_target_entity_team(eid : EntityId)
  return get_int(eid, "team") ?? -1 

def get_target_entity_squad(eid : EntityId)
  return get_Eid(eid, "squad_member__squad") ?? INVALID_ENTITY_ID

def private get_controlled_by_connection(var out : array<IConnection?>&; eid : EntityId)
  query(eid) <| $ [es] (replication : NetObject)
    out |> push(replication |> net_object_getControlledBy() |> get_client_connection())

def target_entity_conn(target_entity : EntityId) : array<IConnection?>
  var recipients : array<IConnection?>
  get_controlled_by_connection(recipients, target_entity)
  return <- recipients

def is_out_of_range(pos : float3; max_range : float; player_eid, possessed : EntityId)
  if max_range > 0.

    
    
    let lookingEid = get_Eid(player_eid, "possessed") ?? ecs::INVALID_ENTITY_ID;
    let playerTm = get_TMatrix(lookingEid, "transform")
    if playerTm != null
      return length_sq(pos - (*playerTm)[3]) > square(max_range)
    if !doesEntityExist(possessed)
      return true
    let possessedTm = possessed |> get_TMatrix("transform")
    if possessedTm == null || length_sq(pos - (*possessedTm)[3]) > square(max_range)
      return true
  return false

def enum_connections_near_pos(pos : float3;
                              max_range : float = 25.;
                              only_for_team_id = -1; 
                              only_for_squad_eid = INVALID_ENTITY_ID;
                              except_possessed = INVALID_ENTITY_ID) : array<IConnection?>
  var recipients : array<IConnection?>
  query() <| $ [es(REQUIRE=player)] (eid : EntityId; possessed : EntityId; connid : int; disconnected : bool = false)
    if !!except_possessed && possessed == except_possessed
      return
    if disconnected
      return
    if is_out_of_range(pos, max_range, eid, possessed)
      return
    if only_for_team_id != -1  && get_target_entity_team(possessed) != only_for_team_id
      return
    if !!only_for_squad_eid && get_target_entity_squad(possessed) != only_for_squad_eid
      return
    recipients |> push(connid |> get_client_connection())
  return <- recipients