function [idx, idxA] = findPositionIn(a,b, allowMissing)
% FINDPOSITIONIN find positions of vector a in vector b
%
% idx = findPositionIn(a,b) finds positions of vector a in vector b
%
% INPUT:
%    a:   vector with values to search for
%    b:   vector with values
%    allowMissing: logical to allow values in a that are missing in b
%
% OUTPUT:
%   idx:  vector with positions in vector b with values of vector a
%   idxA: vector with for each idx entry the corresponding position in vector a
%
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
    idxA = [];    
    if nargout>1
        % create idxA output vector only if needed (for speed)
        count = cellfun(@numel, idx);
        idxA = repelem(1:length(idx), count);
        if iscolumn(a), idxA=idxA'; end
    end
    idx = [idx{:}];
    
    if isempty(idx), idx=double.empty(1,0); end
    if iscolumn(a), idx=idx'; end        
end