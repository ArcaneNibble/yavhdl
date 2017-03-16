architecture test of test is
begin
    l : x port map(
        aaa => bbb(ccc)(ddd(0 to 2, 1 to 3), eee(2 to 4))
    );
end architecture;
