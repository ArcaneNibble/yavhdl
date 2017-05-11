entity test is
    type test1 is (foo);
    subtype test2 is test.test1;
    subtype test3 is test.test2;
begin end;
