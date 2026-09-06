% Case facade. Preserves the historical `case` contract while the deduction
% machinery lives in engine.pl and authored content in
% cases/001-americano/case_content.pl. Player-facing code addresses this
% module; hidden truth never appears in its exports.
:- module(case, [
    person/1, location/1, evidence/1, evidence_title/2,
    statement/1, statement_title/2, inference/1,
    person_name/2, inference_title/2, reason_title/2,
    clear_player/0, discover_evidence/1, record_statement/1,
    player_evidence/1, player_statement/2,
    infer/1, proof/2, contradiction/3, statement_status/2, statement_semantic/2,
    knowledge/2, possible_suspect/1, impossible_suspect/1,
    accusation/2, accusation/3, api/2,
    evaluate_evidence/2, evaluate_hypothesis/2, possible_alternatives/1,
    evidence_meaning/2, consistent/1, circular_reasoning/1,
    available_evidence/1, why_locked/2,
    case_timeline/4, board_node_status/3,
    why_not/2, what_changed/2, alternative_case/2,
    proof_leaves/2, minimal_proof_sets/2, frontier/1,
    hypothetical_infer/3, hypothetical_accusation/3,
    why_possible/2, exclusion_proof/2, exclusion_inference/2,
    verdict_critical/1, verdict_redundant/1,
    ranked_alternatives/2, epistemic_status/1, evidence_impact/2,
    board_graph/1,
    confrontation_grounds/4, reaction_state/2,
    interview_yield/2, available_topics/2
]).

:- use_module(engine).
:- use_module(analysis).
:- use_module(director).
% Content predicates the engine does not surface, imported for qualified
% callers. Hidden truth stays out of the export list above.
:- use_module('../cases/001-americano/case_content', [
    location/1, evidence_title/2, statement_title/2,
    inference/1, statement_status/2, has_supported_status/1,
    statement_semantic/2, evidence_meaning/2, why_locked/2,
    circular_reasoning/1, exclusion_inference/2,
    victim/1, true_event/1, evidence_fact/2, claims/3, deception/2
]).
