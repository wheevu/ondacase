% Named boundary for the runtime. Gameplay calls these operations, never raw
% Prolog goals. A production build can wrap the returned terms as JSON.
:- module(api, [request/3]).
:- use_module(case).

request(discover_evidence, Id, ok(Id)) :- case:discover_evidence(Id).
request(record_statement, Statement, ok(Statement)) :- case:record_statement(Statement).
request(query_contradictions, _, contradictions(List)) :- case:api(query_contradictions, List).
request(query_inferences, _, inferences(List)) :- case:api(query_inferences, List).
request(query_proof, Fact, proof(Fact, Tree)) :- case:proof(Fact, Tree).
request(evaluate_accusation, Person, result(Person, Result)) :- case:accusation(Person, Result).
request(available_evidence, _, available(List)) :-
    findall(Id, case:available_evidence(Id), List).
request(case_timeline, _, timeline(List)) :-
    findall(timeline(Time, Event, Status, Requires),
        case:case_timeline(Time, Event, Status, Requires), List).
request(why_locked, Id, locked(Id, Code)) :- case:why_locked(Id, Code).
request(why_not, Fact, missing(Fact, Missing)) :-
    case:why_not(Fact, missing(Missing)).
request(what_changed, Id, consequences(Id, Derivable, Pending)) :-
    case:what_changed(Id, consequences(Derivable, Pending)).
request(alternative_case, Suspect, alternative(Suspect, Explanation)) :-
    case:alternative_case(Suspect, Explanation).
request(board_state, _, board(List)) :-
    findall(node(Node, Kind, Status), case:board_node_status(Node, Kind, Status), List).
request(minimal_proof, Fact, proof_set(Fact, Leaves)) :-
    case:minimal_proof_sets(Fact, [Leaves]).
request(frontier, _, frontier(Entries)) :- case:frontier(Entries).
request(hypothetical_accusation, suspect(Suspect, Extra), result(Evaluation, Selected)) :-
    case:hypothetical_accusation(Suspect, Extra, result(Evaluation, Selected)).
request(why_possible, Suspect, possible(Suspect, Reasons)) :-
    case:why_possible(Suspect, Reasons).
request(exclusion_proof, Suspect, exclusion(Suspect, Result)) :-
    case:exclusion_proof(Suspect, Result).
request(verdict_critical, _, critical(List)) :-
    findall(Id, case:verdict_critical(Id), List).
request(verdict_redundant, _, redundant(List)) :-
    findall(Id, case:verdict_redundant(Id), List).
request(ranked_alternatives, Suspect, ranked(Suspect, Ranked)) :-
    case:ranked_alternatives(Suspect, Ranked).
request(epistemic_status, _, Status) :- case:epistemic_status(Status).
request(evidence_impact, Id, impact(Id, Impact)) :-
    case:evidence_impact(Id, Impact).
request(board_graph, _, Graph) :- case:board_graph(Graph).
request(director_topics, Suspect, topics(Suspect, Topics)) :-
    case:available_topics(Suspect, Topics).
request(interview_yield, Suspect, Yield) :-
    case:interview_yield(Suspect, Yield).
request(reaction_state, Suspect, reaction(Suspect, State)) :-
    case:reaction_state(Suspect, State).
