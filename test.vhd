L1: CELL port map (Top, Bottom, A(0), B(0));
L2: for I in 1 to 3 generate
L3: for J in 1 to 3 generate
--L4: if I+J>4 generate
--L5: CELL port map (A(I-1),B(J-1),A(I),B(J));
--end generate;
end generate;
end generate;
L6: for I in 1 to 3 generate
L7: for J in 1 to 3 generate
--L8: if I+J<4 generate
--L9: CELL port map (A(I+1),B(J+1),A(I),B(J));
--end generate;
end generate;
end generate;
