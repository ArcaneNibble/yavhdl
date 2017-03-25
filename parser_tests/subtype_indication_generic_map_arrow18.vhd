entity test is
    package a is new b generic map(c => foo(bar (open)));
end;
