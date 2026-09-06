;; Ink bridge with an explicit serialized Story state. Fennel owns the current
;; snapshot; Ink owns the branching text and choice order.
(local json (require :dkjson))

(local encode-json (fn [value] (json.encode value)))
(local shell-quote (fn [value]
  (.. "'" (string.gsub value "'" "'\\''") "'")))
(local request (fn [operation payload]
  (let [body (doto (or payload {}) (tset :operation operation))
        encoded (encode-json body)
        command (.. "printf '%s\\n' " (shell-quote encoded) " | node tools/ink-host.mjs")
        pipe (io.popen command "r")
        line (and pipe (pipe:read "*l"))
        result (and line (json.decode line))]
    (when pipe (pipe:close))
    (or result {:ok false :error "Ink runtime unavailable"}))))

(local module {:request request})
(tset _G :ondacase_ink module)
module
