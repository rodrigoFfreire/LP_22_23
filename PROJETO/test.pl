deez(B) :-
    [H_H|H_T] = [[1, 2, 3], [4, 5, 6]],
    append(H_H, [a, b, c], B1),
    append([B1], H_T, B).
