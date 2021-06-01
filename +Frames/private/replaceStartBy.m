function array_ = replaceStartBy( array, valueNew, valueToReplace )
% replaceStartBy Replace start values by 'valueNew', if start values equal
%'valueToReplace' (optional)
if nargin < 3
    startValue = array(1,:);
else
    startValue = repmat(valueToReplace,1,size(array,2));
end
array_ = array;
array = string(array);
startValue = string(startValue);
v2r = "frames:replaceStartBy:defaultValueReplacingMissing:q31vUwi_29o";
if any(array(:) == v2r), error('Error in data values.'); end
array(ismissing(array)) = v2r;
startValue(ismissing(startValue)) = v2r;
b = false(size(array));
for ii = 1:size(b,2)
    b(:,ii) = array(:,ii) == startValue(ii);
end
b = logical(cumprod(b));
array_( b ) = valueNew;
end
