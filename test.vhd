architecture a of a is begin
    process is begin
        result <= foo(bar => 3, baz => 4)(3);
    end process;
end;
