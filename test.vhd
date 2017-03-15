process
    procedure aaa is new bbb generic map(
        zzz => foo(bar, 0 to 2)
        --zzz => iii(jjj(foo(open)(open)))
    );
begin
end process;
