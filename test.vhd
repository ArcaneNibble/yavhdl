process
    procedure aaa is new bbb generic map(
        --zzz => iii(jjj(
            foo1(open)
            --,
            --foo2(open)(open)
            --,
            --foo3(0 to 2)
            --,
            --foo4(0 to 2, 1 to 3)
            --,
            --foo5(0 to 2)(1 to 3)
            --,
            --foo6(bar)
            --,
            --foo7(bar, baz)
            --,
            --foo8(bar range baz'qux)
            --,
            --foo9(bar range baz'qux, zzz range www'xxx)
            --,
            --foo10(bar range baz'qux)(open)
        --))
    );
begin
end process;
