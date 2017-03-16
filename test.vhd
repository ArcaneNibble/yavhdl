entity test is
end;

architecture test of test is
    type arr_type is array (integer range 0 to 1) of integer;
    shared variable aaa : arr_type;
    shared variable bbb : aaa'subtype;
begin
    xxx <= yyy'subtype'(zzz);
end architecture;
