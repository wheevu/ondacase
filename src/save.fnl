(local json (require :dkjson))
(local utf8 (require :utf8))

(local SAVE-VERSION 2)
(local SUPPORTED-VERSIONS {2 true})
(local MAX-PAYLOAD 200000)
(local MAX-OUTER 250000)

(local valid-screens {:title true :case_select true :investigate true :location true :people true :dialogue true :evidence true :evidence_detail true :timeline true :contradiction true :proof true :board true :theory true :accuse true :ending true :pause true :settings true :load_record true})
(local valid-suspects {:mira true :arin true :jo true :sasha true :dan true})
(local valid-locations {:cafe true :alley true :store true :apartment true})
(local valid-evidence {:receipt_004 true :camera_log true :toxicology true :pharmacy_footage true :cup_lid true :tape_fiber true :draft_email true :service_log true :mira_statement true :delivery_photo true :sasha_voicemail true :panel_log true :jo_statement true})
(local valid-statements {:mira_left_1910 true :arin_cough_drops true :jo_saw_cup_1921 true :jo_identified_mira true :sasha_never_argued true :dan_never_inside true :dan_route_recollection true})
(local valid-endings {:conviction true :lucky_idiot true :beautiful_theory true :insufficient_evidence true :detective true :everybody_goes_home true})

(fn clean-set [value allowed]
  (let [out {}]
    (when (= (type value) :table)
      (each [k v (pairs value)]
        (when (and (= v true) (. allowed k)) (tset out k true))))
    out))

(fn clean-flags [value]
  (let [out {}]
    (when (= (type value) :table)
      (each [k v (pairs value)]
        (when (and (= (type k) :string) (= (type v) :boolean)) (tset out k v))))
    out))

(fn clean-accusation [value allowed]
  (let [source (if (= (type value) :table) value {})
        suspect (if (. valid-suspects source.suspect) source.suspect :arin)
        selected (clean-set source.evidence (or allowed valid-evidence))]
    {:suspect suspect
     :motive (clean-set source.motive selected)
     :method (clean-set source.method selected)
     :opportunity (clean-set source.opportunity selected)
     :evidence selected}))

(fn clean-ink-state [v]
  (if (and (= (type v) :string) (<= (# v) 20000) (utf8.len v)) v nil))

(fn clean-timeline-page [v]
  (if (and (= (type v) :number) (>= v 1) (<= v 100)) (math.floor v) 1))

(fn clean-string-list [value]
  (let [out []]
    (when (= (type value) :table)
      (each [_ item (ipairs value)]
        (when (and (< (# out) 200) (= (type item) :string) (<= (# item) 500) (utf8.len item))
          (table.insert out item))))
    out))

(local valid-dimension-status {:supported true :partial true :missing true :unsupported true :contradicted true})
(local valid-gap-codes {:unsupported_dimension true :unsupported_premise true :required_evidence_missing true :contradiction_ignored true})

(fn clean-report-evidence [value allowed]
  (let [out [] seen {}]
    (when (= (type value) :table)
      (each [_ item (ipairs value)]
        (let [id (if (= (type item) :string) item
                     (= (type item) :table) item.id
                     nil)]
          (when (and id (. allowed id) (not (. seen id)) (< (# out) 20))
            (tset seen id true)
            (table.insert out {:id id})))))
    out))

(fn clean-report-gaps [value]
  (let [out []]
    (when (= (type value) :table)
      (each [_ item (ipairs value)]
        (when (and (= (type item) :table) (< (# out) 50))
          (let [gap {}
                code (if (and (= (type item.code) :string) (. valid-gap-codes item.code)) item.code nil)
                dimension (if (and (= (type item.dimension) :string) (. {:motive true :method true :opportunity true} item.dimension)) item.dimension nil)]
            (when code (tset gap :code code))
            (when dimension (tset gap :dimension dimension))
            (table.insert out gap)))))
    out))

(fn clean-ending-report [value allowed]
  (when (and (= (type value) :table) (= (type value.unique_solution) :boolean))
    (let [out {:unique_solution value.unique_solution
               :selected_evidence (clean-report-evidence value.selected_evidence allowed)
               :unsupported (clean-report-gaps value.unsupported)}]
      (each [_ field (ipairs [:motive :method :opportunity])]
        (let [status (. value field)]
          (when (and (= (type status) :string) (. valid-dimension-status status))
            (tset out field status))))
      out)))

(fn clean-theory [value allowed]
  (let [src (if (= (type value) :table) value {})
        sus (if (. valid-suspects src.suspect) src.suspect :arin)
        mode (if (= src.mode :motive) :motive (= src.mode :method) :method (= src.mode :opportunity) :opportunity :evidence)]
    {:suspect sus
     :motive (clean-set src.motive (or allowed valid-evidence))
     :method (clean-set src.method (or allowed valid-evidence))
     :opportunity (clean-set src.opportunity (or allowed valid-evidence))
     :evidence (clean-set src.evidence (or allowed valid-evidence))
     :mode mode}))

(fn sanitize-theory-after-parse [theory evidence-set]
  (let [base (clean-theory theory evidence-set)
        ev (or (. base :evidence) {})]
    (each [k _ (pairs ev)]
      (when (not (. evidence-set k))
        (tset ev k nil)))
    (each [k _ (pairs base.motive)]
      (when (or (not (. evidence-set k)) (not (. ev k)))
        (tset base.motive k nil)))
    (each [k _ (pairs base.method)]
      (when (or (not (. evidence-set k)) (not (. ev k)))
        (tset base.method k nil)))
    (each [k _ (pairs base.opportunity)]
      (when (or (not (. evidence-set k)) (not (. ev k)))
        (tset base.opportunity k nil)))
    base))

(fn checksum [s]
  (var h 2166136261)
  (for [i 1 (# s)]
    (set h (% (+ (* h 31) (string.byte s i)) 4294967296)))
  (string.format "%08x" h))

(fn json-object? [value]
  (and (= (type value) :table)
       (let [meta (getmetatable value)]
         (not (and meta (= meta.__jsontype :array))))))

(fn validate [data]
  (when (not (json-object? data))
    (lua "return nil, 'not an object'"))
  (when (and data.version (not (. SUPPORTED-VERSIONS data.version)))
    (lua "return nil, 'unsupported version'"))
  true)

(fn serialize [state]
  (let [clean-ev (clean-set state.evidence valid-evidence)
        inner {:screen state.screen
               :evidence clean-ev
               :clues state.clues
               :accused state.accused
               :accusation (clean-accusation state.accusation clean-ev)
               :location state.location
               :settings state.settings
               :ink_state (clean-ink-state state.ink_state)
               :dialogue_page state.dialogue_page
               :timeline_page state.timeline_page
               :ending state.ending
               :ending_report (clean-ending-report state.ending_report clean-ev)
               :current_person state.current_person
               :inspected_objects (clean-set state.inspected_objects clean-ev)
               :visited_locations (clean-set state.visited_locations valid-locations)
               :heard_statements (clean-set state.heard_statements valid-statements)
               :conversation_branches (clean-string-list state.conversation_branches)
               :presented_evidence (clean-set state.presented_evidence clean-ev)
               :evidence_page state.evidence_page
               :evidence_detail (if (. clean-ev state.evidence_detail) state.evidence_detail nil)
               :prev_screen state.prev_screen
               :contradiction_seen (clean-flags state.contradiction_seen)
               :theory (clean-theory state.theory clean-ev)}
        payload-str (json.encode inner)]
    (when (> (# payload-str) MAX-PAYLOAD)
      (lua "return nil, 'payload too large'"))
    (let [cs (checksum payload-str)
          outer {:version SAVE-VERSION :payload payload-str :checksum cs}
          outer-str (json.encode outer)]
      outer-str)))

(fn parse [raw]
  (when (or (not raw) (= raw ""))
    (lua "return nil, 'empty'"))
  (when (> (# raw) MAX-OUTER)
    (lua "return nil, 'too large'"))
  (let [(ok data) (pcall json.decode raw)]
    (when (not ok)
      (lua "return nil, 'json error'"))
    (when (not data)
      (lua "return nil, 'nil data'"))
    (when (not (json-object? data))
      (lua "return nil, 'not an object'"))
    (when (not= data.version SAVE-VERSION)
      (lua "return nil, 'bad version'"))
    (when (not= (type data.payload) :string)
      (lua "return nil, 'bad payload'"))
    (when (not= (type data.checksum) :string)
      (lua "return nil, 'bad checksum'"))
    (when (or (> (# data.payload) MAX-PAYLOAD) (not= (# data.checksum) 8))
      (lua "return nil, 'bad envelope'"))
    (when (not= (checksum data.payload) data.checksum)
      (lua "return nil, 'checksum mismatch'"))
    (let [(ok2 inner) (pcall json.decode data.payload)]
      (when (not ok2)
        (lua "return nil, 'payload json error'"))
      (when (not inner)
        (lua "return nil, 'nil payload'"))
      (when (not (json-object? inner))
        (lua "return nil, 'payload not an object'"))
      (let [data inner]
     (let [clean-ev (clean-set data.evidence valid-evidence)
            screen-ok (and data.screen (. valid-screens data.screen))
            accused-ok (and data.accused (. valid-suspects data.accused))
            report (clean-ending-report data.ending_report clean-ev)
            ending (if (and report (= (type data.ending) :string) (. valid-endings data.ending)) data.ending nil)
            out {:screen (if screen-ok data.screen :title)
                  :evidence clean-ev
                 :clues (or data.clues 0)
                 :accused (if accused-ok data.accused :arin)
                 :accusation (clean-accusation data.accusation clean-ev)
                 :location (if (. valid-locations data.location) data.location :cafe)
                 :settings {:reducedMotion false}
                 :ink_state (clean-ink-state data.ink_state)
                 :ink_text nil
                 :ink_choices []
                 :ink_can_continue false
                 :dialogue_page (let [v data.dialogue_page] (if (and (= (type v) :number) (>= v 1) (<= v 100)) (math.floor v) 1))
                 :timeline_page (clean-timeline-page data.timeline_page)
                 :ending ending
                 :ending_report report
                 :current_person (if (. valid-suspects data.current_person) data.current_person :arin)
                 :inspected_objects (clean-set data.inspected_objects clean-ev)
                 :visited_locations (clean-set data.visited_locations valid-locations)
                 :heard_statements (clean-set data.heard_statements valid-statements)
                 :inferences []
                 :contradictions []
                 :contradiction false
                 :inferred_facts []
                 :conversation_branches (clean-string-list data.conversation_branches)
                 :hypotheses []
                 :timeline_entries {}
                 :presented_evidence (clean-set data.presented_evidence clean-ev)
                 :accusation_attempts []
                 :major_flags {}
                  :alternatives []
                  :proof_data []
                 :evidence_page (let [v data.evidence_page] (if (and (= (type v) :number) (>= v 1) (<= v 100)) (math.floor v) 1))
                  :evidence_detail (if (and (= (type data.evidence_detail) :string) (. clean-ev data.evidence_detail)) data.evidence_detail nil)
                  :prev_screen (if (and data.prev_screen (. valid-screens data.prev_screen)) data.prev_screen nil)
                  :contradiction_seen {}
                  :theory (sanitize-theory-after-parse data.theory clean-ev)
                   :active_proof nil}]
       (when (and (= (type data.settings) :table) (= data.settings.reducedMotion true))
          (tset out.settings :reducedMotion true))
       (when (and out.evidence.mira_statement
                  (or (not out.evidence.receipt_004) (not out.heard_statements.mira_left_1910)))
         (tset out.evidence :mira_statement nil)
         (tset out.accusation.evidence :mira_statement nil)
           (tset out.accusation.motive :mira_statement nil)
           (tset out.accusation.method :mira_statement nil)
           (tset out.accusation.opportunity :mira_statement nil)
           (tset out.inspected_objects :mira_statement nil)
           (tset out.presented_evidence :mira_statement nil)
           (tset out.theory.evidence :mira_statement nil)
           (tset out.theory.motive :mira_statement nil)
           (tset out.theory.method :mira_statement nil)
           (tset out.theory.opportunity :mira_statement nil)
           (when (= out.evidence_detail :mira_statement)
             (tset out :evidence_detail nil))
           (when out.ending_report
             (tset out :ending_report (clean-ending-report out.ending_report out.evidence))))
        (when (and out.evidence.receipt_004 out.heard_statements.mira_left_1910
                   (= (type data.contradiction_seen) :table)
                   (= data.contradiction_seen.receipt_mira true))
          (tset out.contradiction_seen :receipt_mira true))
        (when (and (= out.screen :evidence_detail) (not out.evidence_detail))
          (tset out :screen :evidence))
        (when (= out.screen :proof)
          (tset out :screen :evidence))
        (when (and (= out.screen :contradiction)
                   (or (not out.evidence.receipt_004) (not out.heard_statements.mira_left_1910)))
          (tset out :screen :investigate))
        (when (not out.ending)
          (tset out :ending_report nil))
        (when (and (= out.screen :ending) (or (not out.ending) (not out.ending_report)))
          (tset out :screen :investigate))
       (var c 0)
       (each [_ _ (pairs out.evidence)] (set c (+ c 1)))
       (tset out :clues c)
       out)))))

{: serialize : parse : validate : SAVE-VERSION}
