function array = replaceStartBy( array, valueNew, valueToReplace )
% replaceStartBy Replace all consecutive identical values at the beginning 
% of the columns by 'valueNew', if the values equal 'valueToReplace' (optional,
% if not given, it consider the first values of each column)
if nargin < 3
    valueToReplace = array(1,:);
elseif isscalar(valueToReplace)
    valueToReplace = repmat(valueToReplace,1,size(array,2));
else
    assert(isrow(valueToReplace),"'valueToReplace' must be a row vector")
end
if isrow(valueNew)
    valueNew = repmat(valueNew,size(array,1),1);
end
if iscolumn(valueNew)
    valueNew = repmat(valueNew,1,size(array,2));
end
assert(isequal(size(array),size(valueNew)),"'valueNew' must be of the same size as 'array'")
array_ = string(array);
valueToReplace = string(valueToReplace);
v2r = "frames:replaceStartBy:defaultValueReplacingMissing:q31vUwi_29o";
if any(array_(:) == v2r), error('Error in data values.'); end
array_(ismissing(array_)) = v2r;
valueToReplace(ismissing(valueToReplace)) = v2r;
b = false(size(array_));
for ii = 1:size(b,2)
    b(:,ii) = array_(:,ii) == valueToReplace(ii);
end
b = logical(cumprod(b,1));
array(b) = valueNew(b);
end
