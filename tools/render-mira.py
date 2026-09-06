"""Original cast portraits. Run with Blender 5.2 --background --python.

Default: rebuild the approved Mira. Use -- --character arin for another person.

All coordinates and texture marks are authored here, not derived from photos.
The small atlas deliberately carries face detail instead of dense geometry.
"""

import math
from pathlib import Path
import random
import argparse
import sys

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description="Render an editable ondacase cast portrait.")
parser.add_argument("--character", choices=("mira", "arin", "jo", "sasha", "dan"), default="mira")
args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
CHARACTER = args.character
LABEL = CHARACTER.capitalize()
SOURCE = ROOT / f"assets/suspects/{CHARACTER}-source"
assert SOURCE.is_dir(), f"Missing asset source directory: {SOURCE}"
random.seed(22)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.context.preferences.filepaths.save_version = 0

# Top-down painter coordinates; convert once to Blender's bottom-up image.
pixels = [[(0.12, 0.10, 0.08) for _ in range(128)] for _ in range(128)]


def wash(x, y, w, h, color, noise=0.035):
    for py in range(y, y + h):
        for px in range(x, x + w):
            n = random.uniform(-noise, noise)
            pixels[py][px] = tuple(max(0, min(1, c + n)) for c in color)


def ellipse(cx, cy, rx, ry, color, strength=1):
    for y in range(max(0, int(cy - ry)), min(128, int(cy + ry + 1))):
        for x in range(max(0, int(cx - rx)), min(128, int(cx + rx + 1))):
            d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
            if d < 1:
                a = strength * min(1, (1 - d) * 3)
                pixels[y][x] = tuple(c * a + old * (1 - a)
                                     for c, old in zip(color, pixels[y][x]))


def polygon(points, color):
    for y in range(max(0, min(p[1] for p in points)), min(128, max(p[1] for p in points) + 1)):
        for x in range(max(0, min(p[0] for p in points)), min(128, max(p[0] for p in points) + 1)):
            inside = False
            for a, b in zip(points, points[1:] + points[:1]):
                if (a[1] > y) != (b[1] > y) and x < (b[0] - a[0]) * (y - a[1]) / (b[1] - a[1]) + a[0]:
                    inside = not inside
            if inside:
                pixels[y][x] = color


wash(0, 0, 64, 80, (0.63, 0.46, 0.34), 0.025)
ellipse(29, 32, 25, 36, (0.77, 0.60, 0.45), 0.75)
ellipse(9, 42, 11, 28, (0.36, 0.26, 0.22), 0.5)
ellipse(56, 42, 12, 28, (0.35, 0.26, 0.23), 0.65)
ellipse(31, 20, 17, 12, (0.83, 0.66, 0.48), 0.35)
for cx in (19, 45):
    ellipse(cx, 38, 10, 7, (0.32, 0.25, 0.23), 0.55)
    ellipse(cx, 46, 10, 8, (0.64, 0.37, 0.28), 0.35)
    ellipse(cx, 34, 9, 4, (0.38, 0.28, 0.23), 0.75)
    polygon([(cx - 7, 37), (cx - 3, 35), (cx + 3, 35), (cx + 7, 38), (cx + 2, 40), (cx - 4, 39)], (0.25, 0.20, 0.18))
    polygon([(cx - 6, 37), (cx - 2, 36), (cx + 3, 37), (cx + 5, 38), (cx - 3, 39)], (0.69, 0.65, 0.52))
    ellipse(cx + 1, 37, 2.3, 2.5, (0.16, 0.19, 0.15))
    pixels[36][cx + 1] = (0.77, 0.72, 0.58)
    polygon([(cx - 7, 32), (cx - 2, 30), (cx + 6, 32), (cx + 7, 34), (cx - 2, 32)], (0.22, 0.17, 0.14))
ellipse(33, 44, 4, 9, (0.87, 0.66, 0.48), 0.7)
ellipse(28, 48, 3, 4, (0.43, 0.29, 0.23), 0.65)
ellipse(38, 48, 3, 4, (0.43, 0.29, 0.23), 0.65)
polygon([(28, 50), (31, 51), (35, 51), (38, 49), (36, 52), (31, 53)], (0.37, 0.25, 0.22))
ellipse(33, 54, 2, 3, (0.48, 0.31, 0.25), 0.5)
polygon([(23, 58), (29, 56), (33, 57), (36, 56), (43, 58), (36, 60), (29, 60)], (0.47, 0.28, 0.25))
polygon([(25, 59), (32, 59), (41, 58), (37, 62), (29, 62)], (0.64, 0.39, 0.32))
polygon([(24, 58), (32, 59), (42, 58), (38, 60), (29, 60)], (0.32, 0.22, 0.20))
ellipse(33, 67, 9, 4, (0.82, 0.63, 0.47), 0.5)
ellipse(32, 73, 16, 4, (0.38, 0.28, 0.22), 0.55)
# Bob, cream shirt, and worn olive apron occupy separate atlas islands.
wash(64, 0, 64, 64, (0.18, 0.13, 0.10), 0.025)
for x in range(65, 127, 3):
    shade = random.uniform(0.16, 0.30)
    polygon([(x, 1), (x + 2, 1), (x - 2, 62), (x - 3, 62)], (shade, shade * 0.73, shade * 0.53))
wash(0, 80, 64, 48, (0.55, 0.51, 0.40), 0.04)
for x in (8, 25, 46, 57):
    polygon([(x, 80), (x + 3, 80), (x - 2, 127)], (0.39, 0.36, 0.29))
wash(64, 64, 64, 64, (0.24, 0.27, 0.23), 0.035)
polygon([(67, 93), (123, 93), (119, 95), (69, 95)], (0.39, 0.39, 0.29))
polygon([(68, 95), (70, 95), (72, 119), (117, 119), (121, 95), (123, 95), (120, 122), (70, 122)], (0.15, 0.18, 0.16))

if CHARACTER != "mira":
    # Shared atlas layout, individually painted finishes and face proportions.
    skin, hair, cloth = {
        "arin": ((.94, .98, 1.04), (.11, .105, .10), (.25, .31, .35)),
        "jo": ((.68, .65, .62), (.10, .075, .055), (.57, .43, .24)),
        "sasha": ((1.08, 1.04, 1.12), (.33, .14, .085), (.32, .23, .25)),
        "dan": ((.98, .92, .83), (.13, .11, .085), (.60, .32, .16)),
    }[CHARACTER]
    for x, y, w, h, factors in [
        (0, 0, 64, 80, skin),
        (64, 0, 64, 64, tuple(a / b for a, b in zip(hair, (.18, .13, .10)))),
        (0, 80, 64, 48, tuple(a / b for a, b in zip(cloth, (.55, .51, .40)))),
    ]:
        for py in range(y, y + h):
            for px in range(x, x + w):
                pixels[py][px] = tuple(min(1, c * f) for c, f in zip(pixels[py][px], factors))
    if CHARACTER == "arin":
        for cx in (19, 45):
            ellipse(cx, 42, 8, 2, (.30, .27, .25), .45)
        wash(64, 64, 64, 64, (.43, .40, .32), .025)
        polygon([(89, 65), (100, 65), (105, 127), (88, 127)], (.25, .16, .15))
    elif CHARACTER == "jo":
        wash(64, 0, 64, 64, (.10, .08, .055), .045)
        for _ in range(90):
            ellipse(random.randrange(66, 126), random.randrange(2, 62), 2, 2, (.18, .14, .10), .6)
        for y in range(64, 128):
            for x in range(64, 128):
                r, g, b = pixels[y][x]
                pixels[y][x] = (r * .65, g * .87, b * 1.1)
    elif CHARACTER == "sasha":
        polygon([(24, 58), (31, 56), (34, 57), (38, 56), (43, 58), (37, 62), (29, 62)], (.40, .19, .20))
        polygon([(25, 59), (41, 58), (37, 60), (29, 60)], (.23, .14, .16))
        for cx in (19, 45):
            polygon([(cx-8, 36), (cx-4, 34), (cx+3, 35), (cx+7, 37), (cx+2, 36), (cx-3, 36)], (.18, .13, .13))
        wash(64, 64, 64, 64, (.47, .42, .31), .035)
        for y in range(68, 128, 8):
            polygon([(64, y), (127, y+3), (127, y+5), (64, y+2)], (.28, .29, .25))
    elif CHARACTER == "dan":
        for _ in range(200):
            x, y = random.randrange(14, 53), random.randrange(50, 73)
            if y > 63 or x < 24 or x > 42 or y < 56:
                r, g, b = pixels[y][x]
                pixels[y][x] = (r * .68, g * .69, b * .70)
        wash(64, 64, 64, 64, (.25, .30, .31), .025)
        for x in (81, 94, 107):
            polygon([(x,65),(x+5,65),(x+4,77),(x+1,77)], (.10,.13,.13))
        polygon([(64, 86), (127, 86), (127, 94), (64, 94)], (.65, .66, .56))

atlas = bpy.data.images.new(f"{LABEL} / 128px painted atlas", 128, 128)
atlas.pixels[:] = [v for row in reversed(pixels) for rgb in row for v in (*rgb, 1)]
atlas.filepath_raw = str(SOURCE / f"{CHARACTER}-atlas.png")
atlas.file_format = "PNG"
atlas.save()
atlas.pack()
atlas.filepath = f"//{CHARACTER}-atlas.png"
material = bpy.data.materials.new(f"{LABEL} / nearest atlas")
material.use_nodes = True
nodes = material.node_tree.nodes
shader = nodes.get("Principled BSDF")
shader.inputs["Roughness"].default_value = 1
texture = nodes.new("ShaderNodeTexImage")
texture.image = atlas
texture.interpolation = "Closest"
material.node_tree.links.new(texture.outputs["Color"], shader.inputs["Base Color"])


def mesh(name, verts, faces, region, uv=None):
    name = name.replace("Mira", LABEL)
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    data.materials.append(material)
    layer = data.uv_layers.new()
    x, y, w, h = region
    for face in data.polygons:
        for loop_index in face.loop_indices:
            index = data.loops[loop_index].vertex_index
            if uv:
                u, v = uv[index]
            else:
                vx, vy, vz = verts[index]
                u, v = (vx + 0.8) / 1.6, (vz - 1.2) / 2.4
            layer.data[loop_index].uv = ((x + max(0.01, min(0.99, u)) * w) / 128,
                                          1 - (y + (1 - max(0.01, min(0.99, v))) * h) / 128)
    # Actual triangles, not smooth high-poly geometry made to look pixelated.
    modifier = obj.modifiers.new("Console triangles", "TRIANGULATE")
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    return obj


def rings(name, sections, count, region, face_uv=False):
    verts = []
    for z, rx, ry, cy in sections:
        for i in range(count):
            angle = 2 * math.pi * i / count - math.pi / 2
            verts.append((rx * math.cos(angle), cy + ry * math.sin(angle), z))
    faces = []
    for row in range(len(sections) - 1):
        for i in range(count):
            a = row * count + i
            b = row * count + (i + 1) % count
            faces.append((a, b, b + count, a + count))
    faces += [tuple(reversed(range(count))), tuple(range(len(verts) - count, len(verts)))]
    uv = [((x + 0.36) / 0.72, (z - 2.57) / 0.95) for x, y, z in verts] if face_uv else None
    return mesh(name, verts, faces, region, uv)


head = rings("Mira / head", [
    (2.64, .10, .13, -.015), (2.70, .20, .18, 0),
    (2.82, .265, .23, .015), (2.92, .29, .24, .025),
    (3.02, .305, .265, .025), (3.13, .295, .255, .025),
    (3.25, .29, .265, .04), (3.39, .245, .24, .04),
    (3.47, .15, .16, .04), (3.50, .03, .04, .04),
], 16, (0, 0, 64, 80), True)
# Nose projects beyond the face. UVs continue the same painted face island.
nose = [(-.055, -.234, 3.16), (.045, -.234, 3.16),
        (-.060, -.262, 2.98), (.060, -.262, 2.98),
        (0, -.355, 3.015), (0, -.27, 2.965)]
mesh("Mira / nose", nose, [(0, 1, 4), (0, 4, 2), (1, 3, 4), (2, 4, 5), (4, 3, 5)],
     (0, 0, 64, 80), [((x + .36) / .72, (z - 2.57) / .95) for x, y, z in nose])
rings("Mira / neck", [(2.35, .16, .14, .06), (2.60, .135, .13, .04), (2.73, .14, .14, .04)], 8, (24, 60, 16, 16))
rings("Mira / work shirt", [(1.25, .52, .27, .09), (1.66, .57, .29, .08),
      (2.03, .63, .28, .08), (2.25, .59, .23, .07), (2.40, .32, .17, .06),
      (2.44, .17, .13, .05)], 12, (0, 80, 64, 48))
for side in (-1, 1):
    verts = [(side * x, y, z) for x, y, z in [(.45, -.12, 2.30), (.64, -.12, 2.22),
             (.82, -.08, 1.55), (.65, -.23, 1.42), (.42, .21, 2.30),
             (.65, .22, 2.20), (.85, .24, 1.55), (.64, .15, 1.42)]]
    mesh("Mira / sleeve " + str(side), verts,
         [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (1, 5, 6, 2), (3, 2, 6, 7)], (0, 80, 64, 48))
    mesh("Mira / collar " + str(side), [(side * .13, -.12, 2.48), (side * .31, -.18, 2.35),
         (side * .20, -.275, 2.14), (side * .05, -.22, 2.31)], [(0, 1, 2, 3)], (0, 80, 64, 48))
    mesh("Mira / apron strap " + str(side), [(side * .26, -.16, 2.40), (side * .32, -.16, 2.38),
         (side * .32, -.295, 2.01), (side * .25, -.30, 2.01)], [(0, 1, 2, 3)], (64, 64, 64, 64))
mesh("Mira / apron", [(-.36, -.27, 2.09), (.36, -.27, 2.09), (.48, -.28, 1.25),
     (0, -.315, 1.25), (-.48, -.28, 1.25), (0, -.32, 1.88)],
     [(0, 1, 5), (1, 2, 3, 5), (3, 4, 0, 5)], (64, 64, 64, 64),
     [(0, 1), (1, 1), (1, 0), (.5, 0), (0, 0), (.5, .72)])

# Open-front bob: cap and tapered side/back panels, no spherical helmet.
rings("Mira / hair crown", [(3.27, .31, .28, .06), (3.43, .28, .27, .06),
      (3.54, .17, .17, .06), (3.56, .015, .02, .06)], 12, (64, 0, 64, 64))
for side in (-1, 1):
    verts = [(side * x, y, z) for x, y, z in [(.22, -.18, 3.40), (.33, -.10, 3.25),
        (.34, -.07, 2.91), (.28, -.12, 2.73), (.24, -.03, 2.75),
        (.28, .03, 3.27), (.24, .21, 3.38), (.34, .22, 3.10), (.29, .24, 2.77)]]
    mesh("Mira / bob " + str(side), verts,
         [(0, 1, 5), (1, 2, 4, 5), (2, 3, 4), (5, 6, 7), (5, 7, 8, 4)], (64, 0, 64, 64))
mesh("Mira / swept fringe", [(-.25, -.20, 3.41), (.05, -.275, 3.46), (.25, -.22, 3.36),
     (-.28, -.245, 3.18), (-.12, -.285, 3.30), (.10, -.285, 3.37)],
     [(0, 1, 4), (0, 4, 3), (1, 5, 4), (1, 2, 5)], (64, 0, 64, 64))

if CHARACTER != "mira":
    # Change the generated base meshes, never the approved Mira blend or PNG.
    for obj in list(bpy.context.scene.objects):
        part = obj.name.split(" / ")[-1]
        if (CHARACTER in ("arin", "jo", "dan") and (part.startswith("bob") or part == "swept fringe")) or (
            CHARACTER in ("arin", "sasha", "dan") and part.startswith("apron")
        ):
            bpy.data.objects.remove(obj, do_unlink=True)

    for side in (-1, 1):
        mesh("Mira / ear " + str(side), [(side*x, y, z) for x,y,z in [
            (.28, -.01, 3.16), (.35, -.035, 3.13), (.355, -.04, 3.02),
            (.30, -.02, 2.97), (.31, .04, 3.10)]],
            [(0,1,2,3), (0,4,1), (1,4,2), (2,4,3)], (8, 48, 8, 20))

    if CHARACTER == "arin":
        mesh("Mira / side part", [(-.28,-.23,3.28), (-.23,-.24,3.47), (.16,-.25,3.51),
             (.29,-.22,3.34), (-.03,-.29,3.38)], [(0,1,4), (1,2,4), (2,3,4)], (64,0,64,64))
        for side in (-1,1):
            # Thin, angular spectacles with open lenses, not opaque eye patches.
            outer = [(side*x,-.295,z) for x,z in [(.045,3.125),(.235,3.125),(.235,3.035),(.045,3.035)]]
            inner = [(side*x,-.297,z) for x,z in [(.057,3.113),(.223,3.113),(.223,3.047),(.057,3.047)]]
            mesh("Mira / glasses " + str(side), outer+inner,
                 [(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)], (64,0,8,8))
        mesh("Mira / glasses bridge", [(-.045,-.296,3.10),(.045,-.296,3.10),(.045,-.296,3.088),(-.045,-.296,3.088)], [(0,1,2,3)], (64,0,8,8))
        mesh("Mira / shirt and tie", [(-.12,-.235,2.38),(.12,-.235,2.38),(.20,-.305,1.25),(-.20,-.305,1.25)],
             [(0,1,2,3)], (64,64,64,64), [(0,1),(1,1),(1,0),(0,0)])
    elif CHARACTER == "jo":
        crown = bpy.data.objects[f"{LABEL} / hair crown"]
        for vertex in crown.data.vertices:
            vertex.co.z += .045 * math.sin(vertex.index * 2.4)
        # Short temple wedges keep the crop distinct from Mira's straight bob.
        for side in (-1,1):
            mesh("Mira / temple " + str(side), [(side*.28,-.16,3.32),(side*.31,-.08,3.28),
                 (side*.30,-.09,3.13),(side*.27,-.17,3.19)], [(0,1,2,3)], (64,0,64,64))
    elif CHARACTER == "sasha":
        for obj in bpy.context.scene.objects:
            if " / bob " in obj.name:
                for v in obj.data.vertices:
                    if v.co.z < 3.1:
                        v.co.z -= .43
                        v.co.x *= 1.17
        rings("Mira / scarf", [(2.27,.23,.20,.025),(2.38,.25,.19,.025),(2.52,.18,.155,.025)], 10, (64,64,64,64))
        mesh("Mira / scarf tail", [(-.16,-.235,2.37),(.02,-.24,2.36),(-.06,-.33,1.63),(-.25,-.32,1.68)],
             [(0,1,2,3)], (64,64,64,64))
    elif CHARACTER == "dan":
        rings("Mira / cycle helmet", [(3.22,.335,.30,.06),(3.42,.36,.32,.06),
              (3.60,.23,.24,.06),(3.64,.05,.06,.06)], 12, (64,64,64,64))
        for side in (-1,1):
            mesh("Mira / helmet strap " + str(side), [(side*.30,-.13,3.25),(side*.32,-.13,3.25),
                 (side*.21,-.17,2.67),(side*.18,-.17,2.65)], [(0,1,2,3)], (64,0,8,8))
            mesh("Mira / reflective shoulder " + str(side), [(side*.28,-.205,2.32),(side*.52,-.18,2.26),
                 (side*.65,-.23,1.29),(side*.52,-.29,1.29)], [(0,1,2,3)], (65,86,50,7))
        mesh("Mira / jacket zip", [(-.013,-.275,2.30),(.013,-.275,2.30),(.013,-.30,1.25),(-.013,-.30,1.25)],
             [(0,1,2,3)], (64,0,8,8))

    face_width, face_height, shoulders, yaw = {
        "arin": (.88,1.07,1.03,7), "jo": (1.08,.93,.94,-13),
        "sasha": (.91,1.03,.93,11), "dan": (1.12,.98,1.10,-6),
    }[CHARACTER]
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        part = obj.name.split(" / ")[-1]
        face_part = any(part.startswith(p) for p in ("head","nose","ear","hair","bob","swept","side part","glasses","temple","cycle helmet","helmet strap"))
        for v in obj.data.vertices:
            if face_part:
                v.co.x *= face_width
                v.co.z = 3.1 + (v.co.z - 3.1) * face_height
            elif part != "neck":
                v.co.x *= shoulders

character = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
for obj in character:
    obj.rotation_euler[2] = math.radians(-9 if CHARACTER == "mira" else yaw)
triangles = sum(len(obj.data.polygons) for obj in character)
assert 600 <= triangles <= 1200, triangles

scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 32
scene.cycles.seed = 22
scene.world.color = (.10, .10, .10)
scene.view_settings.view_transform = "Standard"
scene.view_settings.look = "None"
scene.view_settings.exposure = 0
scene.view_settings.gamma = 1
scene.render.resolution_x = 144
scene.render.resolution_y = 216
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"


def area(name, location, energy, color, size):
    data = bpy.data.lights.new(name, "AREA")
    data.energy, data.color, data.size = energy, color, size
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (Vector((0, 0, 2.7)) - obj.location).to_track_quat("-Z", "Y").to_euler()


area("Sodium / counter light", (-2, -4, 5), 200, (1, .82, .60), 3)
area("Street / blue-grey fill", (3, -2, 3), 75, (.61, .72, .82), 4)
area("Kitchen / rim", (1, 2, 4), 130, (.90, .81, .62), 2)
camera_data = bpy.data.cameras.new("Interview / bust")
camera = bpy.data.objects.new("Interview / bust", camera_data)
scene.collection.objects.link(camera)
camera.location = (.10, -7, 3.00)
camera.rotation_euler = (Vector((0, 0, 2.68)) - camera.location).to_track_quat("-Z", "Y").to_euler()
camera_data.type = "ORTHO"
camera_data.ortho_scale = 2.05
scene.camera = camera
scene.render.filepath = f"//../{CHARACTER}-psx.png"
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / f"{CHARACTER}.blend"))
bpy.ops.render.render(write_still=True)
print(f"{CHARACTER}_portrait=pass triangles={triangles} atlas=128x128 portrait=144x216")
