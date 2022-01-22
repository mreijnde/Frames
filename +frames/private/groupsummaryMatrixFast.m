function [B, BG, BC, BGind] = groupsummaryMatrixFast(A, groupid, func, dim, funcAggrDim, apply2single, vectorize)
% aggregate data in rows or columns of matrix A with function func grouped by groupid
%
%  - Similar to "groupsummary(A, groupid, func)" but significant faster (2-20 times) for larger datasets,
%    (specifically with higher number of columns or unique groups).
%  - Only supports groupid as vector, not matrix or cell array.
%  - Additonal optional output/inputs to support aggregation of columns
%
% INPUT:
%   A:             data matrix(Nrows,Ncols) with data to aggregate by rows
%
%   groupid:       vector with groupid for each row in A (numeric or string)
%
%   func:          function handle to aggregate data (eg. @sum) 
%
%   dim:           dimension to aggregate (1:rows default, 2=columns)
%
%   funcAggrDim:   dimension in which given function aggregates (1:rows default, 2=columns)
%
%   apply2single:  boolean to select if function is applied to groups with a single values (default true) 
%
%   vectorizeCols: boolean to select vectorized mode for speedup (default: true)
%                     for vectorization to work, function should only aggregate in dimension given by
%                     func_aggr_dim, but not in the other dimension.               
%                    (behavior will be checked, if funciton not compatible, it will be disabled)  
%
%
% OUTPUT:
%    B:     aggregated dataoutput (Ngroups, Ncols), sorted by groupid
%    BG:    array(Ngroups) of groupids as in used in B
%    BC:    number of aggregated elements per groupid
%    BGind: array(Ngroups) with positon index to first occurance of groupid
%
if nargin<4, dim=1; end               % default aggregate rows of matrix A
if nargin<5, funcAggrDim=1; end     % default func aggregate direction: rows
if nargin<6, apply2single = true; end % default apply function to groups with single value
if nargin<7, vectorize=true; end      % default use vectorization

% check input
assert(dim==1 || dim==2, "invalid dim value (%i), should be 1 or 2", dim);
assert(funcAggrDim==1 || funcAggrDim==2, "invalid func_aggregate_dim value (%i), should be 1 or 2", funcAggrDim);
assert(isvector(groupid) && length(groupid)==size(A,dim), 'groupsummaryMatrixFast:invalidInputSize', ...
        "groupid is not a vector with same number of elements as in aggregation dimension of matrix A.");

% check function handle aggregation behavior
if funcAggrDim==1
    assert( length(func([1;2]))==1, 'groupsummaryMatrixFast:invalidFunction', ...
      "Incompatible function, supplied function '%s' does not aggregate over row dimension " + ...
      "(convert column vector to scalar) which is required when func_aggregate_dim=1.", functions(func).function);     
    if vectorize && ~isequal( size(func([1,2;3,4])), [1 2])
        vectorize = false;
        warning('groupsummaryMatrixFast:vectorizeNotSupported', ...
            "Supplied function '%s' does not support column wise vectorization. \nInput array(Nrows,Ncols) " + ...
            "should give aggregated output array(1,Ncols) when func_aggregate_dim is set to 1 (default) " + ...                
            "==> Falling back to slower non-vectorized method.", functions(func).function);
    end
elseif funcAggrDim==2
    assert( length(func([1 2]))==1, 'groupsummaryMatrixFast:invalidFunction', ...
      "Incompatible function, supplied function '%s' does not aggregate over column dimension " + ...
      "(convert row vector to scalar) which is required when func_aggregate_dim=2", functions(func).function);      
    if vectorize && ~isequal( size(func([1,2;3,4])), [2 1])
        vectorize = false;
        warning('groupsummaryMatrixFast:vectorizeNotSupported', ...
            "Supplied function '%s' does not support row wise vectorization. \nInput array(Nrows,Ncols) " + ...
            "should give aggregated output array(Nrows,1) when func_aggregate_dim is set to 2 " + ...                
            "==> Falling back to slower non-vectorized method.", functions(func).function);
    end        
end

% align function aggregation direction with required dim
if dim==funcAggrDim
    func_ = func;
else
    func_ = @(x) func(x')';
end

% get position indices for each group
[ind_cell, BG, BC, BGind] = getIndicesForEachGroup(groupid);

% calc groups with more than 1 row
mask_multi = BC>1;

% allocate output
if dim==1
   B_cell = cell(length(ind_cell),1);   
else
   B_cell = cell(1,length(ind_cell));   
end

% extract original values for groups with only 1 single value (if option selected)
if ~apply2single
    if dim==1
       B_cell(~mask_multi) = cellfun(@(ind) A(ind,:), ind_cell(~mask_multi), 'UniformOutput', false);
    else
       B_cell(~mask_multi) = cellfun(@(ind) A(:,ind), ind_cell(~mask_multi), 'UniformOutput', false);
    end
end

% calc aggregated data
if  vectorize
    % vectorized calc method      
    if dim==1                  
        B_cell(mask_multi)  = cellfun(@(ind) func_(A(ind,:)), ind_cell(mask_multi), 'UniformOutput', false);
    else        
        B_cell(mask_multi)  = cellfun(@(ind) func_(A(:,ind)), ind_cell(mask_multi), 'UniformOutput', false);
    end

    if apply2single
        % for groups with only single value, apply function to each element separately (using arrayfun)
        % (a workaround as most standard functions like eg. sum(), will aggregate over 2nd dimension
        % if input is a rowvector)
        if dim==1
            B_cell(~mask_multi) = cellfun(@(ind) arrayfun(func_, A(ind,:)')', ... 
                                          ind_cell(~mask_multi), 'UniformOutput', false);   
        else
            B_cell(~mask_multi) = cellfun(@(ind) arrayfun(func_, A(:,ind)')', ... 
                                          ind_cell(~mask_multi), 'UniformOutput', false);   
        end
    end
else
    % calc individual per column/row (by nested cellfun and storing separate columns/rows in cell array by num2cell)
    if dim==1
        B_cell(mask_multi) = cellfun(@(ind) cellfun(func_, num2cell(A(ind,:),1)), ...
                                    ind_cell(mask_multi), 'UniformOutput', false);        
    else
        B_cell(mask_multi) = cellfun(@(ind) cellfun(func_, num2cell(A(:,ind),2)), ...
                                    ind_cell(mask_multi), 'UniformOutput', false);        
    end
    if apply2single
        if dim==1      
            B_cell(~mask_multi) = cellfun(@(ind) cellfun(func_, num2cell(A(ind,:),1)), ...
                                    ind_cell(~mask_multi), 'UniformOutput', false);
        else    
            B_cell(~mask_multi) = cellfun(@(ind) cellfun(func_, num2cell(A(:,ind),2)), ...
                                    ind_cell(~mask_multi), 'UniformOutput', false);
        end
    end    
    
end

% convert cell output to a single matrix
B = cell2mat(B_cell);
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