entity test is
    package a is new b generic map(c => foo(0 to 2)(open)(bar'baz));
end;
