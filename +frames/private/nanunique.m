function [C,ia,ic]= nanunique(x, varargin)
% modified unique function that threats NaN values not as distinct values.
%
% handle single value (or missing value)
if length(x)==1
    C = x;
    ia = 1;
    ic = 1;
    return;
end

replace_nan = false;
% replace NaN values with magic number if required
if isnumeric(x)
    mask_isnan = isnan(x);
    replace_nan = any(mask_isnan);
    if replace_nan
        replace_value = getUniqueMagicNumber(x);
        x(mask_isnan) = replace_value;
    end
end
% perform unique function
[C,ia,ic] = unique(x, varargin{:});
% replace back NaN value
if replace_nan
    C(C==replace_value) = NaN;
end
end


function value = getUniqueMagicNumber(x)
% get a value not used in array
value = 2147483647; %start with fixed value.... (intmax('int32')-1)
n = 0;
while ismember(value,x)
    % try to find unused number
    value = randi(2147483647);
    n=n+1;
    if n>1e5
        % how unlucky can you be?
        error("could not locate unused magic number");
    end
end
end