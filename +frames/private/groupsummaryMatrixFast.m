function [B, BG, BC, BGind] = groupsummaryMatrixFast(A, groupid, func, apply2single, vectorizeCols)
% aggregate data in rows of matrix A with function func grouped by groupid
%
%  - Similar to "groupsummary(A, groupid, func)" but significant faster (2-20 times) for larger datasets,
%    (specifically with higher number of columns or unique groups).
%  - Only supports groupid as vector, not matrix or cell array.
%  - Additonal optional output/inputs
%
% INPUT:
%    A:            data matrix(Nrows,Ncols) with data to aggregate by rows
%
%    groupid:      vector with groupid for each row in A (numeric or string)
%
%    func:         function handle to aggregate data (eg. @sum) 
%                  remark: for performance, function should support vectorization for columns
%                      a input (Nrows,Ncols) should give output array(1,Ncols)
%                      If not, a slower non-vectorized method will be used as fallback.
%
%   apply2single:  boolean to select if function is applied to groups with a single values (default true) 
%
%   vectorizeCols: boolean to select vectorized mode for columns (default: true)
%
%
% OUTPUT:
%    B:     aggregated dataoutput (Ngroups, Ncols), sorted by groupid
%    BG:    array(Ngroups) of groupids as in used in B
%    BC:    number of aggregated elements per groupid
%    BGind: array(Ngroups) with positon index to first occurance of groupid
%
if nargin<4, apply2single = true; end
if nargin<5, vectorizeCols = true; end

assert(isvector(groupid) && length(groupid)==size(A,1), 'groupsummaryMatrixFast:invalidInputSize', ...
    "groupid is not a vector with same number of elements as rows in matrix A");

% check function handle
assert( length(func([1;2]))==1, 'groupsummaryMatrixFast:invalidFunction', ...
      "Incompatible function, supplied function '%s' does not aggregate columns to single scalar value.", ...
      functions(func).function); 
if vectorizeCols
    % check vectorized behavior of supplied function
    if ~isequal( size(func([1,2;3,4])), [1 2])
        vectorizeCols = false;
        warning('groupsummaryMatrixFast:vectorizeColsNotSupported', ...
                "Supplied function '%s' does not support column wise vectorization. Input array(Nrows,Ncols) " + ...
                "should give output array(1,Ncols) with aggregated column values. Falling back to slower " + ...
                "non-vectorized method.", functions(func).function);
    end
end

% get position indices for each group
[ind_cell, groups, groupCount, groupInd] = getIndicesForEachGroup(groupid);

% calc groups with more than 1 row
mask_multi = groupCount>1;

% allocate output
B_cell = cell(length(ind_cell),1);   

% extract original values for groups with only 1 row (if required)
if ~apply2single
    % do no apply function to single values (keep orignal)
    B_cell(~mask_multi) = cellfun(@(ind) A(ind,:), ... 
                                  ind_cell(~mask_multi), 'UniformOutput', false);
end

% calc aggregated data
if  vectorizeCols
    % column vectorized method           
    B_cell(mask_multi)  = cellfun(@(ind) func(A(ind,:)), ... 
                                  ind_cell(mask_multi), 'UniformOutput', false);
    
    if apply2single
        % for groups with only single row, apply function to each element separately (using arrayfun)
        % (a workaround as most standard functions like eg. sum(), will aggregate over 2nd dimension
        % if input is a rowvector)
        B_cell(~mask_multi) = cellfun(@(ind) arrayfun(func, A(ind,:)')', ... 
                                      ind_cell(~mask_multi), 'UniformOutput', false);   
    end
else
    % perform calculation on columns seperately (by storing separate columns in cell array by num2cell)
    B_cell(mask_multi) = cellfun(@(ind) cellfun(func, num2cell(A(ind,:),1)), ...
                                ind_cell(mask_multi), 'UniformOutput', false);
    if apply2single
        B_cell(~mask_multi) = cellfun(@(ind) cellfun(func, num2cell(A(ind,:),1)), ...
                                ind_cell(~mask_multi), 'UniformOutput', false);
    end
end

% convert cell output to a single matrix and collect outputs
B = cell2mat(B_cell);
BG = groups;
BC = groupCount;
BGind = groupInd;
end



function [ind_cell, groups, groupCount, groupInd] = getIndicesForEachGroup(groupid)
% get all position indices for each unique group in a cell array
% with a cell for each unique group id
%
% input: 
%    groupid:    vector with groupids (numeric or strings)
%
% output:
%    ind_cell:    cell array with position indices per group
%    groups:      array with groupid for each group
%    groupcount:  array with number of elements per group
%    groupind:    array with positon index to first occurance of groupid for each group
%
[groups, groupInd, id] = unique(groupid,'sorted');
[~,posind] = sort(id);
groupCount = histc(id, 1:max(id)); %#ok<HISTC>
ind_cell = mat2cell(posind(:),groupCount,1);
end