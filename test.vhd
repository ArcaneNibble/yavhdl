process
    procedure aaa is new bbb generic map(
        foo => bar(0 to 2)(open)(0 to 2, 1 to 3)
    );
begin
end process;
