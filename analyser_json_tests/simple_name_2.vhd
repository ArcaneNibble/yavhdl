entity test is
    type test1 is (foo);
    subtype test2 is test; -- Wrong kind
begin end;
