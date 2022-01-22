warning('off', 'frames:Index:notUnique');
warning('off', 'frames:MultiIndex:notUnique');

index0 = frames.MultiIndex({[ 1,  1,  1,  1,  1,  1,  2,  2,  2,  2,  2,  2,  1,  1,  2], ...
    ["a","b","c","a","b","c","a","b","c","a","b","c","a","a","b"], ...
    ["x","x","x","y","y","y","x","z","x","y","y","y","x","y","z"]});



% example selection7
selector = {[2,1,2],["b","a","b"],["y","x","z","z","y"]};
selector = {':',["b","a","b"],["y","x","z"]};


% get filtered sub-selection (for speedup)
rowsFiltered =  index0.getSelector(selector, false, 'all', true, true);
indexFilt = index0.getSubIndex(rowsFiltered);

Nindex = length(indexFilt);
NselectorDim = length(selector);


% get linear-index position selections for every dimension in selector
pos = cell(1, NselectorDim);
indseq = cell(1, NselectorDim);
for i=1:NselectorDim
    if ~iscolon(selector{i})
        % get linear-index selector
        [pos{i}, indseq{i}] = indexFilt.value_{i}.getSelector(selector{i});        
    else
        % special case: handle colon
        pos{i} = (1:Nindex)'; 
        indseq{i} = ones(Nindex,1);
    end
end

% dimensions to use
rootDim = 1;
loopDims = [2 3];
p = pos{rootDim};
NloopDims = length(loopDims);

% align cell array with indexes with selector dim1
indseq_grouped_aligned = cell(1,NselectorDim );
indseq_grouped_aligned{1} = num2cell(indseq{rootDim });
for i=loopDims
    % get for each MultiIndex row the selector sequence number(s) of values responsible for selection
    indseq_grouped = getSelectorIndicesForEachValue(pos{i}, indseq{i}, Nindex);
        
    % align indices according the main reference dimension
    indseq_grouped_aligned{i} = indseq_grouped(p);     
end

% combine to 2d cell (for further manipulation)
ind_alignAll = horzcat(indseq_grouped_aligned{:});

% expand rows with all combinations
[out,outind] = expandCombinationsCell(ind_alignAll);

% get sorted row positions
[~, sortind] = sortrows(out);
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


function ind_cell = getSelectorIndicesForEachValue(pos, indseq, N)
% get cell array(N) with cell(i) the position indices of vector x with value i
% (values of vector x has to be in range 1 to N)
[~,ix] = sort(pos);
c = histc(pos, 1:N); %#ok<HISTC>
ind_cell = mat2cell(indseq(ix),c,1);
end



