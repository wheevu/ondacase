.PHONY: doctor build run test validate bridge-test ink ink-runtime ink-routes fennel-ink runtime-test check manifest

FENNEL_SOURCES := layout save prolog ink spaces main

doctor:
	@command -v love >/dev/null || { echo "missing: LÖVE 11.x" >&2; exit 1; }
	@command -v fennel >/dev/null || { echo "missing: Fennel" >&2; exit 1; }
	@command -v swipl >/dev/null || { echo "missing: SWI-Prolog" >&2; exit 1; }
	@command -v node >/dev/null || { echo "missing: Node.js" >&2; exit 1; }
	@command -v lua >/dev/null || { echo "missing: Lua" >&2; exit 1; }
	@command -v jq >/dev/null || { echo "missing: jq" >&2; exit 1; }
	@test -f vendor/share/lua/5.5/dkjson.lua || { echo "missing: vendored dkjson" >&2; exit 1; }
	@test -f node_modules/inkjs/bin/inkjs-compiler.js || { echo "missing: npm dependencies (npm ci)" >&2; exit 1; }
	@echo "ondacase_doctor=pass"

manifest:
	@swipl -q -s logic/export_manifest.pl
	@lua tools/build-case-manifest.lua

build: ink manifest
	@set -e; for name in $(FENNEL_SOURCES); do fennel -c "src/$$name.fnl" > "src/$$name.lua"; done
	@luac -p main.lua src/*.lua
	@echo "ondacase_build=pass"

run:
	love .

test:
	swipl -q -l logic/tests.pl -g run_tests,halt

bridge-test:
	@set -eu; \
	response=$$(printf '%s\n' \
	  '{"operation":"reset"}' \
	  '{"operation":"discover_evidence","evidence":"receipt_004"}' \
	  '{"operation":"record_statement","statement":"mira_left_1910"}' \
	  '{"operation":"query_state"}' | swipl -q -s logic/server.pl); \
	printf '%s' "$$response" | grep -q 'mira_departure_conflict'; \
	printf '%s' "$$response" | grep -q 'mira_present_1922'; \
	full=$$(printf '%s\n' \
	  '{"operation":"reset"}' \
	  '{"operation":"discover_evidence","evidence":"toxicology"}' \
	  '{"operation":"discover_evidence","evidence":"pharmacy_footage"}' \
	  '{"operation":"discover_evidence","evidence":"cup_lid"}' \
	  '{"operation":"discover_evidence","evidence":"tape_fiber"}' \
	  '{"operation":"discover_evidence","evidence":"draft_email"}' \
	  '{"operation":"discover_evidence","evidence":"service_log"}' \
	  '{"operation":"discover_evidence","evidence":"delivery_photo"}' \
	  '{"operation":"discover_evidence","evidence":"sasha_voicemail"}' \
	  '{"operation":"discover_evidence","evidence":"panel_log"}' \
	  '{"operation":"accusation","suspect":"arin","motive":["draft_email"],"method":["pharmacy_footage","toxicology","cup_lid","tape_fiber"],"opportunity":["service_log","toxicology"],"evidence":["toxicology","pharmacy_footage","cup_lid","tape_fiber","draft_email","service_log","delivery_photo","sasha_voicemail","panel_log"]}' | swipl -q -s logic/server.pl); \
	printf '%s' "$$full" | grep -q '"ending":"conviction"'; \
	printf '%s' "$$full" | grep -q '"sufficient_evidence":true'; \
	printf '%s' "$$full" | grep -q '"unique_solution":true'; \
	echo "prolog_json_bridge=pass"

validate:
	swipl -q logic/validator.pl

ink:
	node node_modules/inkjs/bin/inkjs-compiler.js -o story/main.json story/main.ink

ink-runtime:
	node tools/test-ink.mjs

ink-routes:
	node tools/test-ink-routes.mjs

fennel-ink:
	lua tools/test-fennel-ink.lua

runtime-test:
	lua tools/test-runtime.lua
	lua tools/test-fennel-runtime.lua
	lua tools/test-spaces.lua

check: doctor build test bridge-test validate ink-runtime ink-routes fennel-ink runtime-test
	@npm audit --omit=dev --audit-level=high
	@jq empty cases/001-americano/case.json
	@jq empty story/main.json
	@test "$$(jq -r '.issues | length' story/main.json)" = 0
	@echo "ondacase_check=pass"
