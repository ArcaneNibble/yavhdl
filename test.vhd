mylabel: block begin end block;
mylabel2: block begin end block mylabel3;

mylabel: block (123 + 456) begin end block;

mylabel: block
    procedure p;
begin
    mylabel: block begin end block;
    mylabel2: block begin end block mylabel3;
end block;
