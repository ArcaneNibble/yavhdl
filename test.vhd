process
    procedure aaa is new bbb generic map(
        foo => bar(baz(0 to 2), qux(1 to 3))
    );
begin
end process;
