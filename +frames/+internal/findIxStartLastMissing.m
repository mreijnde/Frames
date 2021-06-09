function [ix,c] = findIxStartLastMissing(data)
% ix : index of data where the last missing value on each column is found
% c  : columns where the data starts whith at least one missing value
[idx,col] = find(ismissing(fillmissing(data,'previous')));
[c,u] = unique(col,'last');
idx = idx(u);
ix = sub2ind(size(data),idx,c);
end
