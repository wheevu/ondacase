% Counterfactual and proof-analysis machinery. Everything here is generic over
% the engine: it inspects requirements, assumes discoveries without mutating
% player state, and explains verdicts. All results are player-safe.
:- module(analysis, [
    full_case_state/0,
    proof_leaves/2, minimal_proof_sets/2, frontier/1,
    hypothetical_infer/3, hypothetical_accusation/3,
    why_possible/2, exclusion_proof/2,
    verdict_critical/1, verdict_redundant/1,
    ranked_alternatives/2, epistemic_status/1, evidence_impact/2,
    board_graph/1
]).

:- use_module(engine).
:- use_module(case_data, []).
:- use_module('../cases/001-americano/case_content', [exclusion_inference/2]).

% Saturates discovery through arbitrary gating chains, then hears everything.
full_case_state :-
    clear_player,
    saturate_discovery,
    record_all_statements,
    saturate_discovery.

saturate_discovery :-
    findall(Id, (evidence(Id), \+ player_evidence(Id), evidence_available(Id)), Open),
    Open \= [],
    maplist(discover_evidence, Open),
    saturate_discovery.
saturate_discovery.

record_all_statements :-
    findall(Statement, statement(Statement), Statements),
    maplist(record_statement, Statements).

% Hypothetical queries save player state, assume discoveries, run one
% question, and restore the exact prior set in forward flow. Explicit
% save/restore keeps temporary assertions from outliving their query no
% matter which choicepoints surround the call.
snapshot_state(state(Evidence, Statements)) :-
    findall(Id, player_evidence(Id), Evidence),
    findall(Statement, player_statement(Statement, heard), Statements).

restore_state(state(Evidence, Statements)) :-
    retractall(case_content:player_evidence(_)),
    retractall(case_content:player_statement(_, _)),
    maplist(assert_player_evidence, Evidence),
    maplist(assert_player_heard, Statements).

assert_player_evidence(Id) :- assertz(case_content:player_evidence(Id)).
assert_player_heard(Statement) :- assertz(case_content:player_statement(Statement, heard)).

assume_list(Evidence, Statements) :-
    maplist(assume_evidence, Evidence),
    maplist(assume_statement, Statements).

assume_evidence(Id) :- evidence(Id), ( player_evidence(Id) -> true ; assertz(case_content:player_evidence(Id)) ).
assume_statement(Id) :- statement(Id), ( player_statement(Id, heard) -> true ; assertz(case_content:player_statement(Id, heard)) ).

% Runs Goal under assumed discoveries, then restores. Goal must be
% deterministic for the answer to be meaningful; unknown ids fail fast.
with_assumed_state(ExtraEvidence, ExtraStatements, Goal) :-
    snapshot_state(Saved),
    assume_list(ExtraEvidence, ExtraStatements),
    catch((once(Goal), Det = true ; Det = false), Ex, (restore_state(Saved), throw(Ex))),
    restore_state(Saved),
    Det == true.

% Removes one record for one query, then restores the exact prior set.
with_evidence_removed(Removed, Goal) :-
    evidence(Removed),
    snapshot_state(Saved),
    retractall(case_content:player_evidence(Removed)),
    catch((once(Goal), Det = true ; Det = false), Ex, (restore_state(Saved), throw(Ex))),
    restore_state(Saved),
    Det == true.

% Transitive evidence/statement leaves behind an inference. Authored rules
% are conjunctive, so the sorted leaf set is the minimal proof set.
proof_leaves(Inference, Leaves) :-
    inference(Inference, Requirements, _),
    requirements_leaves(Requirements, Raw),
    sort(Raw, Leaves),
    Leaves \= [].

requirements_leaves([], []).
requirements_leaves([Requirement|Rest], Leaves) :-
    requirement_leaves(Requirement, Head),
    requirements_leaves(Rest, Tail),
    append(Head, Tail, Leaves).

requirement_leaves(evidence(Id), [evidence(Id)]).
requirement_leaves(statement(Id), [statement(Id)]).
requirement_leaves(inference(Name), Leaves) :-
    inference(Name, Requirements, _),
    requirements_leaves(Requirements, Leaves).

minimal_proof_sets(Inference, [Leaves]) :- proof_leaves(Inference, Leaves).

% Conclusions exactly one filed record away from becoming derivable.
frontier(Entries) :-
    findall(frontier(Inference, Missing),
        (inference(Inference, Requirements, _),
         \+ infer(Inference),
         findall(Requirement,
             (member(Requirement, Requirements), \+ requirement_met(Requirement)),
             [Missing])),
        Entries).

% Tests an inference under assumed discoveries. Player state is untouched.
hypothetical_infer(ExtraEvidence, ExtraStatements, Inference) :-
    with_assumed_state(ExtraEvidence, ExtraStatements, infer(Inference)).

% Evaluates an accusation under assumed evidence. Selected unions current
% discoveries with the assumed extras.
hypothetical_accusation(Suspect, ExtraEvidence, result(Evaluation, Selected)) :-
    person(Suspect),
    with_assumed_state(ExtraEvidence, [], accusation(Suspect, Evaluation)),
    findall(Id, player_evidence(Id), Current),
    append(ExtraEvidence, Current, Combined),
    sort(Combined, Selected).

% Explains why a suspect cannot yet be ruled out.
why_possible(Suspect, Reasons) :-
    person(Suspect),
    possible_suspect(Suspect),
    findall(Reason, possibility_reason(Suspect, Reason), Reasons),
    Reasons \= [].

possibility_reason(Suspect, unexcluded) :-
    \+ directly_excluded(Suspect, _).
possibility_reason(Suspect, claims_stand) :-
    \+ (claims(Suspect, _, Statement), contradiction(Statement, _, _)).
possibility_reason(_, case_open) :-
    proof_threshold_inference(Threshold),
    \+ infer(Threshold).

% Proves an exclusion when derived, otherwise names what is missing.
exclusion_proof(Suspect, proved(Proof)) :-
    exclusion_inference(Suspect, Rule),
    infer(Rule),
    proof(Rule, Proof).
exclusion_proof(Suspect, blocked(Missing)) :-
    exclusion_inference(Suspect, Rule),
    \+ infer(Rule),
    proof_leaves(Rule, Leaves),
    findall(Requirement,
        (member(Requirement, Leaves), \+ requirement_met(Requirement)),
        Missing).

% Verdict-relative criticality, measured from the fully discovered case.
canonical_conviction :-
    culprit(Culprit),
    accusation(Culprit, evaluation(_, _, ending(conviction), _, _, _, _)).

verdict_critical(Evidence) :-
    evidence(Evidence),
    full_case_state,
    with_evidence_removed(Evidence, \+ canonical_conviction).

verdict_redundant(Evidence) :-
    evidence(Evidence),
    full_case_state,
    with_evidence_removed(Evidence, canonical_conviction).

% Alternative explanations ranked by supported dimensions, strongest first.
ranked_alternatives(Accused, Ranked) :-
    person(Accused),
    findall(Score-Other,
        (person(Other), Other \= Accused, alternative_score(Other, Score)),
        Scored),
    sort(Scored, Ascending),
    reverse(Ascending, Descending),
    findall(rank(Other, Score), member(Score-Other, Descending), Ranked).

alternative_score(Suspect, Score) :-
    evaluate_hypothesis(Suspect, evaluation(_, _, Dimensions)),
    findall(1, member(dimension(_, supported, _, _), Dimensions), Supported),
    length(Supported, Score).

% Overall epistemic status of the investigation.
epistemic_status(epistemic(proven, Threshold)) :-
    case_complete,
    proof_threshold_inference(Threshold), !.
epistemic_status(epistemic(conflicted, Count)) :-
    findall(Statement, contradiction(Statement, _, _), Open),
    length(Open, Count), Count > 0, !.
epistemic_status(epistemic(open, evidence(Count))) :-
    findall(Id, player_evidence(Id), Discovered),
    length(Discovered, Count), Count > 0, !.
epistemic_status(epistemic(fresh, none)).

% Logical impact of newly discovering one record: inferences gained,
% contradictions triggered, and further records unlocked.
evidence_impact(Evidence, impact(Gains, Triggers, Unlocks)) :-
    evidence(Evidence),
    snapshot_state(Saved),
    catch(impact_delta(Evidence, Saved, Gains, Triggers, Unlocks),
        Ex, (restore_state(Saved), throw(Ex))).

impact_delta(Evidence, Saved, Gains, Triggers, Unlocks) :-
    state_snapshot(I0, C0, A0),
    assume_list([Evidence], []),
    state_snapshot(I1, C1, A1),
    restore_state(Saved),
    ord_subtract(I1, I0, Gains),
    ord_subtract(C1, C0, TriggerPairs),
    findall(contradiction(Statement, Record),
        member(Statement-Record, TriggerPairs), Triggers),
    ord_subtract(A1, A0, Unlocks).

state_snapshot(Inferences, Contradictions, Available) :-
    findall(Inference, infer(Inference), RawInferences),
    sort(RawInferences, Inferences),
    findall(Statement-Evidence, contradiction(Statement, Evidence, _), RawContradictions),
    sort(RawContradictions, Contradictions),
    findall(Id, available_evidence(Id), RawAvailable),
    sort(RawAvailable, Available).

% Proof-grounded board graph. Fennel owns layout; Prolog owns meaning.
% Supports and derives edges come from authored requirements. Contradicts
% and excludes edges exist only while live derivations back them.
board_graph(graph(Nodes, Edges)) :-
    findall(node(Id, Kind, Status, Active),
        board_node_entry(Id, Kind, Status, Active), Nodes),
    findall(Edge, board_edge(Edge), Edges).

board_node_entry(Id, Kind, Status, Active) :-
    board_node_status(Id, Kind, Status),
    ( board_node_contradiction_active(Id, Status) -> Active = true ; Active = false ).

board_node_contradiction_active(Id, visible) :-
    case_data:board_node(Id, contradiction, Requires),
    member(Statement, Requires),
    statement(Statement),
    contradiction(Statement, _, _).

board_edge(edge(evidence(Evidence), inference(Inference), supports, Active)) :-
    inference(Inference, Requirements, _),
    member(evidence(Evidence), Requirements),
    ( requirement_met(evidence(Evidence)) -> Active = true ; Active = false ).
board_edge(edge(inference(From), inference(To), derives, Active)) :-
    inference(To, Requirements, _),
    member(inference(From), Requirements),
    ( infer(From) -> Active = true ; Active = false ).
board_edge(edge(statement(Statement), evidence(Evidence), contradicts, true)) :-
    contradiction(Statement, Evidence, _).
board_edge(edge(inference(Rule), suspect(Suspect), excludes, true)) :-
    directly_excluded(Suspect, Rule).
