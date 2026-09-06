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
