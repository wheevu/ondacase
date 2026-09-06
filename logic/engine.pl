% Generic detective engine. Case-agnostic deduction machinery: player state
% transitions, requirement checking, proofs, knowledge states, hypothesis
% evaluation, accusation verdicts, and explanations.
%
% Authored content arrives through explicit hooks. The engine requires these
% predicates from its case module (see the reexport below):
% person/1, evidence/1, inference/3, culprit/1, proof_threshold_inference/1,
% claims/3, contradiction/3, directly_excluded/2, dimension_requirements/4,
% core_evidence/1, exclusion_record/1, selected_directly_excluded/3,
% selected_contradiction/4, selected_threshold_gaps/3, evidence_available/1,
% player_evidence/1, player_statement/2.
:- module(engine, [
    clear_player/0, discover_evidence/1, record_statement/1,
    minute_of_day/3, before/2, within/3,
    requirements_met/1, requirement_met/1, first_three/2, as_evidence_requirement/2,
    infer/1, proof/2, proof_premises/2, case_complete/0,
    possible_suspect/1, impossible_suspect/1, possible_alternatives/1,
    knowledge/2, evaluate_evidence/2, evaluate_hypothesis/2,
    dimension_evaluation/5, dimension_status/6, partition_discovered/3,
    consistent/1, ignored_contradiction/2, selected_ignored_contradiction/3,
    accusation/2, accusation/3, argument_dimension/3,
    selected_dimension_evaluation/7, selected_dimension_status/6,
    dimensions_supported/1, selected_case_complete/1,
    truth_value/2, accusation_ending/5, accusation_gaps/4,
    accusation_alternative/4, selected_accusation_alternative/5,
    api/2, available_evidence/1, case_timeline/4,
    board_requirement_met/1, board_node_visible/1, board_node_status/3,
    why_not/2, what_changed/2, alternative_case/2,
    person_name/2, inference_title/2, reason_title/2
]).

% Reexport doubles as the engine's required content interface: every hook
% the machinery calls unqualified, and the facade inherits visibility.
:- reexport('../cases/001-americano/case_content', [
    person/1, evidence/1, statement/1, inference/3,
    culprit/1, proof_threshold_inference/1,
    claims/3, contradiction/3, directly_excluded/2,
    dimension_requirements/4, core_evidence/1, exclusion_record/1,
    selected_directly_excluded/3, selected_contradiction/4,
    selected_threshold_gaps/3, evidence_available/1,
    player_evidence/1, player_statement/2
]).

:- use_module(case_data, []).

person_name(Id, Name) :- case_data:person_name(Id, Name).
inference_title(Id, Title) :- case_data:inference_title(Id, Title).
reason_title(Id, Title) :- case_data:reason_title(Id, Title).

% All times are integer minutes after midnight. No lexical atom comparison.
minute_of_day(Hour, Minute, Value) :-
    integer(Hour), integer(Minute), between(0, 23, Hour), between(0, 59, Minute),
    Value is Hour * 60 + Minute.
before(A, B) :- integer(A), integer(B), A < B.
within(Time, Start, End) :- integer(Time), Time >= Start, Time =< End.

clear_player :-
    retractall(player_statement(_, _)),
    retractall(player_evidence(_)).

discover_evidence(Id) :-
    evidence(Id),
    evidence_available(Id),
    ( player_evidence(Id) -> true ; assertz(player_evidence(Id)) ).

record_statement(Id) :-
    statement(Id),
    ( player_statement(Id, heard) -> true ; assertz(player_statement(Id, heard)) ).

% Investigation progression. The UI renders whatever the engine reports here.
available_evidence(Id) :-
    evidence(Id),
    evidence_available(Id).

case_timeline(Time, Event, Status, Requires) :-
    case_data:timeline_event(Time, Event, Status, Requires).

board_requirement_met(Id) :-
    evidence(Id), player_evidence(Id).
board_requirement_met(Id) :-
    statement(Id), player_statement(Id, heard).

board_node_visible(Node) :-
    case_data:board_node(Node, _, Requires),
    forall(member(Requirement, Requires), board_requirement_met(Requirement)).

board_node_status(Node, Kind, visible) :-
    case_data:board_node(Node, Kind, _),
    board_node_visible(Node).
board_node_status(Node, Kind, locked) :-
    case_data:board_node(Node, Kind, _),
    \+ board_node_visible(Node).

% Explanation engine. Every verdict the game returns can say why.
why_not(Inference, missing(Missing)) :-
    inference(Inference, Requirements, _),
    \+ infer(Inference),
    findall(Requirement,
        (member(Requirement, Requirements), \+ requirement_met(Requirement)),
        Missing).

what_changed(Evidence, consequences(Derivable, Pending)) :-
    evidence(Evidence),
    findall(Inference,
        (inference(Inference, Requirements, _),
         member(evidence(Evidence), Requirements), infer(Inference)),
        Derivable),
    findall(Inference,
        (inference(Inference, Requirements, _),
         member(evidence(Evidence), Requirements), \+ infer(Inference)),
        Pending).

alternative_case(Suspect, explanation(Status, Unsupported)) :-
    person(Suspect), \+ culprit(Suspect),
    evaluate_hypothesis(Suspect, evaluation(Suspect, Status, Dimensions)),
    findall(dimension(Name, DimStatus, Missing),
        (member(dimension(Name, DimStatus, _, Missing), Dimensions),
         DimStatus \= supported),
        Unsupported).

first_three([A, B, C|_], [A, B, C]).
as_evidence_requirement(Id, evidence(Id)).

infer(Name) :-
    inference(Name, Requirements, _),
    requirements_met(Requirements).

requirements_met([]).
requirements_met([Requirement|Rest]) :-
    requirement_met(Requirement),
    requirements_met(Rest).

requirement_met(evidence(Id)) :- player_evidence(Id).
requirement_met(statement(Id)) :- player_statement(Id, heard).
requirement_met(inference(Name)) :- infer(Name).

proof(Name, proof(Name, Premises, Rule)) :-
    infer(Name),
    inference(Name, Requirements, Rule),
    proof_premises(Requirements, Premises).

proof_premises([], []).
proof_premises([evidence(Id)|Rest], [evidence(Id)|Premises]) :-
    proof_premises(Rest, Premises).
proof_premises([statement(Id)|Rest], [statement(Id)|Premises]) :-
    proof_premises(Rest, Premises).
proof_premises([inference(Name)|Rest], [inference(Name, Proof)|Premises]) :-
    proof(Name, Proof),
    proof_premises(Rest, Premises).

case_complete :-
    proof_threshold_inference(Threshold),
    infer(Threshold).

impossible_suspect(Suspect) :-
    person(Suspect), \+ culprit(Suspect),
    ( directly_excluded(Suspect, _) -> true ; case_complete ).

possible_suspect(Suspect) :-
    person(Suspect),
    \+ impossible_suspect(Suspect).

possible_alternatives(List) :-
    findall(Suspect, (possible_suspect(Suspect)), List).

knowledge(discovered, evidence(Id)) :- player_evidence(Id).
knowledge(discovered_fact, evidence(Id)) :- player_evidence(Id).
knowledge(inferred, Fact) :- infer(Fact).
knowledge(inferred_fact, Fact) :- infer(Fact).
knowledge(hypothesized, suspect(Suspect)) :- person(Suspect).
knowledge(hypothesis, suspect(Suspect)) :- person(Suspect).
knowledge(contradicted, statement(Statement)) :- contradiction(Statement, _, _).
knowledge(possible, suspect(Suspect)) :- possible_suspect(Suspect).
knowledge(impossible, suspect(Suspect)) :- impossible_suspect(Suspect).
knowledge(proven, suspect(Culprit)) :- culprit(Culprit), case_complete.
knowledge(proven_concept, suspect(Culprit)) :- culprit(Culprit), case_complete.

% evaluate evidence and hypothesis for player API
evaluate_evidence(Id, evaluation(Id, relevant, supports(Found))) :-
    evidence(Id), player_evidence(Id),
    findall(Inf, (inference(Inf, Reqs, _), member(evidence(Id), Reqs), infer(Inf)), Found).
evaluate_evidence(Id, evaluation(Id, pending, supports([]))) :-
    evidence(Id), \+ player_evidence(Id).
evaluate_evidence(Id, evaluation(Id, discovered_no_inference, supports([]))) :-
    evidence(Id), player_evidence(Id),
    \+ (inference(_, Reqs, _), member(evidence(Id), Reqs), infer(_)).

evaluate_hypothesis(suspect(Suspect), evaluation(Suspect, Status, Details)) :-
    person(Suspect),
    ( possible_suspect(Suspect) -> Status = viable ; Status = excluded ),
    findall(dimension(Name, DimStatus, Support, Missing),
        (member(Name, [motive, method, opportunity]), dimension_evaluation(Suspect, Name, DimStatus, Support, Missing)), Details).
evaluate_hypothesis(Suspect, Eval) :- person(Suspect), evaluate_hypothesis(suspect(Suspect), Eval).

consistent(Suspect) :-
    person(Suspect),
    \+ ignored_contradiction(Suspect, _).

dimension_evaluation(Suspect, Dimension, Status, Support, Missing) :-
    dimension_requirements(Suspect, Dimension, Required, Maximum),
    partition_discovered(Required, Support, Missing),
    dimension_status(Suspect, Dimension, Maximum, Support, Missing, Status).

dimension_status(Suspect, _, _, _, _, contradicted) :-
    impossible_suspect(Suspect), !.
dimension_status(_, _, missing, _, _, missing) :- !.
dimension_status(_, _, Maximum, _, [], Maximum) :- !.
dimension_status(_, _, _, [], _, missing) :- !.
dimension_status(_, _, _, _, _, partial).

partition_discovered([], [], []).
partition_discovered([Id|Rest], [Id|Found], Missing) :-
    player_evidence(Id), !,
    partition_discovered(Rest, Found, Missing).
partition_discovered([Id|Rest], Found, [Id|Missing]) :-
    partition_discovered(Rest, Found, Missing).

accusation(Suspect, evaluation(
    sufficient_evidence(Sufficient),
    unique_solution(Unique),
    ending(Ending),
    dimensions(Dimensions),
    unsupported(Unsupported),
    alternatives(Alternatives),
    ignored_contradictions(Ignored)
)) :-
    findall(Id, player_evidence(Id), Selected),
    findall(Id, (dimension_requirements(Suspect, motive, Required, _), member(Id, Required), memberchk(Id, Selected)), Motive),
    findall(Id, (dimension_requirements(Suspect, method, Required, _), member(Id, Required), memberchk(Id, Selected)), Method),
    findall(Id, (dimension_requirements(Suspect, opportunity, Required, _), member(Id, Required), memberchk(Id, Selected)), Opportunity),
    accusation(Suspect, argument(Motive, Method, Opportunity, Selected), evaluation(
        sufficient_evidence(Sufficient), unique_solution(Unique), ending(Ending),
        dimensions(Dimensions), unsupported(Unsupported), alternatives(Alternatives),
        ignored_contradictions(Ignored))).

accusation(Suspect, argument(Motive, Method, Opportunity, Selected), evaluation(
    sufficient_evidence(Sufficient),
    unique_solution(Unique),
    ending(Ending),
    dimensions(Dimensions),
    unsupported(Unsupported),
    alternatives(Alternatives),
    ignored_contradictions(Ignored)
)) :-
    person(Suspect),
    append([Motive, Method, Opportunity], SubmittedPremises),
    subset(SubmittedPremises, Selected),
    maplist(player_evidence, Selected),
    truth_value(culprit(Suspect), Correct),
    findall(dimension(Name, Status, Support, Missing),
        (argument_dimension(Name, Motive, Method, Opportunity, Submitted),
         selected_dimension_evaluation(Suspect, Name, Submitted, Selected, Status, Support, Missing)), Dimensions),
    accusation_gaps(Suspect, Dimensions, argument(Motive, Method, Opportunity, Selected), Unsupported),
    truth_value((culprit(Suspect), selected_case_complete(Selected)), Unique),
    truth_value((Unique == true, dimensions_supported(Dimensions), \+ member(gap(unsupported_premise, _, _), Unsupported)), Sufficient),
    accusation_ending(Correct, Sufficient, Suspect, Dimensions, Ending),
    findall(alternative(Other, Status, Reason),
        selected_accusation_alternative(Suspect, Selected, Other, Status, Reason), Alternatives),
    findall(Item, selected_ignored_contradiction(Suspect, Selected, Item), Ignored).

argument_dimension(motive, Motive, _, _, Motive).
argument_dimension(method, _, Method, _, Method).
argument_dimension(opportunity, _, _, Opportunity, Opportunity).

selected_dimension_evaluation(Suspect, Dimension, Submitted, Selected, Status, Support, Missing) :-
    dimension_requirements(Suspect, Dimension, Required, Maximum),
    intersection(Required, Submitted, Support),
    subtract(Required, Support, Missing),
    selected_dimension_status(Suspect, Selected, Maximum, Support, Missing, Status).

selected_dimension_status(Suspect, Selected, _, _, _, contradicted) :-
    selected_impossible_suspect(Suspect, Selected), !.
selected_dimension_status(_, _, missing, _, _, missing) :- !.
selected_dimension_status(_, _, Maximum, _, [], Maximum) :- !.
selected_dimension_status(_, _, _, [], _, missing) :- !.
selected_dimension_status(_, _, _, _, _, partial).

dimensions_supported(Dimensions) :-
    forall(member(dimension(_, Status, _, _), Dimensions), Status == supported).

selected_case_complete(Selected) :-
    core_evidence(Core), subset(Core, Selected),
    findall(Id, (exclusion_record(Id), memberchk(Id, Selected)), Exclusions),
    length(Exclusions, Count), Count >= 3.

selected_impossible_suspect(Suspect, Selected) :-
    \+ culprit(Suspect),
    ( selected_directly_excluded(Suspect, Selected, _) -> true ; selected_case_complete(Selected) ).

truth_value(Goal, true) :- call(Goal), !.
truth_value(_, false).

accusation_ending(true, true, _, _, conviction) :- !.
accusation_ending(true, false, _, _, lucky_idiot) :- !.
accusation_ending(false, _, _, Dimensions, beautiful_theory) :-
    memberchk(dimension(opportunity, Status, _, _), Dimensions),
    memberchk(Status, [supported, partial]), !.
accusation_ending(false, _, _, _, insufficient_evidence).

accusation_gaps(Suspect, Dimensions, Argument, Gaps) :-
    findall(gap(dimension, Name, Status, Missing),
        (member(dimension(Name, Status, _, Missing), Dimensions), Status \= supported), DimensionGaps),
    findall(gap(unsupported_premise, Name, Id),
        (argument_dimension(Name, Argument, Submitted), dimension_requirements(Suspect, Name, Required, _),
         member(Id, Submitted), \+ memberchk(Id, Required)), PremiseGaps),
    selected_threshold_gaps(Suspect, Argument, ThresholdGaps),
    append([DimensionGaps, PremiseGaps, ThresholdGaps], Gaps).

argument_dimension(Name, argument(Motive, Method, Opportunity, _), Values) :-
    argument_dimension(Name, Motive, Method, Opportunity, Values).

accusation_alternative(Accused, Other, possible, not_excluded) :-
    person(Other), Other \= Accused, possible_suspect(Other).
accusation_alternative(Accused, Other, impossible, Rule) :-
    person(Other), Other \= Accused, impossible_suspect(Other),
    ( directly_excluded(Other, Rule) -> true ; Rule = complete_case_threshold ).

selected_accusation_alternative(Accused, Selected, Other, possible, not_excluded) :-
    person(Other), Other \= Accused, \+ selected_impossible_suspect(Other, Selected).
selected_accusation_alternative(Accused, Selected, Other, impossible, Rule) :-
    person(Other), Other \= Accused, selected_impossible_suspect(Other, Selected),
    ( selected_directly_excluded(Other, Selected, Rule) -> true ; Rule = complete_case_threshold ).

ignored_contradiction(Suspect, contradiction(Statement, Evidence, Reason)) :-
    claims(Suspect, _, Statement), contradiction(Statement, Evidence, Reason).
ignored_contradiction(Suspect, exclusion(Suspect, Rule)) :-
    directly_excluded(Suspect, Rule).
ignored_contradiction(Suspect, stronger_supported_case(Culprit)) :-
    culprit(Culprit), Suspect \= Culprit,
    proof_threshold_inference(Threshold), infer(Threshold).

selected_ignored_contradiction(Suspect, Selected, contradiction(Statement, Evidence, Reason)) :-
    claims(Suspect, _, Statement), selected_contradiction(Statement, Evidence, Reason, Selected).
selected_ignored_contradiction(Suspect, Selected, exclusion(Suspect, Rule)) :-
    selected_directly_excluded(Suspect, Selected, Rule).
selected_ignored_contradiction(Suspect, Selected, stronger_supported_case(Culprit)) :-
    culprit(Culprit), Suspect \= Culprit, selected_case_complete(Selected).

api(discover_evidence, Id) :- discover_evidence(Id).
api(query_contradictions, List) :-
    findall(contradiction(S, E, R), contradiction(S, E, R), List).
api(query_inferences, List) :- findall(F, infer(F), List).
api(query_proof, Fact) :- proof(Fact, _).
api(evaluate_accusation, Person) :- accusation(Person, _).
