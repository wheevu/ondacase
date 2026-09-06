local W = 720
local H = 720
local FOOTER_Y = 680
local ACTION_BOTTOM = 648
local function calc(win_w, win_h)
  local scale = math.min((win_w / W), (win_h / H))
  local sw = (W * scale)
  local sh = (H * scale)
  local ox = ((win_w - sw) / 2)
  local oy = ((win_h - sh) / 2)
  return {scale = scale, ox = ox, oy = oy, sw = sw, sh = sh}
end
local function to_logical(sx, sy, win_w, win_h)
  local l = calc(win_w, win_h)
  return {((sx - l.ox) / l.scale), ((sy - l.oy) / l.scale)}
end
local function in_logical_3f(x, y)
  return ((x >= 0) and (x <= W) and (y >= 0) and (y <= H))
end
return {W = W, H = H, FOOTER_Y = FOOTER_Y, ACTION_BOTTOM = ACTION_BOTTOM, calc = calc, ["to-logical"] = to_logical, ["in-logical?"] = in_logical_3f}
