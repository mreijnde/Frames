function [ix,ixCorner] = getElementIDShift(elementsID,sizeIdx,sizeCol,lag)
% element ID where the IDs are shifted vertically. 
% ixCorner : if the shift makes the element disappear, take the id of the
% border of the matrix
data = false(sizeIdx,sizeCol);
data(elementsID) = true;
dataShift = shift(data,lag);
ix = find(dataShift == 1);
if nargout == 2
    hasDisappeared = any(dataShift) ~= any(data);
    if lag < 0
        startCol = 1:sizeIdx:sizeIdx*sizeCol;
        disappeared = startCol(hasDisappeared);
    else
        endCol = sizeIdx:sizeIdx:sizeIdx*sizeCol;
        disappeared = endCol(hasDisappeared);
    end
    ixCorner = union(ix,disappeared);
end
end