function idx = findPosition(a, b)
    if isdatetime(b) % boosts comparison speed
        a = datenum(a);
        b = datenum(b);
    end
    if iscell(b) % makes ismember
        a = string(a);
        b = string(b);
    end
    
    assertFoundIn(a, b);
    idx = arrayfun(@(x) find(b==x), a, 'UniformOutput', false);
    idx = [idx{:}];
end