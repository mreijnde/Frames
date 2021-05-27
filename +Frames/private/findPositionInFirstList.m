function idx = findPositionInFirstList(a, b)
    if isdatetime(a) % boosts comparison speed
        a = datenum(a);
        b = datenum(b);
    end
    if iscell(a) % makes ismember
        a = string(a);
        b = string(b);
    end
    
    isinA = ismember(b, a);
    assert(all(isinA), "Elements of second list not found in first list: " + string(b(~isinA)));

    idx = arrayfun(@(x) find(a==x), b, 'UniformOutput', false);
    idx = [idx{:}];
end