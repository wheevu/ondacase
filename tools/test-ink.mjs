import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { spawn, spawnSync } from "node:child_process";
import { createRequire } from "node:module";

async function compileWithInkjsIfNeeded() {
  const hasInklecate = spawnSync("which", ["inklecate"]).status === 0;
  if (hasInklecate) {
    const r = spawnSync("inklecate", ["-j","-o","story/main.json","story/main.ink"]);
    if (r.status===0) return;
  }
  const r = spawnSync(process.execPath, ["node_modules/inkjs/bin/inkjs-compiler.js","-o","story/main.json","story/main.ink"]);
  if (r.status===0) console.error("compiled via inkjs fallback");
  else console.error("inkjs compile fallback failed", r.stderr?.toString());
}
await compileWithInkjsIfNeeded();

const child = spawn(process.execPath, ["tools/ink-host.mjs"], { stdio: ["pipe", "pipe", "inherit"] });
let buffer = "";
const pending = [];

child.stdout.on("data", (chunk) => {
  buffer += chunk;
  while (buffer.includes("\n")) {
    const cut = buffer.indexOf("\n");
    const reply = JSON.parse(buffer.slice(0, cut));
    buffer = buffer.slice(cut + 1);
    pending.shift()?.resolve(reply);
  }
});
child.on("exit", (code) => {
  for (const waiter of pending.splice(0)) waiter.reject(new Error(`Ink host exited with ${code}`));
});

function request(value) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Ink host timed out on ${value.operation}`)), 3000);
    pending.push({
      resolve: (reply) => {
        clearTimeout(timer);
        resolve(reply);
      },
      reject,
    });
    child.stdin.write(`${JSON.stringify(value)}\n`);
  });
}

async function choicesAt(knot, state) {
  let reply = await request({ operation: "goto", knot, state });
  for (let step = 0; reply.ok && reply.choices.length === 0 && reply.can_continue && step < 20; step += 1) {
    reply = await request({ operation: "continue", state: reply.state });
  }
  return reply;
}

try {
  const init = await request({ operation: "init", variables: { receipt_004: true } });
  assert.equal(init.ok, true);
  assert.match(init.text, /café/);
  assert.deepEqual(init.lines, [init.text]);
  assert.deepEqual(init.errors, []);
  assert.equal(typeof init.state, "string");
  assert.equal(init.variables.receipt_004, true);
  assert.ok(init.known_vars.includes("tape_fiber"));

  const fresh = await request({ operation: "init" });
  assert.equal(fresh.variables.receipt_004, false);
  const menu = await choicesAt("arrival", fresh.state);
  assert.equal(menu.ok, true);
  assert.ok(menu.choices.length >= 10);
  const receipt = menu.choices.find((choice) => choice.text === "Inspect the receipt");
  assert.ok(receipt);

  const chosen = await request({ operation: "choose", index: receipt.index, state: menu.state });
  assert.equal(chosen.ok, true);
  assert.equal(chosen.variables.receipt_004, true);
  assert.ok(chosen.callbacks.some(({ name, args }) => name === "discover_evidence" && args[0] === "receipt_004"));

  const mira = await request({ operation: "goto", knot: "mira", state: chosen.state });
  assert.equal(mira.ok, true);
  assert.ok(mira.tags.includes("speaker:mira"));
  // intents present
  const miraMenu = await choicesAt("mira", chosen.state);
  assert.ok(miraMenu.choices.length >= 8, "mira should have >=8 intents");
  assert.ok(miraMenu.choices.some(c => c.text.toLowerCase().includes("card") || c.tags.includes("intent:neutral")));
  assert.ok(miraMenu.choices.some(c => c.text.includes("Receipt") || c.tags.includes("intent:present_evidence")));
  assert.ok(miraMenu.choices.some(c => c.text.toLowerCase().includes("leave") || c.tags.includes("intent:leave")));

  // repeat reaction: choose neutral then revisit
  const neutral = miraMenu.choices.find(c=>c.tags.includes("intent:neutral"));
  if (neutral) {
    const r1 = await request({ operation: "choose", index: neutral.index, state: miraMenu.state });
    assert.equal(r1.ok, true);
    const redux = await choicesAt("mira", r1.state);
    assert.ok(redux.choices.length>0);
  }

  // Arin's pharmacy evidence stays hidden until it is discovered.
  const arinFresh = await choicesAt("arin", fresh.state);
  assert.doesNotMatch(arinFresh.text, /aconite|footage says/i);
  for (const hiddenChoice of ["19:04", "story is false", "pharmacy footage", "said cough drops"]) {
    assert.ok(!arinFresh.choices.some(({ text }) => text.toLowerCase().includes(hiddenChoice)), `premature Arin choice: ${hiddenChoice}`);
  }
  assert.ok(arinFresh.choices.some(({ text }) => text.includes("night-store pharmacy")));

  const pharmacyKnown = await request({ operation: "init", variables: { pharmacy_footage: true } });
  const arinKnown = await choicesAt("arin", pharmacyKnown.state);
  assert.ok(arinKnown.choices.some(({ text }) => text.includes("19:04")));
  assert.ok(arinKnown.choices.some(({ text }) => text.includes("pharmacy footage")));

  // Re-entering the knot must rebuild materialized choices from restored evidence variables.
  const arinRebuilt = await choicesAt("arin", (await request({
    operation: "goto",
    knot: "arin",
    state: arinKnown.state,
    variables: { pharmacy_footage: false },
  })).state);
  assert.ok(!arinRebuilt.choices.some(({ text }) => text.includes("19:04") || text.includes("pharmacy footage")));

  const idle = await request({ operation: "continue", state: menu.state });
  assert.equal(idle.ok, true);
  assert.deepEqual(idle.lines, []);
  assert.ok(idle.choices.length >= 10);

  const badChoice = await request({ operation: "choose", index: 999, state: menu.state });
  assert.equal(badChoice.ok, false);
  assert.equal(badChoice.errors[0].code, "invalid_choice");

  const badVariable = await request({ operation: "init", variables: { culprit: true } });
  assert.equal(badVariable.ok, false);
  assert.equal(badVariable.errors[0].code, "unknown_variable");

  const badType = await request({ operation: "init", variables: { receipt_004: "yes" } });
  assert.equal(badType.ok, false);
  assert.equal(badType.errors[0].code, "invalid_variable");

  const unknown = await request({ operation: "rewind" });
  assert.equal(unknown.ok, false);
  assert.equal(unknown.errors[0].code, "unknown_operation");

  // bounded error: huge invalid variable name
  const long = await request({ operation: "init", variables: { ["x".repeat(1000)]: true } });
  assert.equal(long.ok, false);
  assert.ok(long.errors[0].message.length <= 500);

  // state serialization round-trip
  const s1 = await request({ operation: "init", variables: { camera_log: true } });
  const g1 = await request({ operation: "goto", knot: "arin", state: s1.state });
  const restored = await request({ operation: "continue", state: g1.state });
  assert.equal(restored.ok, true);
  assert.equal(restored.variables.camera_log, true);

  const legacy = await request({ operation: "start" });
  assert.equal(legacy.ok, true);
  assert.match(legacy.text, /café/);

  console.log("ink_runtime=pass");
} finally {
  child.kill();
}
