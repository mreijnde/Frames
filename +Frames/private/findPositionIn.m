function idx = findPositionIn(a,b)
    if iscolumn(b)
        b = b';
    end
    if isdatetime(b) % boosts comparison speed
        a = datenum(a);
        b = datenum(b);
    end
    if iscell(b) % makes ismember possible
        a = string(a);
        b = string(b);
    end
    
    assertFoundIn(a,b);
    idx = arrayfun(@(x) find(b==x),a,'UniformOutput',false);
    idx = [idx{:}];
    
    if iscolumn(a), idx=idx'; end
end