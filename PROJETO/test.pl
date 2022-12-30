aaa(D) :-
    D = 1; D = 2; D = 3; D = 4; D = 5.

joelio(Result) :-
    findall(L, aaa(L), Result).