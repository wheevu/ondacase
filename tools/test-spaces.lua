-- Asset/projection contract, without a graphics context. Native GPU checks are separate.
package.path=package.path..";./vendor/share/lua/5.5/?.lua;./?.lua"
love={graphics={},filesystem={read=function(path)
  local f=assert(io.open(path,"rb")); local text=f:read("*a"); f:close(); return text
end}}
local spaces=require("src.spaces")
assert(not spaces.load(),"GPU-free load should fall back without crashing")
assert(spaces.status.error:find("3D graphics unavailable",1,true))
local expected={cafe={"receipt_004","camera_log","toxicology","cup_lid","jo_statement","panel_log"},
  alley={"service_log","delivery_photo"},store={"pharmacy_footage"},apartment={"draft_email","sasha_voicemail"}}
local triangles,points=0,0
for id,ids in pairs(expected) do
  local room=assert(spaces.status.rooms[id]); assert(#room.cameras==2)
  assert(#room.vertices>0 and #room.vertices%3==0)
  triangles=triangles+#room.vertices/3
  for _,v in ipairs(room.vertices) do
    assert(#v==9,"mesh format must match shader position/UV/color")
    for _,n in ipairs(v) do assert(type(n)=="number" and n==n and math.abs(n)<100,"invalid mesh number") end
    for i=4,9 do assert(v[i]>=0 and v[i]<=1,"UV and color must be normalized") end
  end
  local count=0; for _ in pairs(room.points) do count=count+1 end
  assert(count==#ids,"unexpected point could expose an unauthored inspection")
  for view=1,2 do
    local c=spaces.camera(id,view)
    local center=spaces.project(id,view,room.cameras[view].target)
    assert(math.abs(center[1]-.5)<1e-6 and math.abs(center[2]-.5)<1e-6,"camera target must project to center")
    assert(spaces.project(id,view,c.eye)==nil,"near/behind-camera targets must not become hotspots")
    local far={}; for i=1,3 do far[i]=c.eye[i]+100*c.forward[i] end
    assert(spaces.project(id,view,far)==nil,"far-clipped geometry must not leave a hotspot")
    for _,key in ipairs(ids) do
      local p=assert(spaces.project(id,view,assert(spaces.point(id,key))))
      assert(p[1]>.03 and p[1]<.97 and p[2]>.04 and p[2]<.96,key..": hotspot clips the view")
      points=points+1
    end
  end
  local first=ids[1]
  local a=spaces.project(id,1,room.points[first]); local b=spaces.project(id,2,room.points[first])
  assert(math.abs(a[1]-b[1])+math.abs(a[2]-b[2])>.02,id..": camera views must be genuinely different")
end
assert(spaces.camera("unknown",1)==nil and spaces.camera("cafe",3)==nil)
assert(spaces.point("cafe","canonical_truth")==nil)
assert(not spaces.draw("cafe",1,0,0,640,352),"unavailable GPU must keep the list usable")
local read=love.filesystem.read
for _,broken in ipairs({'true','{"cafe":true}','not json'}) do
  love.filesystem.read=function() return broken end
  assert(not spaces.load(),"malformed assets must fall back")
  assert(spaces.camera("cafe",1)==nil and spaces.point("cafe","receipt_004")==nil,"bad assets must not leave stale scene metadata")
end
love.filesystem.read=read
print(string.format("spaces_contract=pass rooms=4 views=8 projected_hotspots=%d triangles=%d",points,triangles))
