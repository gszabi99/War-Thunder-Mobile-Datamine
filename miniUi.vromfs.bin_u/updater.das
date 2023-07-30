options no_global_variables = false

require DagorMath
require DagorTime
require DagorShaders
require DagorDriver3D
require DagorTexture3D
require DagorStdGuiRender

require AndroidUpdater

require math
require strings


let
  TARGET_SCREEN_WIDTH_TEXT = 1920.


var
  bkgTid  = BAD_TEXTUREID
  rot0Tid = BAD_TEXTUREID
  bkgAspectRatio = 0.


def E3DCOLOR(r,g,b,a:int)
  return E3DCOLOR(uint4(uint(r), uint(g), uint(b), uint(a)))


def StdGuiRender_set_color(color)
  let copy = color
  StdGuiRender_set_color(copy)


def StdGuiRender_render_rect(x, y, w, h: int)
  StdGuiRender_render_rect(float(x), float(y), float(w), float(h))


def StdGuiRender_render_frame(l, t, r, b, thickness: int)
  StdGuiRender_render_frame(float(l), float(t), float(r), float(b), float(thickness))


def StdGuiRender_render_box(l, t, r, b: int)
  StdGuiRender_render_box(float(l), float(t), float(r), float(b))


def StdGuiRender_goto_xy(x, y: int)
  StdGuiRender_goto_xy(float(x), float(y))


def StdGuiRender_draw_str(s: string)
  StdGuiRender_draw_str(s, -1 /* len */)


def StdGuiRender_draw_str_scaled(scale: float; s: string)
  StdGuiRender_draw_str_scaled(scale, s, -1 /* len */)


[export]
def init()
  print("[CPTC] das: INIT")

  bkgTid = add_managed_texture("updater_bkg.jpg?p1", null)
  let bkgTex = acquire_managed_tex(bkgTid)

  using() <| $(var info: TextureInfo#)
    *bkgTex |> getinfo(info, 0 /* level */)

    bkgAspectRatio = int(info.h) != 0 ? float(info.w) / float(info.h) : 1.

  rot0Tid = add_managed_texture("loadinganim.ddsx", null)
  acquire_managed_tex(rot0Tid)


[export]
def release()
  print("[CPTC] das: RELEASE")

  if bkgTid != BAD_TEXTUREID
    release_managed_tex(bkgTid)
    bkgTid = BAD_TEXTUREID

  if rot0Tid != BAD_TEXTUREID
    release_managed_tex(rot0Tid)
    rot0Tid = BAD_TEXTUREID


[export]
def update(scr_w, scr_h: int): bool
  let base_y = scr_h * 4 / 5
  let x_left = 100
  let x_right = scr_w - 100
  let x_width = x_right - x_left - 2
  let font_scale = float(scr_w) / TARGET_SCREEN_WIDTH_TEXT
  let bar_ht = int(10. * font_scale)
  let rot_sz = int(40. * font_scale)

  let stateText       = embeddedupdater_get_state_text()
  let errorText       = embeddedupdater_get_error_text()
  let failTitle       = embeddedupdater_get_fail_text()
  let waitAppUpdate   = embeddedupdater_get_wait_app_update()
  let progressPct     = embeddedupdater_get_progress_percent()
  let dlSpeed         = embeddedupdater_get_download_speed()
  let etaSec          = embeddedupdater_get_eta()

  d3d_clearview(CLEAR_TARGET, E3DCOLOR(0, 0, 0, 255), 0., 0u)

  StdGuiRender_start_render()

  StdGuiRender_set_texture(bkgTid)
  StdGuiRender_set_color(E3DCOLOR(255, 255, 255, 255))

  let bkgW = float(scr_h) * bkgAspectRatio
  let bkgX = 0.5 * (float(scr_w) - bkgW)
  StdGuiRender_render_rect(int(bkgX), 0, int(bkgX + bkgW), scr_h)

  StdGuiRender_set_color(E3DCOLOR(uint4(0u, 0u, 0u, 64u)))
  StdGuiRender_set_texture(BAD_TEXTUREID)
  StdGuiRender_render_rect(0, base_y - int(90. * font_scale), scr_w, base_y+bar_ht+20)

  if !waitAppUpdate
    StdGuiRender_set_color(E3DCOLOR(255, 255, 255, 255))
    GuiVertex_setRotViewTm(float(x_right-rot_sz/2), float(base_y-10-rot_sz/2), float(get_time_msec()) * PI/3000., 0., false /* add */)
    StdGuiRender_set_texture(rot0Tid)
    StdGuiRender_render_rect(x_right-rot_sz, base_y-10-rot_sz, x_right, base_y-10)
    GuiVertex_resetViewTm()

  StdGuiRender_set_texture(BAD_TEXTUREID)
  StdGuiRender_set_color(E3DCOLOR(0, 0, 0, 255))
  StdGuiRender_render_frame(x_left, base_y, x_right, base_y+bar_ht, 1)
  StdGuiRender_set_color(E3DCOLOR(255, 255, 255, 255))
  StdGuiRender_render_box(x_left+1, base_y+1, x_left+1+x_width*progressPct/100, base_y+bar_ht-1)

  StdGuiRender_set_font(0, 0 /* font_kern */, 0 /* mono_w */)
  StdGuiRender_set_color(E3DCOLOR(255, 255, 255, 255))
  StdGuiRender_goto_xy(100, base_y - int(40. * font_scale))

  let text = build_string() <| $(text)
    text |> write(stateText)

    if progressPct != 0 && !waitAppUpdate
      text |> write("  {progressPct}%")

    if dlSpeed != 0
      var meas = 0.lf
      var desc = "B/s"
      meas = double(dlSpeed) / 1073741824.0lf //GB
      if meas > 0.5lf
        desc = "GB/s"
      else
        meas = double(dlSpeed) / 1048576.0lf //MB
        if meas > 0.5lf
          desc = "MB/s"
        else
          meas = double(dlSpeed) / 1024.0lf //KB
          desc = meas > 0.5lf ? "KB/s" : "B/s"

      text |> write(", {format("%.1lf", meas)}{desc}")

    if etaSec != 0
      if etaSec < 0 || etaSec > 30*86400
        text |> write(",  ETA: ∞")
      else
        var times     = int4() //day, hour, min, sec
        let timeSec   = int3(86400, 3600, 60)
        let timeNames = [[auto[] "d"; "h"; "m"; "s"]]
        var seconds   = etaSec

        for i in range(3)
          times[i] = seconds / timeSec[i]
          seconds -= times[i] * timeSec[i]
        times[3] = seconds

        for i in range(3)
          if times[i] != 0
            if times[i + 1] != 0
              text |> write(",  ETA: {times[i]}{timeNames[i]}:{times[i + 1]}{timeNames[i + 1]}")
            else
              text |> write(",  ETA: {times[i]}{timeNames[i]}")
            break
    if length(errorText) != 0
      text |> write(":  {errorText}")

  StdGuiRender_set_draw_str_attr(FontFxType FFT_SHADOW, 0, 0, E3DCOLOR(0, 0, 0, 255), 16)
  StdGuiRender_draw_str_scaled(font_scale, text)

  if waitAppUpdate
    StdGuiRender_set_color(E3DCOLOR(255, 25, 25, 255))
    StdGuiRender_goto_xy(scr_w/2-int(StdGuiRender_get_str_bbox(failTitle).width.x)/2, scr_h/2)
    StdGuiRender_draw_str_scaled(font_scale, failTitle)

  StdGuiRender_reset_draw_str_attr()
  StdGuiRender_flush_data()
  StdGuiRender_end_render()

  // Return 'true' in case the Updater is done and
  // should close the progress screen
  return true
