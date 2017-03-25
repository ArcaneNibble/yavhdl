entity test is
    package a is new b generic map(c => foo(open)(bar));
end;
