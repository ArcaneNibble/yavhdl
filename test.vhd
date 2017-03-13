type DURATION is range -1E18 to 1E18
    units
        fs;                 --femtosecond
        ps  = 1000 fs;      --picosecond
        ns  = 1000 ps;      --nanosecond
        us  = 1000 ns;      --microsecond
        ms  = 1000 us;      --millisecond
        sec = 1000 ms;      --second
        min = 60 sec;       --minute
    end units;
