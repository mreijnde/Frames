warning('off', 'frames:Index:notUnique');

index0 = frames.MultiIndex({[ 1,  1,  1,  1,  1,  1,  2,  2,  2,  2,  2,  2,  1,  1,  2], ...
    ["a","b","c","a","b","c","a","b","c","a","b","c","a","a","b"], ...
    ["x","x","x","y","y","y","x","z","x","y","y","y","x","y","z"]});



% example selection7
selector = {[2,1,2],["b","a","b"],["y","x","z","z","y"]};
%selector = {[2],["b","a"],["y","x","z"]};


% get filtered sub-selection (for speedup)
rowsFiltered =  index0.getSelector(selector, false, 'all', true, true);
indexFilt = index0%.getSubIndex(rowsFiltered);


Nindex = length(indexFilt);
NselectorDim = length(selector);



% get matching MultiIndex rows from selectors
pos = cell(1, NselectorDim);
ind = cell(1, NselectorDim);
%rowsMask = false(Nindex, NselectorDim);
for i=1:NselectorDim
    [pos{i}, ind{i}] = indexFilt.value_{i}.getSelector(selector{i});
end

% dimensions to use
rootDim = 1;
loopDims = [2 3];
p = pos{rootDim};
NloopDims = length(loopDims);


% for each MultiIndex row get location(s) in selector
pos_grouped = cell(1,NselectorDim);
for i=1:NselectorDim
    pos_grouped{i} = getPosIndicesForEachValue(pos{i}, Nindex);
end

% align cell array with indexes with selector dim1

pos_align = cell(1,NloopDims);
ind_align = cell(1,NloopDims);
c = 0;
for i=loopDims
    c = c + 1;
    % get aligned cell fun
    tmp = pos_grouped{i};
    pos_align{c} = tmp(p); 
    % get cell fun with selector pos
    tmp2 = ind{i};    
    ind_align{c} = cellfun(@(x) tmp2(x), pos_align{c}, 'UniformOutput', false);    
end
ind_align = [{num2cell(ind{rootDim })} ind_align ];

% combine to 2d cell (for easier manipulation)
ind_alignAll = horzcat(ind_align{:});
%ind_alignAll = [num2cell(ind{rootDim }) ind_alignAll ]

% expand rows with all combinations
[out,outind] = expandCombinationsCell(ind_alignAll)

% get sorted row positions
[~, sortind] = sortrows(out)
outind_sorted = outind(sortind);
posout = p(outind_sorted);

% get index 
indexOut = indexFilt.getSubIndex(posout)



 
%%
% r=randi(20,10000,5)-15; 
% 
% r = [3 2 4];
% r(r<1) =1;
% c=mat2cell(r, ones( size(r,1),1),ones(size(r,2),1) );
% c=cellfun(@(x) 1:x, c, 'UniformOutput', false);
% tic
% out = expandCombinationsCell(c, false);
% toc
% 
% c
% out
%%


function ind_cell = getPosIndicesForEachValue(x, N)
% get cell array(N) with cell(i) the position indices of vector x with value i
% (values of vector x has to be in range 1 to N)
[~,ix] = sort(x);
c = histc(x, 1:N); %#ok<HISTC>
ind_cell = mat2cell(ix(:),c,1);
%ind_cell( cellfun(@isempty, ind_cell) ) = {NaN}; % convert missing values to NaN
end

