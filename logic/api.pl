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
