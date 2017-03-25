entity test is
    package a is new b generic map(c => foo'subtype range 0 to 2);
end;
