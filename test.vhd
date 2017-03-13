label1: postponed process--(xxx, yyy, zzz)
    type aaa is range 0 to 5;
    type bbb is range 5 to 10;
    subtype ccc is ddd;
    constant eee : fff;
    constant ggg : hhh := iii;
    variable jjj : kkk;
    shared variable lll : mmm;
    variable nnn : ooo := ppp;
    shared variable qqq : rrr := sss;
begin
    foo <= bar;
    baz <= qux;
end postponed process label2;
