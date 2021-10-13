function colsStart = findColumnStart(data)
% ix : rows of data where the last missing value on each column is found
% c  : columns where the data starts whith at least one missing value
[idx,c] = findIxStartLastMissing(data);
[xi,xc] = size(data);
idx = getElementIDShift(idx,xi,xc,1);
colsStart = 1:xi:xi*xc;
allFull = setdiff(1:xc,c);
colsStart = colsStart(allFull);
colsStart = [colsStart idx'];
end

