local json = require("dkjson")
local WIDTH = 320
local HEIGHT = 176
local scene = {rooms = {}, meshes = {}, ready = false}
local function vector_3f(v)
  local and_1_ = (type(v) == "table") and (#v == 3)
  if and_1_ then
    local valid = true
    for _, n in ipairs(v) do
      if ((type(n) ~= "number") or not (math.abs(n) < 1000)) then
        valid = false
      else
      end
    end
    and_1_ = valid
  end
  return and_1_
end
local function dot(a, b)
  return ((a[1] * b[1]) + (a[2] * b[2]) + (a[3] * b[3]))
end
local function sub(a, b)
  return {(a[1] - b[1]), (a[2] - b[2]), (a[3] - b[3])}
end
local function unit(v)
  local magnitude = math.sqrt(dot(v, v))
  return {(v[1] / magnitude), (v[2] / magnitude), (v[3] / magnitude)}
end
local function cross(a, b)
  return {((a[2] * b[3]) - (a[3] * b[2])), ((a[3] * b[1]) - (a[1] * b[3])), ((a[1] * b[2]) - (a[2] * b[1]))}
end
local function camera(location, view)
  local room = scene.rooms[location]
  local c = (room and room.cameras[(view or 1)])
  if c then
    local forward = unit(sub(c.target, c.eye))
    local right = unit(cross(forward, {0, 0, 1}))
    local up = cross(right, forward)
    local tangent = math.tan(((c.fov * math.pi) / 360))
    return {eye = c.eye, name = c.name, forward = forward, right = right, up = up, tangent = tangent}
  else
    return nil
  end
end
local function project(location, view, point)
  local c = camera(location, view)
  if c then
    local delta = sub(point, c.eye)
    local depth = dot(delta, c.forward)
    if ((depth > 0.1) and (depth < 50)) then
      local x = (0.5 + (dot(delta, c.right) / (2 * depth * c.tangent * (WIDTH / HEIGHT))))
      local y = (0.5 - (dot(delta, c.up) / (2 * depth * c.tangent)))
      if ((x >= 0) and (x <= 1) and (y >= 0) and (y <= 1)) then
        return {x, y}
      else
        return nil
      end
    else
      return nil
    end
  else
    return nil
  end
end
local function release_21()
  for _, mesh in pairs(scene.meshes) do
    mesh:release()
  end
  for _, key in ipairs({"canvas", "atlas", "shader"}) do
    if scene[key] then
      scene[key].release(scene[key])
      scene[key] = nil
    else
    end
  end
  scene["meshes"] = {}
  scene["ready"] = false
  return nil
end
local function load_21()
  release_21()
  scene["rooms"] = {}
  local ok, err
  local function _8_()
    do
      local raw = assert(love.filesystem.read("assets/spaces/rooms.json"))
      local rooms = assert(json.decode(raw))
      assert((type(rooms) == "table"), "Invalid space metadata")
      for _, id in ipairs({"cafe", "alley", "store", "apartment"}) do
        local room = rooms[id]
        assert(((type(room) == "table") and (type(room.vertices) == "table") and (type(room.points) == "table") and (type(room.cameras) == "table") and (#room.cameras == 2)), "Incomplete space metadata")
        for _0, c in ipairs(room.cameras) do
          assert(((type(c) == "table") and vector_3f(c.eye) and vector_3f(c.target) and (type(c.fov) == "number") and (c.fov > 1) and (c.fov < 175)), "Invalid camera")
          local direction = sub(c.target, c.eye)
          assert((((direction[1] * direction[1]) + (direction[2] * direction[2])) > 0.001), "Vertical or zero camera direction")
        end
        for _0, p in pairs(room.points) do
          assert(vector_3f(p), "Invalid inspection point")
        end
      end
      scene["rooms"] = rooms
    end
    assert(love.graphics.newMesh, "3D graphics unavailable")
    scene["atlas"] = love.graphics.newImage("assets/spaces/atlas.png")
    scene.atlas:setFilter("nearest", "nearest")
    scene["shader"] = love.graphics.newShader("assets/spaces/room.glsl")
    scene["canvas"] = love.graphics.newCanvas(WIDTH, HEIGHT, {format = "rgba8", msaa = 0, dpiscale = 1})
    scene.canvas:setFilter("nearest", "nearest")
    for id, room in pairs(scene.rooms) do
      local mesh = love.graphics.newMesh({{"VertexPosition", "float", 3}, {"VertexTexCoord", "float", 2}, {"VertexColor", "float", 4}}, room.vertices, "triangles", "static")
      mesh:setTexture(scene.atlas)
      scene.meshes[id] = mesh
    end
    scene["ready"] = true
    return nil
  end
  ok, err = pcall(_8_)
  local _9_
  if ok then
    _9_ = nil
  else
    _9_ = tostring(err)
  end
  scene["error"] = _9_
  if not ok then
    release_21()
  else
  end
  return scene.ready
end
local function draw_21(location, view, x, y, w, h)
  if (scene.ready and scene.meshes[location]) then
    local c = camera(location, view)
    local previous = love.graphics.getCanvas()
    love.graphics.push("all")
    local ok, err
    local function _12_()
      love.graphics.setCanvas({scene.canvas, depth = true})
      love.graphics.origin()
      love.graphics.setScissor()
      love.graphics.clear(0.065, 0.075, 0.08, 1, 0, 1)
      love.graphics.setDepthMode("less", true)
      love.graphics.setMeshCullMode("none")
      love.graphics.setBlendMode("replace", "premultiplied")
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.setShader(scene.shader)
      scene.shader:send("eye", c.eye)
      scene.shader:send("rightAxis", c.right)
      scene.shader:send("upAxis", c.up)
      scene.shader:send("forwardAxis", c.forward)
      scene.shader:send("lens", {(c.tangent * (WIDTH / HEIGHT)), c.tangent})
      return love.graphics.draw(scene.meshes[location])
    end
    ok, err = pcall(_12_)
    love.graphics.setCanvas(previous)
    love.graphics.pop()
    if ok then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(scene.canvas, x, y, 0, (w / WIDTH), (h / HEIGHT))
      return true
    else
      scene["ready"] = false
      scene["error"] = tostring(err)
      return false
    end
  else
    return nil
  end
end
local function point(location, id)
  local room = scene.rooms[location]
  return (room and room.points[id])
end
return {load = load_21, draw = draw_21, project = project, camera = camera, point = point, status = scene, width = WIDTH, height = HEIGHT}
