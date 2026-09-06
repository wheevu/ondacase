import fs from "node:fs";
import readline from "node:readline";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { Story } = require("inkjs");
const source = fs.readFileSync(new URL("../story/main.json", import.meta.url), "utf8").replace(/^\uFEFF/, "");
const compiled = JSON.parse(source);
const story = new Story(compiled);
const callbacks = [];
const runtimeMessages = [];
const KNOWN_VARS = [
  "receipt_004",
  "camera_log",
  "toxicology",
  "pharmacy_footage",
  "cup_lid",
  "jo_statement",
  "tape_fiber",
  "draft_email",
  "service_log",
  "mira_statement",
  "delivery_photo",
  "sasha_voicemail",
  "panel_log",
];
const knownVars = new Set(KNOWN_VARS);

class ProtocolError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

story.onError = (message, type) => runtimeMessages.push({
  code: type === 1 ? "ink_warning" : "ink_error",
  message,
  warning: type === 1,
});

function bind(name) {
  story.BindExternalFunction(name, (...args) => {
    if (name === "discover_evidence" && knownVars.has(args[0])) {
      story.variablesState.$(args[0], true);
    }
    callbacks.push({ name, args });
  });
}
bind("discover_evidence");
bind("record_statement");
bind("evaluate_accusation");

function response(ok, extra = {}) {
  process.stdout.write(`${JSON.stringify({ ok, ...extra })}\n`);
}

function variables() {
  return Object.fromEntries(KNOWN_VARS.map((name) => [name, story.variablesState.$(name)]));
}

function applyVariables(value) {
  if (value === undefined) return;
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new ProtocolError("invalid_variables", "variables must be an object");
  }
  for (const [name, variable] of Object.entries(value)) {
    if (!knownVars.has(name)) throw new ProtocolError("unknown_variable", `unknown variable: ${name}`);
    if (typeof variable !== "boolean") {
      throw new ProtocolError("invalid_variable", `${name} must be boolean`);
    }
    story.variablesState.$(name, variable);
  }
}

function drain() {
  const raw = story.canContinue ? story.Continue() || "" : "";
  const text = bound(raw, 5000);
  const errors = runtimeMessages.filter((message) => !message.warning).map(({ warning, ...message }) => ({ code: bound(message.code,100), message: bound(message.message,500) }));
  const warnings = runtimeMessages.filter((message) => message.warning).map(({ warning, ...message }) => ({ code: bound(message.code,100), message: bound(message.message,500) }));
  const choices = story.currentChoices.slice(0, 100).map((choice) => ({
    index: choice.index,
    text: bound(choice.text, 500),
    tags: (choice.tags || []).slice(0, 20).map((t) => bound(t, 200)),
  }));
  response(errors.length === 0, {
    text,
    lines: text ? [text] : [],
    choices,
    tags: (story.currentTags || []).slice(0, 20).map((t) => bound(t, 200)),
    callbacks: callbacks.splice(0, 100),
    can_continue: story.canContinue,
    state: story.state.ToJson(),
    known_vars: KNOWN_VARS,
    variables: variables(),
    errors: errors.slice(0, 10),
    warnings: warnings.slice(0, 10),
  });
}

function bound(value, limit = 500) {
  const s = String(value);
  return s.length > limit ? s.slice(0, limit) : s;
}

function fail(error) {
  const message = bound(error.message || error, 500);
  const code = bound(error.code || "runtime_error", 100);
  callbacks.length = 0;
  runtimeMessages.length = 0;
  response(false, {
    error: message,
    lines: [],
    choices: [],
    tags: [],
    callbacks: [],
    can_continue: false,
    known_vars: KNOWN_VARS,
    errors: [{ code, message }],
    warnings: [],
  });
}

const input = readline.createInterface({ input: process.stdin, crlfDelay: Infinity });
input.on("line", (line) => {
  try {
    const request = JSON.parse(line);
    if (!request || typeof request !== "object" || Array.isArray(request)) {
      throw new ProtocolError("invalid_request", "request must be an object");
    }
    callbacks.length = 0;
    runtimeMessages.length = 0;
    const operation = request.operation;
    const isInit = operation === "init" || operation === "start";
    if (!isInit && Object.hasOwn(request, "state")) {
      if (typeof request.state !== "string") throw new ProtocolError("invalid_state", "state must be a string");
      story.state.LoadJson(request.state);
    }
    if (Object.hasOwn(request, "variables") && Object.hasOwn(request, "vars")) {
      throw new ProtocolError("invalid_variables", "send variables or vars, not both");
    }
    if (isInit) {
      story.ResetState();
      applyVariables(request.variables ?? request.vars);
      story.ChoosePathString("start");
      drain();
    } else if (operation === "goto") {
      if (typeof request.knot !== "string" || !request.knot) {
        throw new ProtocolError("invalid_knot", "goto requires a knot");
      }
      applyVariables(request.variables ?? request.vars);
      story.ChoosePathString(request.knot);
      drain();
    } else if (operation === "continue") {
      applyVariables(request.variables ?? request.vars);
      drain();
    } else if (operation === "choose") {
      if (!Number.isInteger(request.index) || request.index < 0 || request.index >= story.currentChoices.length) {
        throw new ProtocolError("invalid_choice", "choose requires an available choice index");
      }
      applyVariables(request.variables ?? request.vars);
      story.ChooseChoiceIndex(request.index);
      drain();
    } else {
      throw new ProtocolError("unknown_operation", `unknown operation: ${String(operation)}`);
    }
  } catch (error) {
    fail(error);
  }
});
