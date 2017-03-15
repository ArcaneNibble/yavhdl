process
    package p is
        component aaa end component;
        component bbb is end component;

        component ccc is generic(foo : bar) end component;
        component ddd is port(baz : qux) end component;
        component eee is generic(xxx : yyy) port(zzz : www) end component;
    end;
begin
end process;
