;; Fixed-camera 3D inspection renderer. Geometry and UVs come from build-spaces.py.
(local json (require :dkjson))
(local WIDTH 320)
(local HEIGHT 176)
(local scene {:rooms {} :meshes {} :ready false})

(fn vector? [v]
  (and (= (type v) :table) (= (# v) 3)
       (do (var valid true)
           (each [_ n (ipairs v)]
             (when (or (not= (type n) :number) (not (< (math.abs n) 1000))) (set valid false)))
           valid)))

(fn dot [a b] (+ (* (. a 1) (. b 1)) (* (. a 2) (. b 2)) (* (. a 3) (. b 3))))
(fn sub [a b] [(- (. a 1) (. b 1)) (- (. a 2) (. b 2)) (- (. a 3) (. b 3))])
(fn unit [v]
  (let [magnitude (math.sqrt (dot v v))]
    [(/ (. v 1) magnitude) (/ (. v 2) magnitude) (/ (. v 3) magnitude)]))
(fn cross [a b]
  [(- (* (. a 2) (. b 3)) (* (. a 3) (. b 2)))
   (- (* (. a 3) (. b 1)) (* (. a 1) (. b 3)))
   (- (* (. a 1) (. b 2)) (* (. a 2) (. b 1)))])

(fn camera [location view]
  (let [room (. scene.rooms location)
        c (and room (. room.cameras (or view 1)))]
    (when c
      (let [forward (unit (sub c.target c.eye))
            right (unit (cross forward [0 0 1]))
            up (cross right forward)
            tangent (math.tan (/ (* c.fov math.pi) 360))]
        {:eye c.eye :name c.name : forward : right : up :tangent tangent}))))

(fn project [location view point]
  (let [c (camera location view)]
    (when c
      (let [delta (sub point c.eye) depth (dot delta c.forward)]
        (when (and (> depth 0.1) (< depth 50))
          (let [x (+ 0.5 (/ (dot delta c.right) (* 2 depth c.tangent (/ WIDTH HEIGHT))))
                y (- 0.5 (/ (dot delta c.up) (* 2 depth c.tangent)))]
            (when (and (>= x 0) (<= x 1) (>= y 0) (<= y 1)) [x y])))))))

(fn release! []
  (each [_ mesh (pairs scene.meshes)] (mesh:release))
  (each [_ key (ipairs [:canvas :atlas :shader])]
    (when (. scene key) ((. (. scene key) :release) (. scene key)) (tset scene key nil)))
  (tset scene :meshes {}) (tset scene :ready false))

(fn load! []
  (release!)
  (tset scene :rooms {})
  (let [(ok err) (pcall (fn []
    (let [raw (assert (love.filesystem.read "assets/spaces/rooms.json"))
          rooms (assert (json.decode raw))]
      (assert (= (type rooms) :table) "Invalid space metadata")
      (each [_ id (ipairs [:cafe :alley :store :apartment])]
        (let [room (. rooms id)]
          (assert (and (= (type room) :table) (= (type room.vertices) :table)
                       (= (type room.points) :table) (= (type room.cameras) :table)
                       (= (# room.cameras) 2)) "Incomplete space metadata")
          (each [_ c (ipairs room.cameras)]
            (assert (and (= (type c) :table) (vector? c.eye) (vector? c.target)
                         (= (type c.fov) :number) (> c.fov 1) (< c.fov 175)) "Invalid camera")
            (let [direction (sub c.target c.eye)]
              (assert (> (+ (* (. direction 1) (. direction 1)) (* (. direction 2) (. direction 2))) 0.001) "Vertical or zero camera direction")))
          (each [_ p (pairs room.points)] (assert (vector? p) "Invalid inspection point"))))
      (tset scene :rooms rooms))
    (assert love.graphics.newMesh "3D graphics unavailable")
    (tset scene :atlas (love.graphics.newImage "assets/spaces/atlas.png"))
    (scene.atlas:setFilter :nearest :nearest)
    (tset scene :shader (love.graphics.newShader "assets/spaces/room.glsl"))
    (tset scene :canvas (love.graphics.newCanvas WIDTH HEIGHT {:format :rgba8 :msaa 0 :dpiscale 1}))
    (scene.canvas:setFilter :nearest :nearest)
    (each [id room (pairs scene.rooms)]
      (let [mesh (love.graphics.newMesh [["VertexPosition" :float 3] ["VertexTexCoord" :float 2] ["VertexColor" :float 4]] room.vertices :triangles :static)]
        (mesh:setTexture scene.atlas)
        (tset scene.meshes id mesh)))
    (tset scene :ready true)))]
    (tset scene :error (if ok nil (tostring err)))
    (when (not ok) (release!))
    scene.ready))

(fn draw! [location view x y w h]
  (when (and scene.ready (. scene.meshes location))
    (let [c (camera location view) previous (love.graphics.getCanvas)]
      (love.graphics.push :all)
      (let [(ok err) (pcall (fn []
        (love.graphics.setCanvas {1 scene.canvas :depth true})
        (love.graphics.origin)
        (love.graphics.setScissor)
        (love.graphics.clear 0.065 0.075 0.08 1 0 1)
        (love.graphics.setDepthMode :less true)
        (love.graphics.setMeshCullMode :none)
        (love.graphics.setBlendMode :replace :premultiplied)
        (love.graphics.setColor 1 1 1 1)
        (love.graphics.setShader scene.shader)
        (scene.shader:send :eye c.eye)
        (scene.shader:send :rightAxis c.right)
        (scene.shader:send :upAxis c.up)
        (scene.shader:send :forwardAxis c.forward)
        (scene.shader:send :lens [(* c.tangent (/ WIDTH HEIGHT)) c.tangent])
        (love.graphics.draw (. scene.meshes location))))]
        (love.graphics.setCanvas previous)
        (love.graphics.pop)
        (if ok
          (do (love.graphics.setColor 1 1 1 1)
              (love.graphics.draw scene.canvas x y 0 (/ w WIDTH) (/ h HEIGHT)) true)
          (do (tset scene :ready false) (tset scene :error (tostring err)) false))))))

(fn point [location id]
  (let [room (. scene.rooms location)] (and room (. room.points id))))

{:load load! :draw draw! : project : camera : point :status scene :width WIDTH :height HEIGHT}
