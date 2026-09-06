"""Build the four original real-time inspection spaces with Blender 5.2."""
import json
import math
from pathlib import Path
import random

import bpy
from mathutils import Vector

OUT = Path(__file__).resolve().parents[1] / "assets/spaces"
assert OUT.is_dir()
random.seed(1922)
bpy.context.preferences.filepaths.save_version = 0
palette = [
    (.46,.42,.33), (.34,.25,.20), (.38,.26,.16), (.47,.49,.43),
    (.23,.30,.32), (.38,.19,.16), (.30,.35,.25), (.085,.11,.12),
    (.72,.69,.54), (.67,.47,.24), (.25,.27,.25), (.15,.22,.23),
    (.44,.36,.27), (.40,.45,.39), (.29,.25,.25), (.24,.36,.31),
]
atlas = bpy.data.images.new("Spaces / 128px atlas",128,128)
pixels=[]
for y in range(128):
    for x in range(128):
        tile=x//32+(y//32)*4
        r,g,b=palette[tile]
        n=random.choice((-.035,-.018,0,.018,.035))
        if tile in (1,10) and (y%8==0 or (x+(4 if y//8%2 else 0))%16==0): n-=.08
        if tile in (2,12) and x%7==0: n-=.09
        if tile==3 and (x%16==0 or y%16==0): n-=.16
        if tile==8 and 4<x%32<28 and y%5==0: n-=.19
        if tile==7 and 4<x%32<28 and y%6==0: n+=.06
        pixels.extend([max(0,min(1,c+n)) for c in (r,g,b)]+[1])
atlas.pixels[:]=pixels
atlas.filepath_raw=str(OUT/"atlas.png"); atlas.file_format="PNG"
atlas.save(); atlas.pack(); atlas.filepath="//atlas.png"
materials=[]
for tile in range(16):
    mat=bpy.data.materials.new(f"Atlas / {tile:02d}")
    mat.diffuse_color=(*palette[tile],1); mat.use_nodes=True
    shader=mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Roughness"].default_value=1
    tex=mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image=atlas; tex.interpolation="Closest"
    mat.node_tree.links.new(tex.outputs["Color"],shader.inputs["Base Color"])
    materials.append(mat)


def surface(obj,tile):
    obj.data.materials.append(materials[tile]); obj["tile"]=tile
    if not obj.data.uv_layers: obj.data.uv_layers.new()
    uv=obj.data.uv_layers.active.data
    for face in obj.data.polygons:
        count=len(face.loop_indices)
        for j,index in enumerate(face.loop_indices):
            u,v=([(0,0),(1,0),(1,1),(0,1)][j] if count==4 else
                 (.5+.48*math.cos(j*math.tau/count),.5+.48*math.sin(j*math.tau/count)))
            uv[index].uv=((tile%4*32+1+u*30)/128,(tile//4*32+1+v*30)/128)
    return obj


def box(name,position,size,tile):
    bpy.ops.mesh.primitive_cube_add(size=1,location=position)
    obj=bpy.context.object; obj.name=name; obj.scale=size
    return surface(obj,tile)


def cylinder(name,position,radius,depth,tile,rotation=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=radius,depth=depth,location=position)
    obj=bpy.context.object; obj.name=name
    if rotation: obj.rotation_euler=rotation
    return surface(obj,tile)


def table(name,x,y,w=1.5,d=1.0,tile=2,z=.85):
    box(name+" / top",(x,y,z),(w,d,.12),tile)
    for dx in (-w*.4,w*.4):
        for dy in (-d*.4,d*.4): box(name+" / leg",(x+dx,y+dy,z/2),(.09,.09,z),7)


def chair(x,y,tile=5):
    box("Chair seat",(x,y,.48),(.58,.58,.12),tile)
    box("Chair back",(x,y+.24,.89),(.58,.12,.75),tile)
    for dx in (-.21,.21):
        for dy in (-.21,.21): box("Chair leg",(x+dx,y+dy,.25),(.07,.07,.5),7)


def room(wall=0,floor=2,ceiling=True):
    for x in range(-4,4):
        for y in range(-3,4): box("Floor tile",(x+.5,y+.5,-.08),(.99,.99,.14),floor)
    box("Back wall",(0,4,1.7),(8,.18,3.4),wall)
    box("Left wall",(-4,.5,1.7),(.18,7,3.4),wall)
    box("Right wall",(4,.5,1.7),(.18,7,3.4),wall)
    if ceiling: box("Ceiling",(0,.5,3.46),(8,7,.12),0)
    box("Back skirting",(0,3.87,.17),(8,.10,.25),2)
    for x in (-2.4,.4):
        box("Window frame",(x,3.86,2.20),(1.65,.10,1.55),2)
        box("Window glass",(x,3.79,2.20),(1.43,.05,1.32),11)
        box("Window mullion",(x,3.73,2.20),(.065,.06,1.35),2)
        box("Window crossbar",(x,3.73,2.20),(1.43,.06,.065),2)


def monitor(x,y,z):
    box("CRT casing",(x,y,z+.22),(.70,.52,.50),4)
    box("CRT glass",(x,y-.275,z+.23),(.54,.035,.34),7)
    box("CRT stand",(x,y,z-.05),(.36,.32,.12),7)
    box("Keyboard",(x,y-.48,z-.06),(.64,.22,.04),3)


def shelf(x,y,w=1.6,boxes=True):
    for dx in (-w/2,w/2): box("Shelf upright",(x+dx,y,1.38),(.08,.60,2.7),4)
    for level in range(4):
        z=.30+level*.67
        box("Shelf plank",(x,y,z),(w,.65,.08),2)
        if boxes:
            for j in range(5):
                h=random.uniform(.20,.43)
                box("Stock carton",(x-w*.37+j*w*.185,y-.08,z+h/2+.05),(.20,.32,h),random.choice((3,6,8,13)))


def cafe():
    room(0,3)
    box("Counter base",(-2.9,1.2,.62),(1.20,4.20,1.24),2)
    box("Counter stone",(-2.9,1.2,1.28),(1.36,4.30,.14),4)
    monitor(-2.9,2.55,1.46)
    box("Receipt roll",(-2.7,.35,1.38),(.36,.55,.018),8)
    box("Coffee machine",(-2.9,1.55,1.57),(.72,.75,.50),4)
    cylinder("Machine dial",(-2.9,1.16,1.62),.09,.035,8,(math.pi/2,0,0))
    for y in (1.05,1.40): cylinder("Coffee cup",(-2.25,y,1.43),.10,.19,8)
    for y in (.5,2.35):
        box("Booth bench",(2.95,y,.47),(1.4,1.45,.32),5)
        box("Booth back",(3.53,y,.94),(.18,1.45,1.20),5)
        table("Booth table",1.95,y,1.1,1.15)
    cylinder("Cup lid",(1.90,2.25,.945),.17,.035,8)
    cylinder("Americano",(2.18,2.60,1.025),.13,.22,8)
    table("Evidence table",.15,-1.75,1.65,.95)
    box("Lab report",(.15,-1.75,.926),(.70,.58,.012),8)
    box("Evidence tray",(.65,-1.63,.95),(.38,.36,.06),4)
    chair(.10,-2.58)
    table("Staff station",(-.7),.3,.9,.75)
    box("Jo's notebook",(-.7,.3,.945),(.42,.45,.05),6)
    chair(-.7,1.1,6)
    box("Security panel",(2.75,3.85,1.80),(.75,.12,.92),4)
    box("Panel screen",(2.75,3.76,1.93),(.52,.04,.30),7)
    for x in (-2.8,1.8):
        cylinder("Pendant stem",(x,.5,3.2),.025,.8,7)
        cylinder("Pendant shade",(x,.5,2.82),.32,.13,9)
    return {"receipt_004":[-2.7,.35,1.45],"camera_log":[2.75,3.70,1.95],
            "toxicology":[.15,-1.75,1.0],"cup_lid":[1.90,2.25,1.05],
            "jo_statement":[-.7,.3,1.02],"panel_log":[-2.9,2.30,1.85]}


def alley():
    room(1,10,False)
    box("Service door frame",(-1.8,3.76,1.22),(1.5,.15,2.44),4)
    box("Service door",(-1.8,3.65,1.20),(1.28,.08,2.25),6)
    box("Door reader",(-.75,3.70,1.28),(.22,.18,.36),7)
    box("Reader lamp",(-.75,3.59,1.33),(.12,.02,.06),9)
    for y in (1.1,2.6):
        box("Dumpster",(-3.10,y,.72),(1.25,1.1,1.25),6)
        lid=box("Dumpster lid",(-3.10,y,1.39),(1.35,1.20,.10),7)
        lid.rotation_euler.y=.12
    for x in (2.8,3.2):
        cylinder("Drain pipe",(x,3.72,1.7),.08,3.4,4)
    box("Ventilation grate",(3.89,2.2,2.2),(.06,1.3,.6),7)
    for z in (2.0,2.15,2.30,2.45): box("Vent slat",(3.82,2.2,z),(.10,1.2,.025),4)
    for y in (-1.0,.2):
        cylinder("Scooter wheel",(1.45,y,.33),.30,.18,7,(0,math.pi/2,0))
    box("Scooter body",(1.45,-.35,.62),(.45,1.35,.42),5)
    box("Delivery box",(1.45,.15,1.02),(.70,.70,.54),8)
    box("Scooter saddle",(1.45,-.50,.88),(.42,.56,.12),7)
    box("Handlebar",(1.45,-1.01,1.13),(.85,.08,.07),4)
    cylinder("Steering",(1.45,-.97,.86),.045,.6,4)
    for x,y in ((-1.5,-1.2),(2.6,2.7)):
        box("Shipping crate",(x,y,.36),(.75,.70,.72),12)
    box("Drain",(.1,-2.35,.012),(1.25,.30,.02),7)
    for x in (-.4,-.2,0,.2,.4): box("Drain rib",(x,-2.35,.029),(.06,.30,.025),4)
    box("Door lamp",(-1.8,3.66,2.72),(.65,.26,.20),9)
    return {"service_log":[-.75,3.52,1.48],"delivery_photo":[1.45,-.05,1.35]}


def store():
    room(13,3)
    for x in (-2.75,-.6,1.55): shelf(x,3.3,1.70)
    for y in (-.4,1.5):
        shelf(2.8,y,1.25)
    box("Pharmacy counter",(-2.5,.15,.62),(2.30,1.20,1.24),4)
    box("Countertop",(-2.5,.15,1.29),(2.4,1.30,.12),3)
    monitor(-2.8,.18,1.45)
    for x in (-2.0,-1.7):
        cylinder("Medicine bottle",(x,-.05,1.53),.105,.35,6)
        cylinder("Bottle lid",(x,-.05,1.73),.11,.06,8)
    box("Counter receipt pad",(-2.25,-.18,1.37),(.30,.42,.02),8)
    box("Freezer cabinet",(-3.45,2.65,.97),(.85,1.70,1.94),4)
    box("Freezer glass",(-2.99,2.65,1.08),(.03,1.45,1.54),11)
    for x in (-1,1): box("Fluorescent fixture",(x,1.2,3.10),(.12,2.0,.10),8)
    box("Shopping basket",(.15,-1.20,.38),(.80,.65,.76),15)
    box("Door mat",(.20,-2.25,.03),(1.7,.8,.06),7)
    return {"pharmacy_footage":[-2.8,-.12,1.86]}


def apartment():
    room(0,2)
    box("Rug",(.65,-.1,.025),(3.6,2.8,.025),14)
    table("Writing desk",-2.5,2.4,2.3,1.15)
    monitor(-2.5,2.5,1.06)
    for x in (-3.3,-1.7): box("Manuscript stack",(x,2.35,.97),(.45,.62,.16),8)
    chair(-2.5,1.25,6)
    shelf(.20,3.3,1.8)
    box("Sofa base",(2.65,1.85,.38),(1.45,2.75,.42),6)
    box("Sofa back",(3.25,1.85,.95),(.25,2.80,1.20),6)
    for y in (.50,3.15): box("Sofa arm",(2.65,y,.73),(1.5,.24,.75),6)
    for y in (1.15,2.2): box("Sofa cushion",(2.55,y,.68),(1.1,.94,.22),13)
    table("Phone table",2.0,-.50,1.0,.85,z=.72)
    box("Answering machine",(2.0,-.50,.86),(.52,.35,.16),4)
    box("Telephone handset",(2.0,-.55,.98),(.60,.13,.09),7)
    table("Coffee table",.50,1.1,1.5,.90,z=.48)
    cylinder("Glass",(.70,1.1,.62),.08,.20,11)
    box("Open book",(.2,1.1,.56),(.60,.42,.03),8)
    cylinder("Floor lamp stem",(3.1,-1.45,1.2),.04,2.4,7)
    cylinder("Floor lamp shade",(3.1,-1.45,2.25),.38,.4,9)
    box("Coat hook board",(-3.85,-.1,1.80),(.12,.75,.20),2)
    return {"draft_email":[-2.5,2.18,1.48],"sasha_voicemail":[2.0,-.50,1.04]}


rooms={}
for name,builder in (("cafe",cafe),("alley",alley),("store",store),("apartment",apartment)):
    bpy.ops.object.select_all(action="SELECT"); bpy.ops.object.delete(use_global=False)
    points=builder()
    bpy.context.view_layer.update()
    vertices=[]
    light=Vector((-.4,-.7,1)).normalized()
    tint={"cafe":(1,.95,.84),"alley":(.84,.91,1),"store":(.92,1,.95),"apartment":(1,.92,.80)}[name]
    for obj in list(bpy.context.scene.objects):
        if obj.type!="MESH": continue
        mesh=obj.data; mesh.calc_loop_triangles()
        normal_matrix=obj.matrix_world.to_3x3().inverted().transposed()
        for tri in mesh.loop_triangles:
            normal=(normal_matrix@tri.normal).normalized()
            brightness=.65+.32*max(0,normal.dot(light))
            if obj["tile"] in (8,9): brightness=max(.88,brightness)
            for index,loop in zip(tri.vertices,tri.loops):
                p=obj.matrix_world@mesh.vertices[index].co
                uv=mesh.uv_layers.active.data[loop].uv
                # PNG top-down V differs from Blender's UV convention.
                vertices.append([round(p.x,5),round(p.y,5),round(p.z,5),round(uv.x,6),round(1-uv.y,6),
                                 round(brightness*tint[0],4),round(brightness*tint[1],4),round(brightness*tint[2],4),1])
    cameras=[{"name":"Right view","eye":[3.6,-4.8,3.0],"target":[0,1.1,1.2],"fov":60},
             {"name":"Left view","eye":[-3.6,-4.8,2.9],"target":[0,1.1,1.2],"fov":60}]
    rooms[name]={"vertices":vertices,"cameras":cameras,"points":points}
    bpy.context.scene.render.resolution_x=320
    bpy.context.scene.render.resolution_y=176
    bpy.context.scene.render.resolution_percentage=100
    for camera in cameras:
        data=bpy.data.cameras.new(camera["name"])
        data.sensor_fit="VERTICAL"
        data.lens=data.sensor_height/(2*math.tan(math.radians(camera["fov"]/2)))
        obj=bpy.data.objects.new(camera["name"],data); bpy.context.collection.objects.link(obj)
        obj.location=camera["eye"]
        obj.rotation_euler=(Vector(camera["target"])-obj.location).to_track_quat("-Z","Y").to_euler()
        bpy.context.scene.camera=obj
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/f"{name}.blend"))
    print(f"space={name} triangles={len(vertices)//3} hotspots={len(points)} views=2")
(OUT/"rooms.json").write_text(json.dumps(rooms,separators=(",",":")))
print("spaces_build=pass atlas=128x128 rooms=4")
