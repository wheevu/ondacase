;; Fennel authoritative runtime. Compiles to src/main.lua; main.lua is tiny bootstrap.
(local layout (require :src.layout))
(local save-mod (require :src.save))
(local prolog (require :src.prolog))
(local ink (require :src.ink))
(local spaces (require :src.spaces))
(local palette {:ink [0.89 0.87 0.79]
                :paper [0.075 0.085 0.085]
                :panel [0.12 0.14 0.145]
                :panel-warm [0.16 0.15 0.12]
                :panel-cool [0.13 0.17 0.18]
                :line [0.36 0.40 0.40]
                :line-warm [0.46 0.43 0.33]
                :rust [0.76 0.48 0.35]
                :gold [0.73 0.63 0.43]
                :muted [0.61 0.65 0.64]
                :green [0.51 0.69 0.57]
                :red [0.76 0.48 0.35]
                :dust [0.60 0.65 0.68]
                :paper-light [0.10 0.12 0.12]})

(local W layout.W)
(local H layout.H)
(local scale-state {:scale 1 :ox 0 :oy 0})
(local fonts {})
(local art {})
(var buttons [])
(var focus-index 1)
(var focusable [])
(var hover-index nil)
(var mouse-lx -1)
(var mouse-ly -1)
(local capture-name (os.getenv "ONDACASE_CAPTURE"))
(local capture-path (os.getenv "ONDACASE_CAPTURE_PATH"))
(var capture-done false)
(var capture-requested false)

(local evidence-data
  [{:id "receipt_004" :title "RECEIPT 004" :sub "Iced americano / 19:22" :body "In-person purchase. Paid with Mira's card." :tag "PLACES MIRA" :color :gold :discovered "Found at the café register." :implication "Mira was present at 19:22." :status "Confirmed purchase record."}
   {:id "camera_log" :title "CAMERA LOG" :sub "Blind spot / 19:18-19:29" :body "West camera offline eleven minutes." :tag "CREATES OPPORTUNITY" :color :rust :discovered "Café security panel." :implication "A gap covered the poisoning window." :status "Confirmed system log."}
   {:id "toxicology" :title "TOXICOLOGY" :sub "Aconite / 19:25-19:28" :body "Poison in drink, not food." :tag "ESTABLISHES METHOD" :color :green :discovered "Lab report at the café." :implication "The drink was the delivery method." :status "Confirmed lab result."}
   {:id "pharmacy_footage" :title "PHARMACY FOOTAGE" :sub "Arin / 19:04 / aconite" :body "Arin bought aconite tincture." :tag "LINKS ARIN TO POISON" :color :rust :discovered "Night-store counter camera." :implication "Arin obtained the poison used." :status "Confirmed footage."}
   {:id "cup_lid" :title "CUP LID" :sub "Cleaned badly" :body "Wiped lid, residue under rim." :tag "PHYSICAL CONTRADICTION" :color :green :discovered "Evidence table at the café." :implication "The cup was wiped to hide residue." :status "Confirmed physical exam."}
   {:id "tape_fiber" :title "BLUE TAPE FIBER" :sub "Fiber beneath lid" :body "Matches tape on Arin's finger." :tag "CONTACT" :color :green :discovered "Lab analysis of the lid." :implication "Points to Arin's contact with the lid." :status "Confirmed fiber match."}
   {:id "draft_email" :title "DRAFT EMAIL" :sub "Eli / scheduled" :body "Article on Arin's review fraud." :tag "MOTIVE" :color :gold :discovered "Eli's apartment desk." :implication "Arin had a reason to stop publication." :status "Confirmed draft."}
   {:id "service_log" :title "SERVICE LOG" :sub "Tag exit 19:25" :body "Borrowed tag opens service door." :tag "OPPORTUNITY" :color :gold :discovered "Service alley reader." :implication "Arin's exit overlaps the death window." :status "Confirmed door log."}
   {:id "mira_statement" :title "MIRA STATEMENT" :sub "Saw Arin at 19:23" :body "Mira saw Arin beside booth." :tag "EXCLUSION" :color :gold :discovered "Confront Mira after the receipt." :implication "Mira's correction shifts suspicion from herself." :status "Claimed follow-up."}
   {:id "delivery_photo" :title "DELIVERY PHOTO" :sub "Dan / 19:19" :body "Photo + tracker exclude Dan." :tag "EXCLUSION" :color :muted :discovered "Alley and tracker review." :implication "Dan was not inside at the critical time." :status "Confirmed image and tracker."}
   {:id "sasha_voicemail" :title "SASHA VOICEMAIL" :sub "Live call 19:20-19:27" :body "Covers death window." :tag "EXCLUSION" :color :muted :discovered "Eli's apartment phone." :implication "Sasha was on a live call outside." :status "Confirmed call log."}
   {:id "panel_log" :title "PANEL LOG" :sub "Jo at till" :body "Till activity excludes Jo." :tag "EXCLUSION" :color :muted :discovered "Café till and panel log." :implication "Jo stayed at the till through the window." :status "Confirmed system log."}
   {:id "jo_statement" :title "JO'S STATEMENT" :sub "Person with cup 19:21" :body "Incomplete account." :tag "MISSING WITNESS" :color :gold :discovered "Interview note at the café." :implication "A familiar person was seen with the cup." :status "Claimed, incomplete."}])

(local statement-ids ["mira_left_1910" "arin_cough_drops" "jo_saw_cup_1921" "jo_identified_mira" "sasha_never_argued" "dan_never_inside" "dan_route_recollection"])
(local location-data
  {:cafe {:name "CAFÉ LANTERN" :note "The room is still open. Nobody is ordering anything."
          :evidence [["receipt_004" "INSPECT RECEIPT #004"] ["camera_log" "CHECK CAMERA LOG"] ["toxicology" "READ TOXICOLOGY"] ["cup_lid" "INSPECT CUP LID"] ["jo_statement" "FILE JO'S ACCOUNT"] ["panel_log" "CHECK PANEL LOG"]]}
   :alley {:name "SERVICE ALLEY" :note "Wet concrete, a staff door, and a route that keeps moving."
           :evidence [["service_log" "CHECK SERVICE-DOOR LOG"] ["delivery_photo" "CHECK BIKE PHOTO"]]}
   :store {:name "NIGHT STORE" :note "The pharmacy counter sees the bottle, the bag, and the time."
           :evidence [["pharmacy_footage" "REVIEW PHARMACY FOOTAGE"]]}
   :apartment {:name "ELI'S APARTMENT" :note "The desk holds the story Eli meant to publish."
               :evidence [["draft_email" "OPEN DRAFT EMAIL"] ["sasha_voicemail" "PLAY SAVED VOICEMAIL"]]}})

(local suspects
  [{:id :mira :name "MIRA VALE" :role "café manager" :tone [0.47 0.35 0.25]}
   {:id :arin :name "ARIN KO" :role "food columnist" :tone [0.35 0.42 0.48]}
   {:id :jo :name "JO BELL" :role "barista" :tone [0.41 0.30 0.35]}
   {:id :sasha :name "SASHA REED" :role "victim's ex" :tone [0.33 0.43 0.34]}
   {:id :dan :name "DAN MOTT" :role "delivery rider" :tone [0.45 0.38 0.30]}])

(local state {:screen :title
              :evidence {}
              :clues 0
              :ending nil
              :accused :arin
              :accusation {:suspect :arin :motive {} :method {} :opportunity {} :evidence {}}
              :accusation_mode :evidence
              :location :cafe
              :toast nil
              :toast_time 0
              :current_person :arin
              :ink_text nil
              :ink_choices []
              :settings {:reducedMotion false}
              :ink_state nil
              :logic_online false
              :contradiction false
              :contradictions []
              :inferences {}
              :inferred_facts []
              :alternatives []
              :proof_data []
              :ending_report nil
              :ink_can_continue false
              :dialogue_page 1
              :inspected_objects {}
              :visited_locations {:cafe true}
              :heard_statements {}
              :conversation_branches []
              :hypotheses []
              :timeline_entries {}
              :presented_evidence {}
              :accusation_attempts []
              :major_flags {}
              :focus 1
              :evidence_page 1
              :evidence_detail nil
              :prev_screen nil
              :contradiction_seen {}
              :timeline_page 1
              :theory {:suspect :arin :motive {} :method {} :opportunity {} :evidence {} :mode :evidence}
              :theory_report_page 1
              :active_proof nil})

(local ui {:shadow 4 :hair 1})

(local console {:paper palette.paper :panel palette.panel :edge palette.line
                :ink palette.ink :muted palette.muted :sodium palette.gold})

(fn clamp [v a b] (math.max a (math.min b v)))

(fn hash2 [a b]
  (math.fmod (+ (* a 374761) (* b 668265) 14407) 2147483647))

(fn set-font [size mono]
  (let [font (or (and mono (. fonts (.. :c size)))
                 (and (not mono) (>= size 22) (. fonts (.. :d size)))
                 (. fonts (.. (if mono :m :s) size)) (. fonts :s18))
        filter :linear]
    ;; Text must survive fractional window scaling; only character art is crunchy.
    (font:setFilter filter filter)
    (love.graphics.setFont font)))

(fn text! [s x y w align color]
  (love.graphics.setColor (or color palette.ink))
  (love.graphics.printf s x y (or w 400) (or align :left)))

;; dumb primitives - flat, 1px, no shadows, 2000s low-bit
(fn shadow! [x y w h] nil)
(fn shadow-soft! [x y w h] nil)
(fn panel-fill! [x y w h fill]
  (love.graphics.setColor (or fill palette.panel))
  (love.graphics.rectangle :fill x y w h))

(fn hairline! [x1 y1 x2 y2 col]
  (love.graphics.setColor (or col palette.line))
  (love.graphics.setLineWidth 1)
  (love.graphics.line x1 y1 x2 y2))

(fn ruled! [x y w]
  (hairline! x y (+ x w) y palette.line)
  (hairline! x (+ y 3) (+ x w) (+ y 3) [0.35 0.36 0.34 0.35]))

(fn clipped-frame! [x y w h stroke]
  (when stroke
    (love.graphics.setColor stroke)
    (love.graphics.setLineWidth 1)
    (love.graphics.rectangle :line x y w h)))

(fn grain! [x y w h seed] nil)

(fn rect! [x y w h fill stroke]
  (panel-fill! x y w h fill)
  (when stroke
    (clipped-frame! x y w h stroke)
    (when (and (> w 100) (> h 60))
      (clipped-frame! (+ x 4) (+ y 4) (- w 8) (- h 8) [0.20 0.23 0.23])
      (hairline! x y (+ x (math.min w 64)) y palette.gold))))

(fn ledger-rect! [x y w h fill stroke]
  (panel-fill! x y w h (or fill palette.panel))
  (when stroke (clipped-frame! x y w h (or stroke palette.line))))

(fn transcript-rect! [x y w h fill stroke]
  (panel-fill! x y w h (or fill palette.panel))
  (when stroke (clipped-frame! x y w h stroke)))

(fn pin-rect! [x y w h fill stroke]
  (panel-fill! x y w h (or fill palette.paper-light))
  (when stroke (clipped-frame! x y w h stroke)))

(local district-anchors {:cafe [99 79] :apartment [146 23] :store [207 105] :alley [134 96]})

(fn district-art! [x y w h location]
  (panel-fill! x y w h palette.paper-light)
  (when art.district
    (love.graphics.setColor 1 1 1 1)
    (love.graphics.draw art.district x y 0 (/ w 320) (/ h 224)))
  (when (and location (. district-anchors location))
    (let [point (. district-anchors location)
          px (+ x (* (. point 1) (/ w 320))) py (+ y (* (. point 2) (/ h 224)))]
      (rect! (- px 4) (- py 4) 8 8 palette.gold palette.ink))))

(fn dotted-line! [x1 y1 x2 y2]
  (let [dx (- x2 x1) dy (- y2 y1)
        len (math.sqrt (+ (* dx dx) (* dy dy)))
        ux (/ dx len) uy (/ dy len)]
    (for [distance 0 len 10]
      (let [finish (math.min len (+ distance 5))]
        (love.graphics.line (+ x1 (* ux distance))
                            (+ y1 (* uy distance))
                            (+ x1 (* ux finish))
                            (+ y1 (* uy finish)))))))

(fn dotted-rect! [x y w h]
  (dotted-line! x y (+ x w) y)
  (dotted-line! (+ x w) y (+ x w) (+ y h))
  (dotted-line! (+ x w) (+ y h) x (+ y h))
  (dotted-line! x (+ y h) x y))

(fn stamp! [label x y w h col]
  (love.graphics.setColor col)
  (love.graphics.setLineWidth 1)
  (love.graphics.rectangle :line x y w h)
  (love.graphics.rectangle :line (+ x 2) (+ y 2) (- w 4) (- h 4))
  (set-font 10 true)
  (text! label (+ x 4) (+ y 6) (- w 8) :center col))

(fn scanlines! []
  (love.graphics.setColor [1 1 1 0.045])
  (love.graphics.setLineWidth 1)
  (for [y 0 H 2]
    (love.graphics.line 0 y W y))
  (love.graphics.setColor [0 0 0 0.25])
   (love.graphics.rectangle :line 0 0 W H)
   (love.graphics.rectangle :line 2 2 (- W 4) (- H 4)))

(fn ambiance! []
  (let [warm [0.54 0.53 0.46 0.11]
        cool [0.68 0.68 0.64 0.055]]
    (love.graphics.setColor warm)
    (for [i 1 8]
      (let [seed (math.abs (hash2 i 97))
            y (+ 72 (math.fmod seed 580))
            x (+ 12 (math.fmod (math.abs (hash2 i 131)) 26))]
        (love.graphics.rectangle :fill x y 2 2)
        (love.graphics.rectangle :fill (- W x 4) y 2 2)))
    (love.graphics.setColor cool)
    (love.graphics.line 18 62 42 62)
    (love.graphics.line (- W 42) 62 (- W 18) 62)
    (love.graphics.line 18 (- H 30) 42 (- H 30))
    (love.graphics.line (- W 42) (- H 30) (- W 18) (- H 30))))

(fn cafe-vignette! [x y w h]
  (when art.cafe_composed
    (let [image art.cafe_composed
          iw (image:getWidth)
          ih (image:getHeight)
          crop-x 68
          crop-y 45
          crop-w 1022
          crop-h 673
          floor-h (math.max 30 (math.floor (* h 0.24)))
          image-h (- h floor-h)
          floor-y (+ y image-h)
          quad (love.graphics.newQuad crop-x crop-y crop-w crop-h iw ih)]
      (love.graphics.setColor [0.045 0.045 0.043])
      (love.graphics.rectangle :fill x y w h)
      (love.graphics.setColor [1 1 1 0.78])
      (love.graphics.draw image quad x y 0 (/ w crop-w) (/ image-h crop-h))
      (love.graphics.setColor [0.075 0.075 0.07])
      (love.graphics.rectangle :fill x floor-y w floor-h)
      ;; The source still has furniture feet above its lower crop. Let them meet
      ;; the new floor instead of leaving a visible gap beneath the room.
      (love.graphics.setColor [0.02 0.02 0.018 0.8])
      (love.graphics.rectangle :fill (+ x (* w 0.06)) (- floor-y 2) (* w 0.38) 5)
      (love.graphics.rectangle :fill (+ x (* w 0.39)) (- floor-y 2) (* w 0.2) 5)
      (love.graphics.rectangle :fill (+ x (* w 0.77)) (- floor-y 2) (* w 0.18) 5)
      (love.graphics.setColor [0.12 0.12 0.11 0.92])
      (love.graphics.rectangle :fill (+ x (* w 0.08)) (+ y (* image-h 0.07)) 5 (- floor-y (+ y (* image-h 0.07))))
      (love.graphics.rectangle :fill (- (+ x (* w 0.92)) 5) (+ y (* image-h 0.07)) 5 (- floor-y (+ y (* image-h 0.07))))
      (love.graphics.setColor [0.54 0.53 0.46 0.48])
      (love.graphics.line (+ x (* w 0.08)) (+ y (* image-h 0.07)) (+ x (* w 0.92)) (+ y (* image-h 0.07)))
      (love.graphics.rectangle :fill (+ x (* w 0.06)) (- floor-y 4) (* w 0.08) 6)
      (love.graphics.rectangle :fill (+ x (* w 0.86)) (- floor-y 4) (* w 0.08) 6)
      (love.graphics.setLineWidth 2)
      (love.graphics.line (+ x (* w 0.23)) (- floor-y (* floor-h 0.45)) (+ x (* w 0.18)) (+ floor-y 1))
      (love.graphics.line (+ x (* w 0.3)) (- floor-y (* floor-h 0.4)) (+ x (* w 0.36)) (+ floor-y 1))
      (love.graphics.line (+ x (* w 0.43)) (- floor-y (* floor-h 0.35)) (+ x (* w 0.4)) (+ floor-y 1))
      (love.graphics.setLineWidth 1)
      (love.graphics.setColor [0.54 0.53 0.46 0.42])
      (love.graphics.setLineWidth 1)
      (love.graphics.line x floor-y (+ x w) floor-y)
      (love.graphics.line x (+ floor-y (* floor-h 0.48)) (+ x w) (+ floor-y (* floor-h 0.48)))
      (love.graphics.line x (+ y h -1) (+ x w) (+ y h -1))
      (love.graphics.setColor [0.45 0.45 0.43 0.5])
      (love.graphics.line (+ x (* w 0.24)) floor-y (+ x (* w 0.08)) (+ y h -1))
      (love.graphics.line (+ x (* w 0.62)) floor-y (+ x (* w 0.46)) (+ y h -1))
      (love.graphics.line (+ x (* w 0.96)) floor-y (+ x (* w 0.8)) (+ y h -1))
      (love.graphics.setColor [0 0 0 0.22])
      (love.graphics.rectangle :fill x y w 4))))

(fn exhibit-tag! [x y label]
  (love.graphics.setColor [0.06 0.06 0.06])
  (love.graphics.rectangle :fill x y 150 20)
  (love.graphics.setColor palette.gold)
  (love.graphics.setLineWidth 1)
  (love.graphics.rectangle :line x y 150 20)
  (love.graphics.circle :line (+ x 9) (+ y 10) 3)
  (set-font 10 true)
  (text! label (+ x 18) (+ y 5) 126 :left palette.gold))

(fn scene-sketch! [x y s marker]
  (let [stroke palette.line
        dim palette.line-warm
        fx (fn [v] (+ x (* v s)))
        fy (fn [v] (+ y (* v s)))]
    (love.graphics.setLineWidth 1)
    (panel-fill! x y (* 200 s) (* 140 s) palette.paper-light)
    (for [row 0 7]
      (hairline! x (fy (* row 20)) (fx 200) (fy (* row 20)) [0.17 0.20 0.20]))
    (for [col 0 10]
      (hairline! (fx (* col 20)) y (fx (* col 20)) (fy 140) [0.17 0.20 0.20]))
    (panel-fill! (fx 12) (fy 16) (* 92 s) (* 18 s) palette.line-warm)
    (panel-fill! (fx 138) (fy 16) (* 50 s) (* 30 s) palette.panel-cool)
    (panel-fill! (fx 138) (fy 92) (* 50 s) (* 30 s) palette.panel-cool)
    (love.graphics.setColor stroke)
    (love.graphics.rectangle :line (fx 0) (fy 0) (* 200 s) (* 140 s))
    (love.graphics.setColor [0.05 0.05 0.05])
    (love.graphics.rectangle :fill (fx 8) (fy 128) (* 26 s) (* 12 s))
    (love.graphics.setColor stroke)
    (love.graphics.line (fx 8) (fy 128) (fx 22) (fy 114))
    (love.graphics.rectangle :line (fx 12) (fy 16) (* 92 s) (* 18 s))
    (love.graphics.setColor dim)
    (love.graphics.line (fx 16) (fy 25) (fx 100) (fy 25))
    (love.graphics.setColor stroke)
    (love.graphics.rectangle :line (fx 138) (fy 16) (* 50 s) (* 30 s))
    (love.graphics.rectangle :line (fx 138) (fy 92) (* 50 s) (* 30 s))
    (love.graphics.circle :line (fx 60) (fy 70) (* 14 s))
    (love.graphics.circle :line (fx 100) (fy 100) (* 12 s))
    (when (= marker :register)
      (love.graphics.setColor palette.gold)
      (love.graphics.circle :fill (fx 60) (fy 25) (* 4 s))
      (set-font 10 true)
      (text! "1" (fx 68) (fy 19) 40 :left palette.gold))
    (love.graphics.setColor dim)
    (love.graphics.line (fx 0) (fy 152) (fx 200) (fy 152))))

(fn conflict-diagram! [x y]
  (rect! x y 222 104 palette.paper-light palette.line)
  (rect! (+ x 338) y 222 104 palette.paper-light palette.line)
  (set-font 12 true)
  (text! "STATEMENT / MIRA" (+ x 12) (+ y 12) 198 :left palette.muted)
  (text! "RECEIPT / REGISTER" (+ x 350) (+ y 12) 198 :left palette.gold)
  (set-font 32 false)
  (text! "19:10" (+ x 12) (+ y 38) 198 :left palette.ink)
  (text! "19:22" (+ x 350) (+ y 38) 198 :left palette.ink)
  (set-font 12 true)
  (text! "Claimed departure" (+ x 12) (+ y 78) 198 :left palette.muted)
  (text! "In-person purchase" (+ x 350) (+ y 78) 198 :left palette.muted)
  (hairline! (+ x 222) (+ y 50) (+ x 265) (+ y 50) palette.rust)
  (hairline! (+ x 295) (+ y 50) (+ x 338) (+ y 50) palette.rust)
  (hairline! (+ x 272) (+ y 42) (+ x 288) (+ y 58) palette.rust)
  (hairline! (+ x 288) (+ y 42) (+ x 272) (+ y 58) palette.rust)
  (set-font 11 true) (text! "CONFLICT" (+ x 230) (+ y 76) 100 :center palette.rust))

(fn case-rule! [x y w]
  (ruled! x y w))
(fn has? [id] (not= (. state.evidence id) nil))

(fn suspect-note [id]
  (if (= id :mira) (if (and (has? "receipt_004") (. state.heard_statements "mira_left_1910")) "Said 19:10. Register says 19:22. I kept both." "Ran the late shift. Says she left early."
      )
      (= id :arin) (if (has? "pharmacy_footage") "Bought aconite at 19:04. Camera saw the bottle." "Food columnist. Same table every Tuesday.")
      (= id :jo) "On till all evening. Saw a familiar hand with the cup, not the face."
      (= id :sasha) "Came after close to get her key. Did not stay long."
      (= id :dan) "Ran the alley route that night. Timing has to be checked."
      ""))

(fn toast! [msg]
  (tset state :toast msg)
  (tset state :toast_time 3))

(fn copy-table [source]
  (let [out {}]
    (each [k v (pairs (or source {}))] (tset out k v))
    out))

(fn known-evidence [extra]
  (let [out []]
    (each [_ item (ipairs evidence-data)]
      (when (or (has? item.id) (= item.id extra)) (table.insert out item.id)))
    out))

(fn known-statements [extra]
  (let [out []]
    (each [_ id (ipairs statement-ids)]
      (when (or (. state.heard_statements id) (= id extra)) (table.insert out id)))
    out))

(fn logic-request [operation payload evidence-override statement-extra]
  (let [body (copy-table payload)]
    (tset body :known_evidence (or evidence-override (known-evidence)))
    (tset body :known_statements (known-statements statement-extra))
    (prolog.request operation body)))

(fn absorb-logic! [result]
  (when (and result result.ok)
    (tset state :logic_online true)
    (when result.contradictions
      (tset state :contradictions result.contradictions)
      (tset state :contradiction (> (# result.contradictions) 0)))
    (when result.inferences
      (tset state :inferred_facts result.inferences)
      (tset state :inferences {})
      (each [_ id (ipairs result.inferences)]
        (tset state.inferences id true)
        (tset state.timeline_entries id true)))
    (when result.inference_details (tset state :proof_data result.inference_details))
    (when result.knowledge
      (tset state :hypotheses (or result.knowledge.hypothesized []))
      (tset state.major_flags :unique_proof (> (# (or result.knowledge.proven [])) 0)))
    true))

(fn maybe-trigger-contradiction! []
  (when (and (has? "receipt_004") (. state.heard_statements "mira_left_1910"))
    (when (not (. state.contradiction_seen :receipt_mira))
      (tset state.contradiction_seen :receipt_mira true)
      (when (not= state.screen :contradiction)
        (tset state :prev_screen state.screen)
        (tset state :screen :contradiction)))))

(fn logic-sync []
  (let [snapshot (logic-request :query_state {})]
    (if (absorb-logic! snapshot)
      (let [alternatives (logic-request :possible_alternatives {})]
        (when (and alternatives alternatives.ok)
          (tset state :alternatives (or alternatives.alternatives [])))
        (maybe-trigger-contradiction!)
        snapshot)
      (do (tset state :logic_online false) snapshot))))

(fn logic-accusation [payload]
  (logic-request :accusation payload (or payload.evidence [])))

;; expose for tests
(tset _G :ondacase_state state)
(tset _G :ondacase_layout layout)
(tset _G :ondacase_save save-mod)

(fn hover? [entry]
  (or (= hover-index entry.action) (= (. focusable focus-index) entry.action)))

(fn add-button [label x y w h action kind]
  (let [entry {:x x :y y :w w :h h :action action :label label :kind kind}
        ordinal (+ (# focusable) 1)]
    (table.insert buttons entry)
    (table.insert focusable action)
    (let [focused (= focus-index ordinal)
          ;; Actions are rebuilt each draw, so hover follows their stable rectangles.
          hov (and (>= mouse-lx x) (<= mouse-lx (+ x w)) (>= mouse-ly y) (<= mouse-ly (+ y h)))
          cursor (>= h 26)
          selected (or focused hov)
          bg (if focused console.sodium hov [0.19 0.22 0.22] console.panel)
          fg (if focused console.paper (= kind :accent) palette.gold console.ink)
          stroke (if (or selected (= kind :accent)) console.sodium console.edge)]
      (love.graphics.setColor bg)
      (love.graphics.rectangle :fill x y w h)
      (love.graphics.setColor stroke)
      (love.graphics.setLineWidth 1)
      (love.graphics.rectangle :line x y w h)
      (when (and cursor focused)
        (love.graphics.setColor console.paper)
        (love.graphics.line (+ x 7) (+ y (/ h 2) -4) (+ x 11) (+ y (/ h 2)) (+ x 7) (+ y (/ h 2) 4)))
      (set-font (if cursor 13 11) true)
      (let [raw (tostring label)
            inset (if cursor 18 8)
            max-width (- w inset 8)
            initial-font (love.graphics.getFont)
            font (if (> (initial-font:getWidth raw) max-width)
                   (do (set-font 10 true) (love.graphics.getFont))
                   initial-font)
            suffix "..."
            shown (if (<= (font:getWidth raw) max-width)
                    raw
                    (do
                      (var clipped raw)
                      (while (and (> (string.len clipped) 0)
                                  (> (font:getWidth (.. clipped suffix)) max-width))
                        (set clipped (string.sub clipped 1 (- (string.len clipped) 1))))
                      (.. clipped suffix)))
            line-height (font:getHeight)
            text-y (+ y (math.max 2 (/ (- h line-height) 2)))]
        (text! shown (+ x inset) text-y max-width :left fg)))))

(fn update-hover! [sx sy]
  (let [calc (layout.calc (love.graphics.getDimensions) (select 2 (love.graphics.getDimensions)))
        lx (/ (- sx calc.ox) calc.scale)
        ly (/ (- sy calc.oy) calc.scale)]
    (set mouse-lx lx) (set mouse-ly ly)
    (if (not (layout.in-logical? lx ly))
      (set hover-index nil)
      (do
        (var found nil)
        (each [_ b (ipairs buttons)]
          (when (and (>= lx b.x) (<= lx (+ b.x b.w)) (>= ly b.y) (<= ly (+ b.y b.h)))
            (set found b.action)))
        (set hover-index found)))))

(fn add! [id]
  (tset state.inspected_objects id true)
  (when (not (has? id))
    (let [result (logic-request :discover_evidence {:evidence id} (known-evidence id))]
      (if (and result result.ok)
        (do
          (tset state.evidence id true)
          (tset state :clues (+ state.clues 1))
          (logic-sync)
          (toast! "Evidence added to your file."))
        (toast! "Evidence is not available yet.")))))

(fn record-statement! [id]
  (when (not (. state.heard_statements id))
    (let [result (logic-request :record_statement {:statement id} nil id)]
      (if (and result result.ok)
        (do
          (tset state.heard_statements id true)
          (logic-sync))
        (toast! "The statement could not be filed.")))))

(fn known-ink-vars []
  (let [vars {}]
    (each [_ item (ipairs evidence-data)] (tset vars item.id (has? item.id)))
    vars))

(fn hear-from-text! [text]
  (when (= (type text) :string)
    (when (string.find text "left at ten past seven" 1 true) (record-statement! "mira_left_1910"))
    (when (string.find text "bought cough drops" 1 true) (record-statement! "arin_cough_drops"))
    (when (string.find text "saw somebody with the cup" 1 true) (record-statement! "jo_saw_cup_1921"))
    (when (string.find text "thought it was Mira" 1 true) (record-statement! "jo_identified_mira"))
    (when (string.find text "never raised my voice" 1 true) (record-statement! "sasha_never_argued"))
    (when (string.find text "never went inside" 1 true) (record-statement! "dan_never_inside"))))

(fn selected-list [selected-set]
  (let [selected []]
    (each [_ item (ipairs evidence-data)]
      (when (. selected-set item.id) (table.insert selected item.id)))
    selected))

(fn accusation-payload [suspect]
  (let [selected (selected-list state.accusation.evidence)]
    {:suspect (or suspect state.accused)
     :motive (selected-list state.accusation.motive)
     :method (selected-list state.accusation.method)
     :opportunity (selected-list state.accusation.opportunity)
     :evidence selected}))

(fn finish-accusation! [payload result]
  (when (and result result.ok result.result)
    (table.insert state.accusation_attempts {:payload payload :result result.result})
    (tset state :ending result.result.ending)
    (tset state :ending_report result.result)
    (tset state.major_flags :submitted true)
    (tset state :screen :ending)))

(fn dispatch-ink-callback! [callback]
  (let [name callback.name arg (and callback.args (. callback.args 1))]
    (if (= name "discover_evidence") (add! arg)
        (= name "record_statement") (record-statement! arg)
        (= name "evaluate_accusation")
        (let [payload (accusation-payload arg)
              result (logic-accusation payload)]
          (finish-accusation! payload result))
        (toast! "Ink requested an unsupported operation."))))

(fn apply-ink! [result]
  (if (and result result.ok)
    (do
      (tset state :ink_state result.state)
      (tset state :ink_text (or result.text (and result.lines (table.concat result.lines "\n\n")) ""))
      (tset state :ink_choices (or result.choices []))
      (tset state :ink_can_continue (= result.can_continue true))
      (tset state :dialogue_page 1)
      (hear-from-text! state.ink_text)
      (each [_ callback (ipairs (or result.callbacks []))] (dispatch-ink-callback! callback)))
    (toast! (or (and result result.error) "Dialogue runtime unavailable."))))

(fn ink-request! [operation payload]
  (let [body (copy-table payload)]
    (tset body :variables (known-ink-vars))
    (when (and state.ink_state (not= operation :start)) (tset body :state state.ink_state))
    (let [result (ink.request operation body)]
      (apply-ink! result)
      result)))

(fn open-interview! [person]
  (tset state :current_person person)
  (tset state :screen :dialogue)
  ;; Six navigation tabs precede the first conversation action.
  (set focus-index 7)
  (table.insert state.conversation_branches (.. "goto:" (tostring person)))
  (ink-request! :goto {:knot (tostring person)}))

(fn continue-interview! []
  (table.insert state.conversation_branches "continue")
  (ink-request! :continue {}))

(fn choose-interview! [choice]
  (table.insert state.conversation_branches (.. "choice:" (tostring state.current_person) ":" (tostring choice.index)))
  (when (and (= state.current_person :dan)
             (or (= choice.text "Ask about the route gap") (= choice.text "Ask him to walk the route again")))
    (record-statement! "dan_route_recollection"))
  (ink-request! :choose {:index choice.index}))

(fn topbar! [label sub]
  (love.graphics.setColor palette.paper)
  (love.graphics.rectangle :fill 0 0 W 36)
  (love.graphics.setColor palette.line)
  (love.graphics.line 0 36 W 36)
   (love.graphics.setColor palette.gold)
   (love.graphics.rectangle :fill 20 13 4 4)
   (set-font 11 true) (text! "ONDACASE 001" 30 11 150 :left palette.gold)
  (set-font 12 true) (text! label 160 11 500 :left palette.ink)
  (let [badge (string.format "%02d FILED" state.clues)]
    (set-font 11 true) (text! badge (- W 100) 11 80 :right palette.gold)))

(fn cafe-art! [alpha]
  ;; Prefer photographic backdrop for now; composed cafe is a vendored free prop sheet
  ;; used as a subtle dressing fallback when the photo is absent to keep the build distributable.
  (if art.cafe
    (do
      (love.graphics.setColor 1 1 1 (or alpha 1))
      (love.graphics.draw art.cafe 0 0 0 (/ W (art.cafe:getWidth)) (/ H (art.cafe:getHeight)))
      (love.graphics.setColor 1 1 1 1))
    (when art.cafe_composed
      (love.graphics.setColor 1 1 1 (* 0.42 (or alpha 1)))
      (love.graphics.draw art.cafe_composed 0 0 0 (/ W (art.cafe_composed:getWidth)) (/ H (art.cafe_composed:getHeight)))
      (love.graphics.setColor 1 1 1 1))))

(fn location-art! [loc alpha]
  (if (= loc :cafe)
    (cafe-art! (or alpha 0.56))
    (when art.locations
      (love.graphics.setColor 1 1 1 (or alpha 0.92))
      (let [sw (art.locations:getWidth) sh (art.locations:getHeight)
            panel-w (/ sw 3)
            idx (if (= loc :alley) 0 (if (= loc :store) 1 (if (= loc :apartment) 2 0)))
            quad (love.graphics.newQuad (* idx panel-w) 0 panel-w sh sw sh)]
        (love.graphics.draw art.locations quad 0 0 0 (/ W panel-w) (/ H sh)))
      (love.graphics.setColor 1 1 1 1))))

(fn suspect-portrait! [person x y w h full-bleed]
  (let [indiv (and art.portraits (. art.portraits person))
        crop (and (<= h 64) art.portrait_crops (. art.portrait_crops person))]
    (if indiv
      (do
        (when (not full-bleed) (rect! x y w h [0.18 0.17 0.16] palette.line))
        (let [sw (if crop 112 (indiv:getWidth)) sh (if crop 112 (indiv:getHeight))
              padding (if full-bleed 0 crop 4 12)
              scale (math.min (/ (- w padding) sw) (/ (- h padding) sh))
              dw (* sw scale) dh (* sh scale)
              dx (+ x (/ (- w dw) 2)) dy (+ y (/ (- h dh) 2))]
          (love.graphics.setColor 1 1 1 1)
          (if crop (love.graphics.draw indiv crop dx dy 0 scale scale)
                   (love.graphics.draw indiv dx dy 0 scale scale))
          (love.graphics.setColor 1 1 1 1)))
      (if art.suspects
        (do
          (rect! x y w h [0.18 0.17 0.16] palette.line)
          (let [order {:mira 0 :arin 1 :jo 2 :sasha 3 :dan 4}
                idx (or (. order person) 0)
                sw (art.suspects:getWidth) sh (art.suspects:getHeight)
                quad-w (/ sw 5) quad-h sh
                scale (math.min (/ (- w 12) quad-w) (/ (- h 12) quad-h))
                dw (* quad-w scale) dh (* quad-h scale)
                dx (+ x (/ (- w dw) 2)) dy (+ y (/ (- h dh) 2))]
            (love.graphics.setColor 1 1 1 1)
            (let [quad (love.graphics.newQuad (* idx quad-w) 0 quad-w quad-h sw sh)]
              (love.graphics.draw art.suspects quad dx dy 0 scale scale))
            (love.graphics.setColor 1 1 1 1)))
        ;; procedural fallback - paper silhouette with initials
        (do
          (rect! x y w h [0.16 0.17 0.17] palette.line)
          (let [init (string.upper (string.sub (tostring person) 1 2))]
            (set-font 48 false) (text! init (+ x 10) (+ y 90) (- w 20) :center palette.muted)
            (set-font 11 true) (text! (string.upper (tostring person)) (+ x 10) (+ y 185) (- w 20) :center palette.gold)
            (set-font 10 true) (text! "CONTACT PRINT" (+ x 10) (+ y 210) (- w 20) :center palette.muted)))))))

(fn nav! []
  (add-button "FILE" 20 36 60 20 (fn [] (tset state :screen :evidence)))
  (add-button "BOARD" 85 36 60 20 (fn [] (tset state :screen :board)))
  (add-button "TIME" 150 36 60 20 (fn [] (tset state :screen :timeline)))
  (add-button "ACCUSE" 215 36 60 20 (fn [] (tset state :screen :accuse) ) :accent)
  (add-button "MENU" (- W 70) 36 60 20 (fn [] (tset state :screen :pause)))
  (add-button "MAP" 280 36 60 20 (fn [] (tset state :screen :investigate)))
  (let [tab (or (. {:evidence 20 :evidence_detail 20 :board 85 :proof 85 :theory 85
                    :timeline 150 :accuse 215 :investigate 280 :location 280} state.screen) nil)]
    (when tab (hairline! tab 60 (+ tab 60) 60 palette.gold))))

(fn save-state! []
  (let [s (save-mod.serialize state)]
    (if s
      (do (love.filesystem.write "save.json" s)
          (toast! "Case record saved."))
      (toast! "The case record is too large to save."))))

(fn load-state! []
  (when (not (love.filesystem.getInfo "save.json"))
    (toast! "No case record found.")
    (lua "return"))
  (let [raw (love.filesystem.read "save.json")]
    (let [parsed (save-mod.parse raw)]
      (if parsed
        (do
          (tset state :screen (or parsed.screen :investigate))
          (tset state :evidence (or parsed.evidence {}))
          (tset state :accused (or parsed.accused :arin))
          (tset state :accusation (or parsed.accusation {:suspect :arin}))
          (tset state :settings (or parsed.settings {:reducedMotion false}))
          (tset state :ink_state parsed.ink_state)
          (tset state :ending parsed.ending)
          (tset state :ending_report parsed.ending_report)
          (tset state :current_person parsed.current_person)
          (tset state :inspected_objects parsed.inspected_objects)
           (tset state :visited_locations parsed.visited_locations)
           (tset state :heard_statements parsed.heard_statements)
           (tset state :inferences (or parsed.inferences []))
           (tset state :contradictions parsed.contradictions)
           (tset state :contradiction (if (= parsed.contradiction true) true false))
          (tset state :inferred_facts parsed.inferred_facts)
          (tset state :conversation_branches parsed.conversation_branches)
          (tset state :hypotheses parsed.hypotheses)
          (tset state :timeline_entries parsed.timeline_entries)
          (tset state :presented_evidence parsed.presented_evidence)
          (tset state :accusation_attempts parsed.accusation_attempts)
          (tset state :major_flags parsed.major_flags)
          (tset state :alternatives parsed.alternatives)
          (tset state :proof_data parsed.proof_data)
          (tset state :evidence_page (or parsed.evidence_page 1))
          (tset state :timeline_page (or parsed.timeline_page 1))
          (tset state :ink_text parsed.ink_text)
          (tset state :ink_choices (or parsed.ink_choices []))
          (tset state :ink_can_continue (or parsed.ink_can_continue false))
          (tset state :dialogue_page (or parsed.dialogue_page 1))
          (tset state :evidence_detail parsed.evidence_detail)
          (tset state :prev_screen parsed.prev_screen)
          (tset state :location (or parsed.location :cafe))
           (tset state :contradiction_seen (or parsed.contradiction_seen {}))
           (tset state :theory (or parsed.theory {:suspect :arin :motive {} :method {} :opportunity {} :evidence {} :mode :evidence}))
           (tset state :theory_report_page 1)
           (tset state :active_proof parsed.active_proof)
           (var c 0) (each [_ _ (pairs state.evidence)] (set c (+ c 1))) (tset state :clues c)
           (logic-sync)
          (toast! "Case record reopened."))
        (do
          (tset state :evidence {}) (tset state :clues 0) (tset state :screen :title)
          (toast! "Save was damaged. Started fresh."))))))

(fn draw-title []
  (panel-fill! 0 0 W H palette.paper)
  (district-art! 64 228 592 414.4)
  (set-font 13 true) (text! "ONDACASE / CASE 001" 60 40 500 :left palette.gold)
  (set-font 42 false) (text! "The iced americano at 7:22" 60 72 620 :left palette.ink)
  (set-font 13 true) (text! "I was called at 19:42. The cup was still warm." 60 137 600 :left palette.muted)
  (add-button "Open file" 60 180 130 32 (fn [] (tset state :screen :case_select) ) :accent)
  (add-button "Continue" 200 180 110 32 load-state!)
  (add-button "Settings" 320 180 90 32 (fn [] (tset state :screen :settings)))
  (set-font 12 true) (text! "CAFE LANTERN / 19:22" 64 622 500 :left palette.gold))

(fn draw-case-select []
  (panel-fill! 0 0 W H palette.paper)
  (love.graphics.setColor palette.rust) (love.graphics.rectangle :fill 0 0 10 H)
  (set-font 12 true) (text! "Files on my desk" 72 72 300 :left palette.gold)
  (set-font 42 false) (text! "One file tonight" 72 112 500 :left palette.ink)
  (set-font 14 false) (text! "One is enough when it is not yet closed." 74 180 500 :left palette.muted)
    (rect! 74 245 572 220 palette.panel palette.line)
  (set-font 11 true) (text! "File 001 / open" 108 280 250 :left palette.gold)
  (set-font 29 false) (text! "The iced americano at 7:22" 108 318 560 :left palette.ink)
  (set-font 13 false) (text! "Cafe Lantern. Five names. One cup that should not have killed anyone." 108 368 560 :left palette.muted)
  (add-button "Open it" 108 500 160 44 (fn [] (tset state :screen :investigate) ) :accent)
  (set-font 12 true) (text! "One case. Five accounts to check." 74 590 570 :left palette.muted))

(fn visit-location! [location]
  (tset state :location location)
  (tset state :location_view 1)
  (tset state.visited_locations location true)
  (tset state :screen :location))

(fn draw-investigate []
  (topbar! "AREA MAP" "FOUR LOCATIONS")
  (nav!)
  (set-font 13 true) (text! "Select a location" 40 82 400 :left palette.ink)
  (set-font 11 true) (text! "SCHEMATIC / NOT TO SCALE" 380 84 300 :right palette.muted)
  (district-art! 40 112 640 448)
  (clipped-frame! 40 112 640 448 palette.line)
  ;; Anchor pixels are projected by tools/render-map.py, then displayed at 2x.
  (when (not art.district)
    (set-font 13 true) (text! "Map image unavailable. Location controls still work." 60 520 600 :left palette.muted))
  (each [_ loc (ipairs [{:id :cafe :label "Cafe Lantern" :bx 52 :by 312}
                        {:id :alley :label "Service alley" :bx 104 :by 398}
                        {:id :store :label "Night store" :bx 496 :by 356}
                        {:id :apartment :label "Eli's apartment" :bx 450 :by 140}])]
    (let [point (. district-anchors loc.id)
          ax (+ 40 (* (. point 1) 2)) ay (+ 112 (* (. point 2) 2))
          current (= state.location loc.id)]
      (hairline! ax ay ax (+ loc.by 15) palette.gold)
      (hairline! ax (+ loc.by 15) loc.bx (+ loc.by 15) palette.gold)
      (rect! (- ax 3) (- ay 3) 6 6 palette.gold)
      (add-button loc.label loc.bx loc.by 168 30 (fn [] (visit-location! loc.id)) (if current :accent nil))))
  (set-font 12 true) (text! "Places to visit, not a reconstruction of the crime." 40 580 640 :left palette.muted)
  (add-button "People" 40 608 140 34 (fn [] (tset state :screen :people)) :accent)
  (add-button "Evidence file" 192 608 156 34 (fn [] (tset state :screen :evidence))))

(local evidence-per-page 6)

(fn filtered-evidence []
  (let [out []]
    (each [_ e (ipairs evidence-data)]
      (when (has? e.id) (table.insert out e)))
    out))

(fn draw-evidence []
  (topbar! "FILE" "WHAT I FILED")
  (nav!)
   (rect! 60 90 600 460 palette.panel palette.line)
  (let [all (filtered-evidence)
        total (# all)
        pages (math.max 1 (math.ceil (/ (math.max total 1) evidence-per-page)))
        page (math.max 1 (math.min (or state.evidence_page 1) pages))
        start (+ 1 (* (- page 1) evidence-per-page))
        finish (math.min total (+ start evidence-per-page -1))]
    (tset state :evidence_page page)
    (if (= total 0)
      (do
        (set-font 12 true) (text! "Nothing filed yet." 80 120 400 :left palette.ink)
        (set-font 11 true) (text! "Go look around." 80 140 400 :left palette.muted))
      (for [idx start finish]
          (let [e (. all idx) y (+ 110 (* (- idx start) 58))]
            (rect! 74 (- y 4) 572 50 palette.paper-light)
          (set-font 12 true) (text! e.title 80 y 300 :left palette.ink)
          (set-font 11 true) (text! e.sub 80 (+ y 16) 300 :left palette.muted)
            (set-font 11 true) (text! e.tag 390 (+ y 4) 156 :left palette.gold)
           (add-button "Open" 560 y 70 30 (fn [] (tset state :evidence_detail e.id) (tset state :screen :evidence_detail))))))
     (when (> pages 1)
       (set-font 11 true) (text! (string.format "%d/%d" page pages) 330 500 60 :center palette.muted)
       (add-button "Prev" 250 495 70 26 (fn [] (tset state :evidence_page (math.max 1 (- page 1)))))
       (add-button "Next" 410 495 70 26 (fn [] (tset state :evidence_page (math.min pages (+ page 1)))))))
  (add-button "Back" 60 580 100 30 (fn [] (tset state :screen :investigate)))
  (when (. state.inferences "mira_departure_conflict")
     (add-button "Why Mira fails" 170 580 140 30 (fn [] (tset state :active_proof "mira_departure_conflict") (tset state :screen :proof) ) :accent)))

(fn draw-evidence-detail []
  (let [detail-id state.evidence_detail
        found (do (var f nil) (each [_ e (ipairs evidence-data)] (when (= e.id detail-id) (set f e))) f)]
    (topbar! "FILE" (or (and found found.title) "RECORD"))
    (nav!)
    (if (not found)
      (do
        (set-font 12 true) (text! "No record." 60 140 400 :left palette.ink)
        (add-button "Back" 60 170 100 30 (fn [] (tset state :screen :evidence))))
      (do
         (rect! 60 110 600 420 palette.panel palette.line)
         (set-font 14 true) (text! found.title 80 130 560 :left palette.ink)
         (set-font 11 true) (text! found.sub 80 150 560 :left palette.gold)
         (set-font 14 false) (text! found.body 80 175 560 :left palette.muted)
         (set-font 11 true) (text! (.. "Found: " found.discovered) 80 220 560 :left palette.muted)
         (set-font 11 true) (text! (.. "Means: " found.implication) 80 240 560 :left palette.muted)
         (set-font 11 true) (text! found.status 80 260 560 :left palette.muted)
          (scene-sketch! 390 362 0.95 :register)
          (set-font 10 true) (text! "SCENE SKETCH / REGISTER" 390 512 260 :left palette.muted)
        (let [evidence-proof-map {:receipt_004 "mira_departure_conflict" :pharmacy_footage "arin_means" :cup_lid "arin_delivery_method" :tape_fiber "arin_contact" :draft_email "arin_motive" :service_log "arin_opportunity" :toxicology "death_window_established" :camera_log "camera_gap_confirmed"}
              target (or (. evidence-proof-map found.id) found.id)
              proof (do (var p nil) (each [_ pr (ipairs (or state.proof_data []))] (when (or (= pr.fact found.id) (= pr.fact target) (do (var has false) (each [_ prem (ipairs (or pr.premises []))] (when (= prem.id found.id) (set has true))) has)) (set p pr))) p)]
             (if proof
               (do (set-font 12 true) (text! proof.conclusion 80 300 390 :left palette.ink)
                   (add-button "View proof" 500 290 120 30 (fn [] (tset state :active_proof proof.fact) (tset state :screen :proof)) :accent))
               (set-font 12 true) (text! "No proof yet." 80 300 400 :left palette.muted)))
         (let [ev found.id]
           (add-button (if (. state.accusation.evidence ev) "Remove" "Add") 500 330 120 30 (fn [] (if (. state.accusation.evidence ev) (tset state.accusation.evidence ev nil) (do (tset state.accusation.evidence ev true) (tset state.presented_evidence ev true)))) (if (. state.accusation.evidence ev) :accent nil)))
        (add-button "Back" 60 580 100 30 (fn [] (tset state :screen :evidence)))
        (add-button "Theory" 170 580 100 30 (fn [] (tset state :screen :theory)))))))

(local timeline-defs
  [{:time "18:52" :event "Sasha arrives to recover her apartment key" :requires [] :status "claimed"}
   {:time "18:58" :event "Dan delivers café supplies" :requires [] :status "claimed"}
   {:time "19:04" :event "Arin visits the night-store pharmacy counter" :requires ["pharmacy_footage"] :status "confirmed"}
   {:time "19:16" :event "Jo opens the west-camera panel" :requires ["panel_log"] :status "confirmed"}
   {:time "19:18" :event "West café camera goes offline" :requires ["camera_log"] :status "confirmed"}
   {:time "19:19" :event "A delivery-bike photo places Dan in the alley" :requires ["delivery_photo"] :status "confirmed"}
   {:time "19:21" :event "Jo sees a familiar person carrying Eli's cup" :requires ["jo_statement"] :status "claimed"}
   {:time "19:22" :event "Mira makes an in-person purchase" :requires ["receipt_004"] :status "confirmed"}
   {:time "19:23" :event "Mira sees Arin beside Eli's booth" :requires ["mira_statement"] :status "claimed"}
   {:time "19:24" :event "Eli drinks the iced americano" :requires ["toxicology"] :status "confirmed"}
   {:time "19:25" :event "Arin's borrowed tag exits through the service door" :requires ["service_log"] :status "confirmed"}
   {:time "19:25-19:28" :event "Eli dies from aconite" :requires ["toxicology"] :status "confirmed"}
   {:time "19:29" :event "West café camera returns" :requires ["camera_log"] :status "confirmed"}
   {:time "19:34" :event "Jo finds Eli" :requires [] :status "confirmed"}])

(fn timeline-visible []
  (let [out []]
    (each [_ row (ipairs timeline-defs)]
      (let [reqs row.requires
            ok (do (var v true) (each [_ id (ipairs reqs)] (when (not (has? id)) (set v false))) v)]
        (when (or (= (# reqs) 0) ok)
          (table.insert out row))))
    out))

(fn draw-timeline []
  (topbar! "TIME" "WHEN")
  (nav!)
   (rect! 60 90 600 460 palette.panel palette.line)
   (set-font 11 true) (text! "Timeline - only what is filed shows." 80 110 560 :left palette.muted)
  (let [rows (timeline-visible)
        per-page 6
        total (# rows)
        pages (math.max 1 (math.ceil (/ (math.max total 1) per-page)))
        page (math.max 1 (math.min (or state.timeline_page 1) pages))
        start (+ 1 (* (- page 1) per-page))
        finish (math.min total (+ start per-page -1))]
     (tset state :timeline_page page)
     (hairline! 172 136 172 464 palette.line)
     (if (= total 0)
       (do
         (set-font 12 true) (text! "Nothing yet." 80 140 400 :left palette.muted))
       (for [idx start finish]
          (let [row (. rows idx) y (+ 136 (* (- idx start) 56))
                confirmed (= row.status "confirmed")]
            (rect! 192 (- y 4) 440 48 palette.paper-light)
            (rect! 168 (+ y 4) 8 8 (if confirmed palette.green palette.panel) (if confirmed palette.green palette.dust))
            (when (not confirmed)
              (love.graphics.setColor palette.dust) (dotted-line! 176 (+ y 8) 192 (+ y 8)))
            (set-font 12 true) (text! row.time 80 (+ y 4) 82 :left palette.gold)
            (set-font 12 true) (text! row.event 204 y 302 :left palette.ink)
            (set-font 11 true) (text! (string.upper row.status) 516 (+ y 4) 104 :right (if confirmed palette.green palette.dust)))))
     (when (> pages 1)
       (add-button "Prev" 250 500 70 26 (fn [] (tset state :timeline_page (math.max 1 (- page 1)))))
       (add-button "Next" 410 500 70 26 (fn [] (tset state :timeline_page (math.min pages (+ page 1)))))))
  (add-button "Back" 60 580 100 30 (fn [] (tset state :screen :investigate)))
  (when state.contradiction
    (add-button "Conflict" 170 580 100 30 (fn [] (tset state :prev_screen :timeline) (tset state :screen :contradiction) ) :accent)))

(fn draw-contradiction []
  (topbar! "CONFLICT" "RECEIPT vs MIRA")
  (nav!)
   (rect! 60 90 600 380 palette.panel palette.line)
   (set-font 18 false) (text! "Mira said 19:10. Register says 19:22." 80 120 560 :left palette.ink)
   (set-font 14 false) (text! "One is memory. One is paper. Both cannot be true." 80 155 560 :left palette.muted)
  (set-font 11 true) (text! "This breaks the alibi. Not the murder." 80 190 500 :left palette.gold)
  (conflict-diagram! 80 225)
  (add-button "Keep looking" 80 400 140 30 (fn [] (tset state :screen (or state.prev_screen :investigate))) :accent)
  (add-button "See proof" 230 400 120 30 (fn [] (tset state :active_proof "mira_departure_conflict") (tset state :screen :proof))))

(local board-nodes
  [{:id "mira_conflict" :label "MIRA" :sub "timeline conflict" :x 210 :y 280 :requires ["receipt_004" "mira_left_1910"] :kind :contradiction}
   {:id "arin_means" :label "ARIN" :sub "pharmacy / poison" :x 650 :y 220 :requires ["pharmacy_footage"] :kind :proven}
   {:id "eli" :label "ELI" :sub "victim" :x 650 :y 500 :requires [] :kind :proven}
   {:id "camera_gap" :label "CAMERA GAP" :sub "19:18 - 19:29" :x 1000 :y 290 :requires ["camera_log"] :kind :proven}
   {:id "cup_lid" :label "CUP LID" :sub "residue" :x 330 :y 500 :requires ["cup_lid"] :kind :proven}
   {:id "tape_fiber" :label "TAPE FIBER" :sub "Arin contact" :x 450 :y 360 :requires ["tape_fiber" "cup_lid"] :kind :proven :alt_requires ["tape_fiber"]}
   {:id "m motive" :label "MOTIVE" :sub "draft email" :x 650 :y 360 :requires ["draft_email"] :kind :hypothesis}])

(fn board-visible-nodes []
  (let [out []]
    (each [_ n (ipairs board-nodes)]
      (let [ok (do (var v true) (each [_ id (ipairs n.requires)]
                    (when (and (= id "mira_left_1910") (not (. state.heard_statements id))) (set v false))
                    (when (and (not= id "mira_left_1910") (not (has? id))) (set v false))) v)]
        (when ok (table.insert out n))))
    out))

(fn draw-board []
  (topbar! "BOARD" "WHAT HOLDS")
  (nav!)
   (set-font 13 true) (text! "What the file supports" 40 84 500 :left palette.ink)
   ;; Columns classify known nodes. No decorative links imply a causal relationship.
   (let [nodes (board-visible-nodes)]
     (each [column group (ipairs [[:proven "HOLD" :green] [:hypothesis "GUESS" :dust] [:contradiction "CONFLICT" :rust]])]
       (let [x (+ 40 (* (- column 1) 218)) col (. palette (. group 3))]
         (rect! x 120 204 438 palette.panel palette.line)
         (set-font 14 true) (text! (. group 2) (+ x 14) 138 176 :left col)
         (hairline! (+ x 14) 162 (+ x 190) 162 col)
         (var row 0)
         (each [_ node (ipairs nodes)]
           (when (= node.kind (. group 1))
             (let [y (+ 178 (* row 72))]
               (rect! (+ x 12) y 180 60 palette.paper-light)
               (love.graphics.setColor col)
               (if (= node.kind :hypothesis)
                 (dotted-rect! (+ x 12) y 180 60)
                 (do (clipped-frame! (+ x 12) y 180 60 col)
                     (panel-fill! (+ x 12) y 3 60 col)))
               (set-font 13 true) (text! node.label (+ x 24) (+ y 9) 154 :left palette.ink)
               (set-font 12 true) (text! node.sub (+ x 24) (+ y 29) 154 :left palette.muted)
               (set row (+ row 1)))))
         (when (= row 0)
           (set-font 12 true) (text! "No filed entries." (+ x 14) 185 170 :left palette.muted)))))
  (set-font 12 true) (text! "Solid: holds   Dotted: hypothesis   Conflict: incompatible records" 40 575 640 :left palette.muted)
  (add-button "Map" 40 608 100 32 (fn [] (tset state :screen :investigate)))
  (add-button "Test a theory" 152 608 160 32 (fn [] (tset state :screen :theory))))

(fn proof-for [fact]
  (each [_ proof (ipairs (or state.proof_data []))]
    (when (= proof.fact fact) (lua "return proof"))))

(fn draw-proof []
  (let [headings {"mira_departure_conflict" "MIRA TIME" "arin_means" "ARIN MEANS" "arin_delivery_method" "DELIVERY" "arin_contact" "CONTACT" "arin_motive" "MOTIVE" "arin_opportunity" "WHEN" "death_window_established" "WINDOW" "camera_gap_confirmed" "GAP" "arin_case_proven" "CASE"}
        fact (or state.active_proof "mira_departure_conflict")
        proof (or (proof-for fact) (and (> (# (or state.proof_data [])) 0) (. state.proof_data 1)))
        heading (or (. headings fact) "PROOF")]
    (topbar! "PROOF" heading)
    (nav!)
     (set-font 12 true) (text! (.. heading " / PROOF TRACE") 40 84 600 :left palette.gold)
     (rect! 60 112 600 100 palette.panel (if proof palette.green palette.line))
     (set-font 16 false) (text! (or (and proof proof.conclusion) "No proof has been filed for this claim.") 80 137 560 :left palette.ink)
     (when proof
       (when (not= state.proof_view_fact fact)
         (tset state :proof_page 1) (tset state :proof_view_fact fact))
       (let [premises (or proof.premises [])
             pages (math.max 1 (math.ceil (/ (# premises) 6)))
             page (math.max 1 (math.min (or state.proof_page 1) pages))
             start (+ 1 (* (- page 1) 6))
             finish (math.min (# premises) (+ start 5))]
         (tset state :proof_page page)
         (when (> (# premises) 0)
           (hairline! 360 212 360 480 palette.green)
           (hairline! 354 220 360 212 palette.green)
           (hairline! 366 220 360 212 palette.green))
         (for [i start finish]
           (let [right (= (math.fmod (- i start) 2) 1)
                 x (if right 392 60) y (+ 248 (* (math.floor (/ (- i start) 2)) 78))
                 premise (. premises i)]
             (hairline! (if right 392 328) (+ y 28) 360 (+ y 28) palette.green)
             (rect! x y 268 58 palette.panel palette.line)
             (set-font 12 true) (text! (.. (string.format "%02d / " i) (or premise.title "Filed premise")) (+ x 12) (+ y 14) 244 :left palette.ink)))
         (when (> pages 1)
           (add-button "Prev" 400 514 74 28 (fn [] (tset state :proof_page (math.max 1 (- page 1)))))
           (set-font 12 true) (text! (string.format "%d / %d" page pages) 480 520 90 :center palette.muted)
           (add-button "Next" 580 514 74 28 (fn [] (tset state :proof_page (math.min pages (+ page 1))))))))
    (set-font 12 true) (text! (if proof "Filed premises support the conclusion above." "Find records before a proof can be traced.") 60 568 600 :left palette.muted)
    (add-button "Back" 60 616 100 32 (fn [] (tset state :screen :evidence)))
    (add-button "Accuse" 172 616 100 32 (fn [] (tset state :screen :accuse) ) :accent)))

(fn toggle-accusation-evidence! [id]
  (let [mode state.accusation_mode selected-set (. state.accusation mode)]
    (if (= mode :evidence)
      (if (. selected-set id)
        (do
          (tset selected-set id nil)
          (tset state.accusation.motive id nil)
          (tset state.accusation.method id nil)
          (tset state.accusation.opportunity id nil))
        (do (tset selected-set id true) (tset state.presented_evidence id true)))
      (if (. selected-set id)
        (tset selected-set id nil)
        (do
          (tset selected-set id true)
          (tset state.accusation.evidence id true)
          (tset state.presented_evidence id true))))))

(fn submit-accusation! []
  (let [payload (accusation-payload)
        result (logic-accusation payload)]
    (if (and result result.ok)
      (finish-accusation! payload result)
      (toast! "The reasoning engine could not evaluate the case."))))

(fn close-insufficient! []
  (let [snapshot (logic-sync)]
    (if (and snapshot snapshot.ok)
      (do
        (tset state :ending (if state.major_flags.unique_proof "everybody_goes_home" "detective"))
        (tset state :ending_report {:alternatives state.alternatives :unique_solution state.major_flags.unique_proof})
        (tset state.major_flags :closed_insufficient true)
        (tset state :screen :ending))
      (toast! "The reasoning engine could not review the open alternatives."))))

(fn toggle-theory! [id]
  (let [mode state.theory.mode bucket (. state.theory mode)]
    (if (= mode :evidence)
      (if (. bucket id) (do (tset bucket id nil) (tset state.theory.motive id nil) (tset state.theory.method id nil) (tset state.theory.opportunity id nil))
          (do (tset bucket id true)))
      (if (. bucket id) (tset bucket id nil)
          (do (tset bucket id true) (tset state.theory.evidence id true))))))

(fn evaluate-theory! []
  (let [p {:suspect (tostring state.theory.suspect)
           :motive (selected-list state.theory.motive)
           :method (selected-list state.theory.method)
           :opportunity (selected-list state.theory.opportunity)
           :evidence (selected-list state.theory.evidence)}
        result (logic-request :evaluate_hypothesis p)]
    (tset state.theory :result (or (and result result.evaluation) result))
    (tset state :theory_report_page 1)
    (when result (toast! "Theory evaluated as hypothesis."))))

(fn player-status [value]
  (let [s (tostring (or value "unresolved"))]
    (string.upper (string.gsub s "_" " "))))

(fn case-structure! [x y w]
  (let [stroke palette.line]
    (love.graphics.setLineWidth 1)
    (love.graphics.setColor stroke)
    (rect! x y w 22 palette.panel-cool stroke)
    (set-font 10 true)
    (text! (string.upper (tostring state.accused)) (+ x 6) (+ y 6) (- w 12) :left palette.ink)
    (each [i row (ipairs [["MOTIVE" :motive] ["METHOD" :method] ["OPPORTUNITY" :opportunity]])]
      (let [ry (+ y 38 (* (- i 1) 26))
            n (# (selected-list (. state.accusation (. row 2))))
            active (> n 0)]
        (love.graphics.setColor stroke)
        (love.graphics.line (+ x w 8) (+ y 22) (+ x w 8) ry)
        (love.graphics.line (+ x w) ry (+ x w 8) ry)
        (rect! x (- ry 9) w 20 palette.paper-light stroke)
        (text! (.. (. row 1) " / " n) (+ x 6) (- ry 4) (- w 12) :left (if active palette.gold palette.muted))))))

(fn theory-map! [x y]
  (let [stroke palette.line]
    (rect! x y 196 24 palette.paper-light stroke)
    (set-font 12 true)
    (text! "HYPOTHESIS INPUTS" (+ x 8) (+ y 5) 180 :left palette.dust)
    (each [i row (ipairs [["FILE" :evidence] ["WHY" :motive] ["HOW" :method] ["WHEN" :opportunity]])]
      (let [col (math.fmod (- i 1) 2)
            r (math.floor (/ (- i 1) 2))
            bx (+ x (* col 102))
            by (+ y 34 (* r 40))
            active (= state.theory.mode (. row 2))]
        (rect! bx by 94 30 palette.paper-light)
        (love.graphics.setColor (if active palette.gold stroke))
        (dotted-rect! bx by 94 30)
        (text! (.. (if active "> " "  ") (. row 1)) (+ bx 8) (+ by 8) 78 :left (if active palette.gold palette.muted))))))

(fn verdict-chart! [x y w]
  (let [r (or state.ending_report {})
        stroke palette.line]
    (love.graphics.setLineWidth 1)
    (love.graphics.setColor stroke)
    (rect! x y w 22 palette.panel-cool stroke)
    (set-font 10 true)
    (text! (string.upper (tostring state.accused)) (+ x 8) (+ y 6) (- w 16) :left palette.ink)
    (love.graphics.line (+ x 6) (+ y 22) (+ x 6) (+ y 88))
    (each [i row (ipairs [["MOTIVE" :motive] ["METHOD" :method] ["OPPORTUNITY" :opportunity]])]
      (let [ry (+ y 36 (* (- i 1) 26))
            status (player-status (. r (. row 2)))
            good (= status "SUPPORTED")]
        (love.graphics.setColor stroke)
        (love.graphics.line (+ x 6) ry (+ x 14) ry)
        (love.graphics.rectangle :line (+ x 14) (- ry 4) 9 9)
        (when good
          (love.graphics.setColor palette.green)
          (love.graphics.rectangle :fill (+ x 16) (- ry 2) 5 5))
        (love.graphics.setColor stroke)
        (text! (.. (. row 1) "  " status) (+ x 30) (- ry 5) (- w 40) :left (if good palette.ink palette.muted))))))

(fn add-report-line! [lines tone text]
  (when (and text (not= text ""))
    (table.insert lines {:tone tone :text text})))

(fn theory-report-lines [res]
  (let [lines []]
    (when res
      (add-report-line! lines :gold (.. "RESULT / " (player-status res.status)))
      (each [_ dim (ipairs (or res.dimensions []))]
        (let [name (string.upper (tostring (or dim.name dim.dimension "link")))]
          (add-report-line! lines :ink (.. name " / " (player-status dim.status)))
          (each [_ support (ipairs (or dim.support []))]
            (add-report-line! lines :muted (.. "Supports: " (or support.title support.evidence_title "Filed record"))))
          (each [_ missing (ipairs (or dim.missing []))]
            (add-report-line! lines :gold (.. "Missing: " (or missing.title missing.evidence_title "Required record"))))))
      (each [_ gap (ipairs (or res.unsupported []))]
        (let [evidence-title (or (and gap.evidence gap.evidence.title) gap.evidence_title)]
          (when evidence-title (add-report-line! lines :gold (.. "Missing evidence: " evidence-title)))
          (each [_ missing (ipairs (or gap.missing []))]
            (add-report-line! lines :gold (.. "Needs: " (or missing.title "Required record"))))))
      (each [_ conflict (ipairs (or res.contradictions []))]
        (add-report-line! lines :rust (.. "Statement: " (or conflict.statement_title "Filed statement")))
        (add-report-line! lines :rust (.. "Conflicts with: " (or conflict.evidence_title "Filed evidence")))
        (add-report-line! lines :rust (or conflict.reason_title "The two records cannot both hold.")))
      (add-report-line! lines :muted (string.format "%d competing accounts remain." (# (or res.alternatives [])))))
    lines))

(fn draw-theory []
  (topbar! "THEORY" "TEST")
  (nav!)
  (rect! 60 110 600 540 palette.panel palette.line)
   (set-font 16 false) (text! "Test a story." 80 130 560 :left palette.muted)
  (when (not state.theory.result)
    (each [i s (ipairs suspects)]
      (add-button s.name 80 (+ 150 (* (- i 1) 28)) 180 24 (fn [] (tset state.theory :suspect s.id)) (if (= state.theory.suspect s.id) :accent nil))))
  (set-font 14 true) (text! (string.upper (tostring state.theory.suspect)) 300 155 200 :left palette.gold)
  (add-button "File" 300 185 60 24 (fn [] (tset state.theory :mode :evidence)) (if (= state.theory.mode :evidence) :accent nil))
  (add-button "Why" 365 185 50 24 (fn [] (tset state.theory :mode :motive)) (if (= state.theory.mode :motive) :accent nil))
  (add-button "How" 420 185 50 24 (fn [] (tset state.theory :mode :method)) (if (= state.theory.mode :method) :accent nil))
  (add-button "When" 475 185 60 24 (fn [] (tset state.theory :mode :opportunity)) (if (= state.theory.mode :opportunity) :accent nil))
   (if state.theory.result
     (let [lines (theory-report-lines state.theory.result)
           per-page 10
           pages (math.max 1 (math.ceil (/ (math.max (# lines) 1) per-page)))
           page (math.max 1 (math.min (or state.theory_report_page 1) pages))
           start (+ 1 (* (- page 1) per-page))
           finish (math.min (# lines) (+ start per-page -1))]
       (tset state :theory_report_page page)
       (for [i start finish]
         (let [line (. lines i) y (+ 220 (* (- i start) 22))]
           (set-font 11 (= line.tone :ink))
           (text! line.text 80 y 560 :left (or (. palette line.tone) palette.muted))))
       (when (> pages 1)
         (add-button "PREV" 250 500 72 28 (fn [] (tset state :theory_report_page (math.max 1 (- page 1)))))
         (set-font 10 true) (text! (string.format "%d / %d" page pages) 330 508 60 :center palette.muted)
         (add-button "NEXT" 410 500 72 28 (fn [] (tset state :theory_report_page (math.min pages (+ page 1)))))))
     (do
        (set-font 11 true) (text! "Filed records" 300 130 300 :left palette.muted)
        (theory-map! 80 320)
        (set-font 10 true) (text! "LENS MAP / PICK ONE ANGLE" 80 440 240 :left palette.muted)
       (var y 220)
       (each [_ item (ipairs evidence-data)]
         (when (and (has? item.id) (< y 520))
           (let [active (. (. state.theory state.theory.mode) item.id)
                  label (.. (if active "[x] " "[ ] ") item.title)]
              (add-button label 300 y 300 18 (fn [] (toggle-theory! item.id)) (if active :accent nil))
             (set y (+ y 20)))))))
   (add-button "Test this story" 300 560 140 36 evaluate-theory! :accent)
   (add-button "Take it to accuse" 455 560 165 36 (fn [] (tset state :screen :accuse)))
    (add-button "Back to the board" 455 612 165 28 (fn [] (tset state :screen :board)))
    (when state.theory.result
      (add-button "Edit theory" 300 612 140 28 (fn [] (tset state.theory :result nil)))))

(fn draw-accuse []
  (topbar! "ACCUSE" "WHO")
  (nav!)
  (rect! 60 110 600 530 palette.panel palette.line)
  (set-font 12 true) (text! "Who am I naming?" 80 130 200 :left palette.muted)
  (each [i s (ipairs suspects)]
    (add-button s.name 80 (+ 150 (* (- i 1) 32)) 190 26 (fn [] (tset state :accused s.id) (tset state.accusation :suspect s.id)) (if (= state.accused s.id) :accent nil)))
  (set-font 22 false) (text! (string.upper (tostring state.accused)) 300 155 300 :left palette.gold)
  (set-font 11 true) (text! "File for:" 300 185 100 :left palette.muted)
  (add-button "File" 300 200 80 26 (fn [] (tset state :accusation_mode :evidence)) (if (= state.accusation_mode :evidence) :accent nil))
  (add-button "Why" 385 200 60 26 (fn [] (tset state :accusation_mode :motive)) (if (= state.accusation_mode :motive) :accent nil))
  (add-button "How" 450 200 60 26 (fn [] (tset state :accusation_mode :method)) (if (= state.accusation_mode :method) :accent nil))
  (add-button "When" 515 200 60 26 (fn [] (tset state :accusation_mode :opportunity)) (if (= state.accusation_mode :opportunity) :accent nil))
  (set-font 11 true) (text! "Checked stays." 300 230 300 :left palette.muted)
  (var y 255)
  (each [_ item (ipairs evidence-data)]
    (when (and (has? item.id) (< y 520))
      (let [active (. (. state.accusation state.accusation_mode) item.id)
            label (.. (if active "[x] " "[ ] ") item.title)]
        (add-button label 300 y 320 18 (fn [] (toggle-accusation-evidence! item.id)) (if active :accent nil))
        (set y (+ y 20)))))
  (set-font 10 true) (text! (string.format "%d in file / %d other accounts possible" state.clues (# state.alternatives)) 80 535 190 :left palette.muted)
  (case-structure! 80 330 180)
  (set-font 11 true) (text! "Selections, not proof." 80 468 190 :left palette.muted)
  (add-button "Submit" 300 535 120 32 submit-accusation! :accent)
  (add-button "Keep looking" 430 535 120 32 (fn [] (tset state :screen :investigate)))
  (add-button "Not enough" 300 587 120 28 close-insufficient!)
  (add-button "Theory" 430 587 100 28 (fn [] (tset state :screen :theory))))

(fn draw-ending []
  (panel-fill! 0 0 W H palette.paper)
  (local win (= state.ending "conviction"))
  (love.graphics.setColor (if win palette.green palette.rust)) (love.graphics.rectangle :fill 0 0 10 H)
  (set-font 13 true) (text! "CASE REPORT / 001" 72 78 300 :left palette.gold)
   (local titles {:conviction "CASE PROVEN" :lucky_idiot "CORRECT SUSPECT\nCASE UNPROVEN" :beautiful_theory "GOOD THEORY\nWEAK EVIDENCE" :insufficient_evidence "NO CONVICTION" :detective "CASE REMAINS OPEN" :everybody_goes_home "NO CHARGE"})
   (set-font 30 true) (text! (or (. titles state.ending) "CASE REVIEW INCOMPLETE") 72 140 360 :left palette.ink)
   (verdict-chart! 460 150 200)
   (district-art! 460 300 200 140)
   (set-font 11 true) (text! "CASE AREA / SCHEMATIC" 460 454 210 :left palette.muted)
  (when state.ending_report
     (set-font 16 false)
    (text! (if state.ending_report.unique_solution "No viable alternative remains in the submitted proof." "The visible record still leaves another account open.") 74 300 360 :left palette.muted)
    (when state.ending_report.motive
      (text! (.. "Motive: " (tostring state.ending_report.motive)) 74 345 360 :left palette.ink)
      (text! (.. "Method: " (tostring state.ending_report.method)) 74 368 360 :left palette.ink)
      (text! (.. "Opportunity: " (tostring state.ending_report.opportunity)) 74 391 360 :left palette.ink))
    (when state.ending_report.selected_evidence
      (text! (string.format "%d selected records were evaluated." (# state.ending_report.selected_evidence)) 74 424 360 :left palette.gold))
    (when state.ending_report.unsupported
      (text! (string.format "%d unsupported parts in the submitted argument." (# state.ending_report.unsupported)) 74 447 360 :left palette.gold)))
  (add-button "Back to title" 72 604 160 40 (fn [] (tset state :screen :title) (tset state :evidence {}) (tset state :clues 0) (tset state :ending nil))))

(fn draw-pause []
  (panel-fill! 0 0 W H palette.paper)
  (topbar! "PAUSE" "I STEPPED AWAY FROM THE FILE")
  (rect! 120 200 480 320 palette.panel palette.line)
   (set-font 24 false) (text! "Paused. The cafe waits." 150 230 420 :left palette.ink)
  (add-button "Go back" 150 290 180 40 (fn [] (tset state :screen :investigate) ) :accent)
  (add-button "Settings" 150 335 180 40 (fn [] (tset state :screen :settings)))
  (add-button "Save this file" 150 380 180 40 save-state!)
  (add-button "Open a saved file" 150 425 180 40 (fn [] (tset state :screen :load_record)))
  (add-button "Close and go to title" 150 470 220 40 (fn [] (tset state :screen :title))))

(fn draw-settings []
  (panel-fill! 0 0 W H palette.paper)
  (topbar! "SETTINGS" "MAKE THE FILE EASIER TO READ")
  (rect! 100 180 520 400 palette.panel palette.line)
   (set-font 24 false) (text! "Less motion" 130 220 300 :left palette.ink)
  (set-font 13 false) (text! "I turn off grain and other movement that is not needed." 130 245 440 :left palette.muted)
  (add-button (if state.settings.reducedMotion "On" "Off") 130 280 100 36 (fn [] (tset state.settings :reducedMotion (not state.settings.reducedMotion))))
  (add-button "Back" 130 520 120 36 (fn [] (tset state :screen :pause))))

(fn draw-load-record []
  (panel-fill! 0 0 W H palette.paper)
  (topbar! "CASE RECORD" "KEEP OR REOPEN THE FILE")
  (rect! 100 180 520 400 palette.panel palette.line)
   (set-font 24 false) (text! "My file on disk" 130 220 400 :left palette.ink)
  (set-font 12 false) (text! "Save keeps what I have filed. Load brings it back." 130 244 440 :left palette.muted)
  (add-button "Save now" 130 300 140 36 save-state! :accent)
  (add-button "Load it" 290 300 140 36 load-state!)
  (add-button "Back to the cafe" 130 500 170 36 (fn [] (tset state :screen :investigate))))

(fn draw-people []
  (topbar! "PEOPLE" "FIVE NAMES")
  (nav!)
   (rect! 40 90 640 500 palette.panel palette.line)
   (set-font 11 true) (text! "Talk to someone. Start anywhere." 80 110 560 :left palette.muted)
   (each [i s (ipairs suspects)]
     (let [y (+ 142 (* (- i 1) 88))]
       (rect! 56 (- y 4) 608 76 palette.paper-light)
       (suspect-portrait! s.id 64 y 64 64)
       (set-font 24 false) (text! s.name 144 (+ y 3) 200 :left palette.ink)
       (set-font 12 true) (text! s.role 144 (+ y 31) 200 :left palette.gold)
       (set-font 12 true) (text! (suspect-note s.id) 356 (+ y 4) 192 :left palette.muted)
       (add-button "Talk" 568 (+ y 16) 80 32 (fn [] (open-interview! s.id)) :accent)))
  (add-button "Map" 40 612 100 32 (fn [] (tset state :screen :investigate))))

(fn restore-dialogue-if-needed! []
  (when (and (= state.screen :dialogue) (or (not state.ink_text) (= state.ink_text "") (= (# state.ink_choices) 0)))
    (let [payload {:knot state.current_person :variables (known-ink-vars)}]
      (when state.ink_state (tset payload :state state.ink_state))
      (let [result (ink.request :goto payload)]
        (when (and result result.ok) (apply-ink! result))))
    (when (or (not state.ink_text) (= state.ink_text ""))
      (tset state :ink_text (.. (string.upper (tostring state.current_person)) ": …"))
      (when (= (# state.ink_choices) 0) (tset state :ink_choices [{:text "LEAVE INTERVIEW" :index 0}])))))

(fn draw-dialogue []
  (restore-dialogue-if-needed!)
  (panel-fill! 0 0 W H console.paper)
  ;; Static low-resolution counter backdrop. No licensed scene raster required.
  (panel-fill! 32 96 296 440 [0.105 0.115 0.11])
  (panel-fill! 44 110 268 210 [0.18 0.19 0.175])
  (for [i 0 8]
    (let [y (+ 116 (* i 23))]
      (panel-fill! 44 y 268 3 [0.09 0.11 0.105])
      (hairline! 44 (+ y 3) 312 (+ y 3) [0.26 0.265 0.23])))
  (panel-fill! 44 318 268 16 [0.31 0.28 0.20])
  (panel-fill! 44 334 268 186 [0.13 0.15 0.145])
  (suspect-portrait! state.current_person 36 100 288 432 true)
  ;; Scanlines belong to the picture, never over reading or menu text.
  (scanlines!)
  (clipped-frame! 32 96 296 440 console.edge)
  (hairline! 32 96 96 96 console.sodium)
  (hairline! 32 96 32 160 console.sodium)
  (hairline! 264 536 328 536 console.sodium)
  (hairline! 328 472 328 536 console.sodium)
  (topbar! "INTERVIEW" "CAFE")
  (nav!)
  (each [_ person (ipairs suspects)]
    (when (= person.id state.current_person)
      (if fonts.display (love.graphics.setFont fonts.display) (set-font 32 false))
      (text! person.name 36 549 288 :left console.ink)
      (set-font 13 true) (text! person.role 38 585 288 :left console.sodium)))
  (rect! 348 96 340 280 console.panel console.edge)
  (clipped-frame! 352 100 332 272 [0.20 0.23 0.23])
  (set-font 12 true) (text! "STATEMENT" 368 114 296 :left console.sodium)
  (hairline! 368 139 668 139 console.edge)
  (set-font 16 false) (text! (or state.ink_text "…") 368 158 300 :left console.ink)
  (set-font 12 true) (text! "ASK" 350 394 240 :left console.muted)
  (hairline! 392 400 688 400 console.edge)
  (if state.ink_can_continue
    (add-button "Continue" 348 420 340 26 continue-interview! :accent)
    (> (# state.ink_choices) 0)
    (let [page-size 6
          start (+ 1 (* (- state.dialogue_page 1) page-size))
          finish (math.min (# state.ink_choices) (+ start page-size -1))
          pages (math.max 1 (math.ceil (/ (# state.ink_choices) page-size)))]
      (for [i start finish]
        (let [choice (. state.ink_choices i)]
          (add-button choice.text 348 (+ 420 (* (- i start) 30)) 340 26 (fn [] (choose-interview! choice)))))
        (when (> pages 1)
          (add-button "Prev" 348 616 80 28 (fn [] (tset state :dialogue_page (math.max 1 (- state.dialogue_page 1)))))
          (set-font 12 true) (text! (string.format "%d / %d" state.dialogue_page pages) 464 623 108 :center console.muted)
          (add-button "Next" 608 616 80 28 (fn [] (tset state :dialogue_page (math.min pages (+ state.dialogue_page 1)))))))
    (add-button "Leave" 348 420 340 26 (fn [] (tset state :screen :people)) :accent))
  (add-button "Back" 36 616 100 30 (fn [] (tset state :screen :people)))
  (hairline! 32 layout.FOOTER_Y 688 layout.FOOTER_Y console.edge)
  (set-font 12 true)
  (text! "TAB  Move     ENTER  Select" 36 (+ layout.FOOTER_Y 10) 370 :left console.muted)
  (text! "ESC  Pause" 508 (+ layout.FOOTER_Y 10) 180 :right console.muted))

(fn change-view! []
  (tset state :location_view (if (= state.location_view 2) 1 2)))

(fn draw-location []
  (let [location (if (. location-data state.location) state.location :cafe)
        info (. location-data location)
        view (if (= state.location_view 2) 2 1)]
    (topbar! info.name "INSPECTION")
    (nav!)
    (set-font 13 false) (text! info.note 40 92 640 :left palette.ink)
    (panel-fill! 40 112 640 352 palette.paper-light)
    (let [ready (spaces.draw location view 40 112 640 352)]
      (clipped-frame! 40 112 640 352 palette.line)
      (when (not ready)
        (set-font 16 false) (text! "3D view unavailable. Use the inspection list below." 80 260 560 :center palette.muted))
      (each [i route (ipairs info.evidence)]
        (let [id (. route 1) point (spaces.point location (. route 1))
              p (and ready point (spaces.project location view point))
              x (+ 40 (* (math.fmod (- i 1) 2) 328))
              y (+ 486 (* (math.floor (/ (- i 1) 2)) 38))]
          (when p
            (add-button (string.format "%02d" i) (- (+ 40 (* (. p 1) 640)) 14) (- (+ 112 (* (. p 2) 352)) 12) 28 24
                        (fn [] (add! id)) (if (has? id) :accent nil)))
          (add-button (.. (string.format "%02d " i) (if (has? id) "[x] " "[ ] ") (. route 2)) x y 312 30
                      (fn [] (add! id)) (if (has? id) :accent nil)))))
    (add-button "Change view" 40 616 160 32 change-view!)
    (set-font 12 true) (text! (.. "V  /  " (if (= view 1) "Right view" "Left view")) 216 625 280 :left palette.muted)
    (add-button "Area map" 552 616 128 32 (fn [] (tset state :screen :investigate)))))

(fn prepare-capture! [name]
  (let [all-evidence {}]
    (each [_ item (ipairs evidence-data)] (tset all-evidence item.id true))
    (if (= name "title") (tset state :screen :title)
        (= name "location")
        (do (tset state :screen :location) (tset state :location :cafe)
            (tset state :location_view 1) (set focus-index 7))
        (= name "dialogue")
        (do (tset state :screen :dialogue)
            (set focus-index 7)
            (tset state :evidence {:receipt_004 true})
            (tset state :current_person :mira)
            (tset state :ink_text "MIRA: I left at ten past seven. If you have a later time, show me.")
            (tset state :ink_choices [{:index 0 :text "Where did you go afterward?"}
                                      {:index 1 :text "Present Receipt #004"}
                                      {:index 2 :text "Leave the interview"}])
            (tset state :ink_state nil))
        (= name "evidence-detail")
        (do (tset state :screen :evidence_detail)
            (tset state :evidence {:receipt_004 true})
            (tset state :evidence_detail "receipt_004")
            (tset state :proof_data [{:fact "mira_departure_conflict" :conclusion "Mira's departure claim is contradicted." :rule "purchase_requires_presence" :premises [{:id "receipt_004" :title "Receipt #004"}]}]))
         (= name "contradiction")
         (do (tset state :screen :contradiction) (tset state :evidence {:receipt_004 true}) (tset state.heard_statements :mira_left_1910 true))
         (= name "people")
         (do (tset state :screen :people) (tset state :evidence all-evidence) (tset state :clues 13))
         (= name "timeline")
        (do (tset state :screen :timeline) (tset state :evidence all-evidence) (tset state :timeline_page 2) (tset state :contradiction true))
        (= name "board")
        (do (tset state :screen :board) (tset state :evidence {:receipt_004 true :camera_log true :cup_lid true :pharmacy_footage true :draft_email true}) (tset state.heard_statements :mira_left_1910 true))
        (= name "accusation")
        (do (tset state :screen :accuse) (tset state :evidence all-evidence) (tset state :clues 13)
            (tset state.accusation :evidence {:toxicology true :pharmacy_footage true :cup_lid true :draft_email true :service_log true})
            (tset state.accusation :motive {:draft_email true})
            (tset state.accusation :method {:toxicology true :pharmacy_footage true :cup_lid true})
            (tset state.accusation :opportunity {:service_log true}))
        (= name "case-report")
        (do (tset state :screen :ending) (tset state :ending "lucky_idiot")
            (tset state :ending_report {:unique_solution false :motive "supported" :method "partial" :opportunity "supported" :selected_evidence [{:id "draft_email"}] :unsupported [{:code "required_evidence_missing"}]}))
        (tset state :screen :title))
    (var count 0)
    (each [_ _ (pairs state.evidence)] (set count (+ count 1)))
    (tset state :clues count)))

;; ---- LOVE callbacks ----

(fn love.load []
   (love.window.setMode W H {:resizable true :minwidth 600 :minheight 600})
  (love.window.setTitle "ondacase / Case 001")
  (love.graphics.setDefaultFilter :nearest :nearest)
   (each [_ s (ipairs [10 11 12 13 14 15 16 18 19 22 24 27 28 29 30 32 42 48 58])]
     (let [mono-path "assets/fonts/IBMPlexMono-Medium.ttf"
           serif-path "assets/fonts/Newsreader16pt-Regular.ttf"
          mfont (if (love.filesystem.getInfo mono-path) (love.graphics.newFont mono-path s) (love.graphics.newFont s))
          sfont (if (love.filesystem.getInfo serif-path) (love.graphics.newFont serif-path s) (love.graphics.newFont s))]
      (tset fonts (.. "m" s) mfont)
      (tset fonts (.. "s" s) sfont)
      (tset fonts (.. "c" s) nil)
      (tset fonts (.. "d" s) nil)
      (when (love.filesystem.getInfo "assets/fonts/ShareTechMono-Regular.ttf")
        (tset fonts (.. "c" s) (love.graphics.newFont "assets/fonts/ShareTechMono-Regular.ttf" s)))
      (when (love.filesystem.getInfo "assets/fonts/VT323-Regular.ttf")
        (tset fonts (.. "d" s) (love.graphics.newFont "assets/fonts/VT323-Regular.ttf" s)))))
  (tset fonts :display nil)
  (when (love.filesystem.getInfo "assets/fonts/VT323-Regular.ttf")
    (tset fonts :display (love.graphics.newFont "assets/fonts/VT323-Regular.ttf" 38))
    (fonts.display:setFilter :linear :linear))
  (when (love.filesystem.getInfo "assets/cafe/composed.png")
    (tset art :cafe_composed (love.graphics.newImage "assets/cafe/composed.png"))
    (art.cafe_composed:setFilter :linear :linear))
  (tset art :district nil)
  (when (love.filesystem.getInfo "assets/map/district.png")
    (tset art :district (love.graphics.newImage "assets/map/district.png"))
    (art.district:setFilter :nearest :nearest))
  (when (love.filesystem.getInfo "assets/cafe-lantern.png")
    (tset art :cafe (love.graphics.newImage "assets/cafe-lantern.png"))
    (art.cafe:setFilter :linear :linear))
  (tset art :portraits {})
  (tset art :portrait_crops {})
  (each [_ id (ipairs [:mira :arin :jo :sasha :dan])]
    (let [psx-path (.. "assets/suspects/" (tostring id) "-psx.png")
          psx (love.filesystem.getInfo psx-path)
          path (if psx psx-path (.. "assets/suspects/" (tostring id) ".png"))]
      (when (love.filesystem.getInfo path)
        (let [img (love.graphics.newImage path)]
          (img:setFilter (if psx :nearest :linear) (if psx :nearest :linear))
          (when psx
            ;; Head-only crop for the small People thumbnails; interviews use the bust.
            (tset art.portrait_crops id (love.graphics.newQuad 16 8 112 112 (img:getWidth) (img:getHeight))))
          (tset art.portraits id img)))))
  (when (love.filesystem.getInfo "assets/suspects-sheet.png")
    (tset art :suspects (love.graphics.newImage "assets/suspects-sheet.png"))
    (art.suspects:setFilter :linear :linear))
  (when (love.filesystem.getInfo "assets/locations-sheet.png")
    (tset art :locations (love.graphics.newImage "assets/locations-sheet.png"))
    (art.locations:setFilter :linear :linear))
  (logic-sync)
  (spaces.load)
  (when capture-name (prepare-capture! capture-name)))

(fn love.update [dt]
  (when (> state.toast_time 0)
    (tset state :toast_time (- state.toast_time dt))
    (when (<= state.toast_time 0) (tset state :toast nil)))
  (when capture-done (love.event.quit)))

(fn love.draw []
  (set focusable []) (set buttons [])
  (let [dw (love.graphics.getDimensions)
        dh (select 2 (love.graphics.getDimensions))
        calc (layout.calc dw dh)]
    (tset scale-state :scale calc.scale) (tset scale-state :ox calc.ox) (tset scale-state :oy calc.oy)
    (love.graphics.clear [0.05 0.05 0.05])
    (love.graphics.push)
    (love.graphics.translate calc.ox calc.oy)
    (love.graphics.scale calc.scale calc.scale)
    (love.graphics.setScissor calc.ox calc.oy calc.sw calc.sh)
    (panel-fill! 0 0 W H palette.paper)
    (if (= state.screen :title) (draw-title)
        (= state.screen :case_select) (draw-case-select)
        (= state.screen :investigate) (draw-investigate)
        (= state.screen :location) (draw-location)
        (= state.screen :people) (draw-people)
        (= state.screen :dialogue) (draw-dialogue)
        (= state.screen :evidence) (draw-evidence)
        (= state.screen :evidence_detail) (draw-evidence-detail)
        (= state.screen :timeline) (draw-timeline)
        (= state.screen :contradiction) (draw-contradiction)
        (= state.screen :proof) (draw-proof)
        (= state.screen :board) (draw-board)
        (= state.screen :theory) (draw-theory)
        (= state.screen :accuse) (draw-accuse)
        (= state.screen :ending) (draw-ending)
        (= state.screen :pause) (draw-pause)
        (= state.screen :settings) (draw-settings)
        (= state.screen :load_record) (draw-load-record)
        (draw-title))
    (when (> (# focusable) 0)
      (when (> focus-index (# focusable)) (set focus-index 1))
      (when (< focus-index 1) (set focus-index (# focusable))))
    (ambiance!)
    (when (and state.toast (> state.toast_time 0))
       (let [toast-x (if (= state.screen :case_select) 300 190)
             toast-y (if (= state.screen :title) 250 (if (= state.screen :case_select) 500 (if (= state.screen :ending) 250 60)))]
         (rect! toast-x toast-y 340 28 palette.gold)
         (set-font 12 true) (text! state.toast (+ toast-x 15) (+ toast-y 8) 310 :center palette.paper)))
    (when (not= state.screen :dialogue)
      (hairline! 32 layout.FOOTER_Y 688 layout.FOOTER_Y palette.line)
      (set-font 12 true)
      (text! "TAB  Move   ENTER  Select" 36 (+ layout.FOOTER_Y 10) 350 :left palette.muted)
      (text! "M  Map   ESC  Pause" 416 (+ layout.FOOTER_Y 10) 270 :right palette.muted))
    (love.graphics.setScissor)
    (love.graphics.pop)
    (when (and capture-name capture-path (not capture-requested))
      (set capture-requested true)
      (love.graphics.captureScreenshot
        (fn [image-data]
          (let [encoded (image-data:encode "png")
                file (io.open capture-path "wb")]
            (when file
              (file:write (encoded:getString))
              (file:close))
            (set capture-done true)))))
    ))

(fn love.mousemoved [x y dx dy]
  (update-hover! x y))

(fn love.mousepressed [x y b]
  (when (not= b 1) (lua "return"))
  (let [dw (love.graphics.getDimensions)
        dh (select 2 (love.graphics.getDimensions))
        calc (layout.calc dw dh)
        lx (/ (- x calc.ox) calc.scale)
        ly (/ (- y calc.oy) calc.scale)]
    (when (not (layout.in-logical? lx ly)) (lua "return"))
    (update-hover! x y)
    (each [i v (ipairs buttons)]
      (when (and (>= lx v.x) (<= lx (+ v.x v.w)) (>= ly v.y) (<= ly (+ v.y v.h)))
        (set focus-index i)
        (v.action) (lua "return")))))

(fn love.keypressed [k]
  (let [ctrl (or (love.keyboard.isDown "lctrl") (love.keyboard.isDown "rctrl"))]
    (when (and (= k "s") ctrl) (save-state!) (lua "return"))
    (when (and (= k "l") ctrl) (load-state!) (lua "return")))
  (if (= k "tab")
    (if (or (love.keyboard.isDown "lshift") (love.keyboard.isDown "rshift"))
      (set focus-index (- focus-index 1))
      (set focus-index (+ focus-index 1)))
    (= k "up") (set focus-index (- focus-index 1))
    (= k "down") (set focus-index (+ focus-index 1))
    (= k "left") (set focus-index (- focus-index 1))
    (= k "right") (set focus-index (+ focus-index 1))
    (or (= k "return") (= k "space") (= k "kpenter"))
    (when (and focusable focus-index (. focusable focus-index)) ((. focusable focus-index)))
    (= k "escape")
    (if (or (= state.screen :pause) (= state.screen :settings) (= state.screen :load_record) (= state.screen :contradiction) (= state.screen :evidence_detail))
      (tset state :screen (or state.prev_screen :investigate))
      (not= state.screen :title) (tset state :screen :pause))
    (= k "e") (tset state :screen :evidence)
    (= k "t") (tset state :screen :timeline)
    (= k "b") (tset state :screen :board)
    (= k "a") (tset state :screen :accuse)
    (= k "h") (tset state :screen :theory)
    (= k "m") (tset state :screen :investigate)
    (and (= k "v") (= state.screen :location)) (change-view!)
    (= k "p") (tset state :screen :pause)
    nil)
  (when (> (# focusable) 0)
    (when (> focus-index (# focusable)) (set focus-index 1))
    (when (< focus-index 1) (set focus-index (# focusable)))))

;; expose for tests
(tset _G :ondacase_focus {:get (fn [] focus-index) :set (fn [v] (set focus-index v)) :count (fn [] (# focusable)) :hover (fn [] hover-index) :set_hover (fn [v] (set hover-index v))})
(tset _G :ondacase_routes
  {:evidence {:receipt_004 :cafe :camera_log :cafe :toxicology :cafe :cup_lid :cafe :jo_statement :cafe :panel_log :cafe
              :service_log :alley :delivery_photo :alley :pharmacy_footage :store :draft_email :apartment :sasha_voicemail :apartment
              :tape_fiber :arin_interview :mira_statement :mira_interview}
   :statements {:mira_left_1910 :mira_interview :arin_cough_drops :arin_interview :jo_saw_cup_1921 :jo_interview
                :jo_identified_mira :jo_interview :sasha_never_argued :sasha_interview :dan_never_inside :dan_interview
                :dan_route_recollection :dan_interview}})
(tset _G :ondacase_runtime
  {:discover add!
   :record_statement record-statement!
   :logic_sync logic-sync
   :open_interview open-interview!
   :continue_interview continue-interview!
   :choose_interview choose-interview!
   :apply_ink apply-ink!
   :visit visit-location!
   :toggle_evidence toggle-accusation-evidence!
   :accusation_payload accusation-payload
   :submit_accusation submit-accusation!
   :close_insufficient close-insufficient!
   :evaluate_theory evaluate-theory!
   :theory_report_lines theory-report-lines
   :save_state save-state!
   :load_state load-state!
   :maybe_contradiction maybe-trigger-contradiction!
   :timeline_visible timeline-visible
   :board_visible board-visible-nodes})
