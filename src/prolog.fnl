;; Named, narrow bridge. The runtime sends operations, never arbitrary goals.
(local json (require :dkjson))

(local encode-json (fn [value] (json.encode value)))
(local shell-quote (fn [value]
  (.. "'" (string.gsub value "'" "'\\''") "'")))

(fn copy-payload [payload]
  (let [out {}]
    (each [k v (pairs (or payload {}))]
      (when (and (not= k :known_evidence) (not= k :known_statements))
        (tset out k v)))
    out))

(fn line-for [operation payload]
  (json.encode (doto (copy-payload payload) (tset :operation operation))))

(fn request [operation payload]
  (let [payload (or payload {})
        lines [(line-for :reset {})]]
    ;; server.pl is intentionally process-local. Replay the player-safe snapshot
    ;; so every named call observes one coherent Prolog session.
    (each [_ statement (ipairs (or payload.known_statements []))]
      (table.insert lines (line-for :record_statement {:statement statement})))
    (each [_ evidence (ipairs (or payload.known_evidence []))]
      (table.insert lines (line-for :discover_evidence {:evidence evidence})))
    (table.insert lines (line-for operation payload))
    (let [input (.. (table.concat lines "\n") "\n")
        command (.. "printf '%s' " (shell-quote input) " | swipl -q -s logic/server.pl")
        pipe (io.popen command "r")
        output (and pipe (pipe:read "*a"))]
    (when pipe (pipe:close))
    (if output
      (let [responses []]
        (each [line (string.gmatch output "[^\r\n]+")]
          (let [decoded (json.decode line)] (table.insert responses decoded)))
        (or (. responses (# responses)) {:ok false :error "logic engine returned no response"}))
      {:ok false :error "logic engine unavailable"}))))

(local module {:request request})
(tset _G :ondacase_prolog module)
module
