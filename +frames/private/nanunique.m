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
        replace_value = max( x(~isinf(x)),[],'omitnan')+1;
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
