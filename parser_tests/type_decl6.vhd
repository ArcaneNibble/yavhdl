entity test is
    type t is range 0 to 10 units
        foo;

        bar = 2 foo;
        baz = bar;
    end units;
end;
