% Regenerates cases/001-americano/case.json from canonical Prolog case data.
% Run with `make manifest`. The output must stay deterministic.
:- initialization(main, main).
:- use_module(library(http/json)).
:- use_module(manifest).
:- dynamic manifest_file/1.
:- prolog_load_context(directory, LogicDirectory),
   directory_file_path(LogicDirectory, '../cases/001-americano/case.json', ManifestPath),
   assertz(manifest_file(ManifestPath)).

main :-
    manifest_file(ManifestPath),
    manifest:manifest_dict(Dict),
    setup_call_cleanup(
        open(ManifestPath, write, Stream, [encoding(utf8)]),
        (json_write_dict(Stream, Dict, [width(100)]), nl(Stream)),
        close(Stream)),
    halt(0).
