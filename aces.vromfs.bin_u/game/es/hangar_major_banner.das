require ecs
require %appGame.wtm_events
require DagorConsole

def change_major_banner(eid : EntityId;
                        template_name : string;
                        name : string;
                        transform : float3x4)
  createEntity(template_name) <| $(var init)
    init |> set("ri_extra__name", name)
    init |> set("transform", transform)
  destroyEntity(eid)

[es(tag=hangar, REQUIRE=hangarMajorBannerTank)]
def hangar_major_banner_change_tank(evt : EventChangeHangarBanners;
                                    eid : EntityId;
                                    ri_extra__name : string;
                                    transform : float3x4)
  if evt.bannerType == "tank" && evt.newRiExName != ri_extra__name
    change_major_banner(eid, "hangar_major_banner_tank", evt.newRiExName, transform)


[es(tag=hangar, REQUIRE=hangarMajorBannerShip)]
def hangar_major_banner_change_ship(evt : EventChangeHangarBanners;
                                    eid : EntityId;
                                    ri_extra__name : string;
                                    transform : float3x4)
  if evt.bannerType == "ship" && evt.newRiExName != ri_extra__name
    change_major_banner(eid, "hangar_major_banner_ship",  evt.newRiExName, transform)

[es(tag=hangar, REQUIRE=hangarMajorBannerAir)]
def hangar_major_banner_change_air(evt : EventChangeHangarBanners;
                                   eid : EntityId;
                                   ri_extra__name : string;
                                   transform : float3x4)
  if evt.bannerType == "air" && evt.newRiExName != ri_extra__name
    change_major_banner(eid, "hangar_major_banner_air", evt.newRiExName, transform)
