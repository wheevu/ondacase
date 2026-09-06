"""Original low-poly district diorama. Blender 5.2, offline rendering only."""
import math
from pathlib import Path
import random

import bpy
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/map"
assert OUT.is_dir()
random.seed(1922)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.context.preferences.filepaths.save_version = 0

atlas = bpy.data.images.new("District / 128px atlas", 128, 128)
pixels = []
colors = [(.37,.30,.23), (.24,.29,.29), (.18,.20,.19), (.39,.39,.32)]
for y in range(128):
    for x in range(128):
        tile = (x//64) + 2*(y//64)
        color = colors[tile]
        noise = random.uniform(-.035,.035)
        mortar = (y%8 == 0 or (x + (4 if y//8%2 else 0))%16 == 0) if tile < 2 else (x%16 == 0 or y%16 == 0)
        pixels.extend([max(0,c + noise - (.07 if mortar else 0)) for c in color] + [1])
atlas.pixels[:] = pixels
atlas.filepath_raw = str(OUT / "district-atlas.png")
atlas.file_format = "PNG"
atlas.save(); atlas.pack(); atlas.filepath = "//district-atlas.png"


def material(name, color, tile=None, emission=0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color,1)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color,1)
    shader.inputs["Roughness"].default_value = 1
    if emission:
        shader.inputs["Emission Color"].default_value = (*color,1)
        shader.inputs["Emission Strength"].default_value = emission
    if tile is not None:
        uv = mat.node_tree.nodes.new("ShaderNodeTexCoord")
        mapping = mat.node_tree.nodes.new("ShaderNodeVectorMath")
        mapping.operation = "MULTIPLY_ADD"
        mapping.inputs[1].default_value = (.49,.49,1)
        mapping.inputs[2].default_value = ((tile%2)*.5+.005,(tile//2)*.5+.005,0)
        texture = mat.node_tree.nodes.new("ShaderNodeTexImage")
        texture.image,texture.interpolation = atlas,"Closest"
        mat.node_tree.links.new(uv.outputs["UV"],mapping.inputs[0])
        mat.node_tree.links.new(mapping.outputs[0],texture.inputs[0])
        mat.node_tree.links.new(texture.outputs["Color"],shader.inputs["Base Color"])
    return mat


brick = material("Warm brick",(.37,.30,.23),0)
blue = material("Blue-grey siding",(.24,.29,.29),1)
road = material("Asphalt",(.18,.20,.19),2)
paving = material("Concrete",(.39,.39,.32),3)
roof = material("Tar roof",(.095,.12,.125),2)
dark = material("Door frames",(.065,.08,.075))
glass = material("Unlit glass",(.10,.15,.16))
light = material("Sodium windows",(.68,.47,.23),emission=.35)
cream = material("Worn cream paint",(.62,.59,.43))
olive = material("Painted olive metal",(.28,.32,.24))
rust = material("Awning canvas",(.43,.25,.16))


def box(name, center, size, mat):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    obj=bpy.context.object
    obj.name=name
    obj.scale=size
    obj.data.materials.append(mat)
    return obj


def building(name,x,y,w,d,h,mat):
    box(name,(x,y,h/2+.17),(w,d,h),mat)
    box(name+" / cornice",(x,y,h+.19),(w+.16,d+.16,.16),paving)
    box(name+" / roof",(x,y,h+.29),(w-.15,d-.15,.06),roof)
    box(name+" / roof vent",(x+.5,y+.2,h+.45),(.5,.55,.32),blue)
    for floor in range(max(1,int(h/1.1))):
        for col in (-1,0,1):
            wx=x+col*w*.28
            z=.72+floor*1.1
            box(name+" / window frame",(wx,y-d/2-.02,z),(.60,.06,.68),dark)
            box(name+" / window",(wx,y-d/2-.06,z),(.48,.025,.54),light if random.random()>.4 else glass)
            box(name+" / sill",(wx,y-d/2-.10,z-.35),(.70,.16,.07),paving)
    return (x,y,h+.4)


box("District base",(0,.2,-.25),(12,10,.5),dark)
box("Road bed",(0,.2,.025),(11.8,9.8,.05),road)
box("West sidewalk",(-3,.4,.10),(5,8.7,.16),paving)
box("East sidewalk",(3,.4,.10),(4,8.7,.16),paving)
box("Service passage",(-2.7,1.2,.195),(4.2,1.0,.04),road)
for y in (-3.5,-2,-.5,1,2.5,4):
    box("Street center stripe",(.35,y,.075),(.10,.65,.02),cream)
for x in (-.5,0,.5,1):
    box("Crossing",(x,-3.4,.08),(.23,1.0,.015),cream)

anchors={}
anchors["cafe"]=building("Cafe Lantern",-3,-1.35,3.5,2.7,2.1,brick)
anchors["apartment"]=building("Eli's apartment",-3,3.05,3.5,2.3,3.45,brick)
anchors["store"]=building("Night store",3,.65,3.0,3.5,1.75,blue)
anchors["alley"]=(-2.4,1.1,.25)
# Awnings, storefronts, and a staff door distinguish the locations without pins.
box("Cafe fascia",(-3,-2.78,1.78),(3.65,.18,.3),olive)
for i in range(10):
    awning=box("Cafe awning stripe",(-4.62+i*.36,-3.00,1.57),(.35,.72,.08),cream if i%2 else rust)
    awning.rotation_euler.x=math.radians(12)
box("Cafe door",(-3,-2.74,.67),(.68,.06,1.10),dark)
box("Store sign",(3,-1.18,1.40),(2.6,.15,.35),olive)
box("Pharmacy cross upright",(3,-1.28,1.42),(.08,.05,.24),cream)
box("Pharmacy cross across",(3,-1.29,1.42),(.24,.05,.08),cream)
box("Store doorway",(3,-1.15,.61),(.70,.05,1.15),dark)
box("Service door",(-2.2,.02,.66),(.65,.05,1.10),dark)
for x in (-4.1,-3.3):
    box("Alley bins",(x,1.12,.49),(.55,.60,.58),olive)
    box("Bin lid",(x,1.12,.80),(.62,.64,.06),dark)
for x,y in ((-5,-3.1),(1.2,-2),(1.2,3.5)):
    box("Street lamp",(x,y,1.05),(.08,.08,2),dark)
    box("Lamp head",(x,y,2.07),(.40,.28,.14),light)
    data=bpy.data.lights.new("Pool of sodium","POINT")
    data.energy=18; data.color=(1,.69,.35); data.shadow_soft_size=.6
    obj=bpy.data.objects.new("Pool of sodium",data); bpy.context.collection.objects.link(obj)
    obj.location=(x,y,1.92)
# Boxy parked delivery scooter, off the service passage.
box("Scooter chassis",(-1.2,1.8,.45),(.30,.95,.25),rust)
box("Scooter delivery box",(-1.2,2.05,.74),(.52,.50,.40),cream)
for y in (1.42,2.13):
    bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=.22,depth=.14,location=(-1.2,y,.30),rotation=(0,math.pi/2,0))
    bpy.context.object.data.materials.append(dark)

scene=bpy.context.scene
scene.render.engine="CYCLES"; scene.cycles.samples=32; scene.cycles.seed=1922
scene.world.color=(.12,.14,.16)
data=bpy.data.lights.new("Overcast sky","AREA"); data.energy=900; data.size=10
obj=bpy.data.objects.new("Overcast sky",data); scene.collection.objects.link(obj)
obj.location=(-4,-6,12); obj.rotation_euler=(Vector((0,0,0))-obj.location).to_track_quat("-Z","Y").to_euler()
data.color=(.81,.87,1)
camera_data=bpy.data.cameras.new("District camera")
camera=bpy.data.objects.new("District camera",camera_data); scene.collection.objects.link(camera)
camera.location=(12,-16,15)
camera.rotation_euler=(Vector((0,.3,.6))-camera.location).to_track_quat("-Z","Y").to_euler()
camera_data.type="ORTHO"; camera_data.ortho_scale=17.8; scene.camera=camera
scene.view_settings.view_transform="Standard"; scene.view_settings.look="None"
scene.render.resolution_x=320; scene.render.resolution_y=224; scene.render.resolution_percentage=100
scene.render.film_transparent=True; scene.render.image_settings.file_format="PNG"
scene.render.image_settings.color_mode="RGBA"; scene.render.filepath="//district.png"
bpy.context.view_layer.update()
for name,point in anchors.items():
    p=world_to_camera_view(scene,camera,Vector(point))
    print(f"map_anchor {name} x={round(p.x*320)} y={round((1-p.y)*224)}")
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"district.blend"))
bpy.ops.render.render(write_still=True)
print("district_map=pass render=320x224 atlas=128x128")
