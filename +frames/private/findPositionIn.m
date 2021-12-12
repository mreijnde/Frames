function idx = findPositionIn(a,b, allowMissing)
    if nargin<3, allowMissing=false; end
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
    
    if ~allowMissing
       assertFoundIn(a,b);
    end
    idx = arrayfun(@(x) find(b==x),a,'UniformOutput',false);
    idx = [idx{:}];
    
    if isempty(idx), idx=double.empty(1,0); end
    if iscolumn(a), idx=idx'; end
end