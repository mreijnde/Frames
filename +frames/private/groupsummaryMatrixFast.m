function [B, groupID, groupCount, groupFirstInd] = groupsummaryMatrixFast(A, groupid, func, dim, funcAggrDim, apply2single, vectorize, convGroupInd)
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
%   convGroupInd:  boolean, convert output of func, which can be interpreted as a local index position
%                     within aggregation group to absolute matrix index position (default false)
%                     (usage to convert the local position output, of 2nd output max() and min(), to matrix index)
%
% OUTPUT:
%    B:             aggregated dataoutput (Ngroups, Ncols) or (Nrows, Ngroups), sorted by groupid                                       
%    groupID:       array(Ngroups) of groupids as in used in B
%    groupCount:    number of aggregated elements per groupid
%    groupFirstInd: array(Ngroups) with positon index to first occurance of groupid
%
if nargin<4, dim=1; end               % default aggregate rows of matrix A
if nargin<5, funcAggrDim=1; end       % default func aggregate direction: rows
if nargin<6, apply2single = true; end % default apply function to groups with single value
if nargin<7, vectorize=true; end      % default use vectorization
if nargin<8, convGroupInd=false; end  % default off

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
[groupID, groupCount, groupFirstInd, groupStartRef, indicesList] = getIndicesForEachGroup(groupid);
Ngroups = length(groupID);
% shortcut in case of only single values
if isempty(groupCount)
    if ~convGroupInd
        % sorted vector
        if dim==1
           B = A(groupFirstInd,:);
        else
           B = A(:,groupFirstInd);
        end
    else
        % index position output
        B = groupFirstInd;
    end
    return
end

% calc groups with more then 1 row
maskMulti = groupCount>1;
ind_maskSingle = find(~maskMulti);
ind_maskMulti = find(maskMulti);

% output var
if dim==1
   B = zeros(Ngroups, size(A,2));
else
   B = zeros(size(A,1), Ngroups);
end

% get single values (groups of 1)
if dim==1
    Bs = A(groupFirstInd(ind_maskSingle),:);
else
    Bs = A(:, groupFirstInd(ind_maskSingle));
end
if apply2single
   for j=1:numel(Bs)       
       Bs(j)=func_(Bs(j));
   end
end
if dim==1
   B(ind_maskSingle,:) = Bs;
else
   B(:,ind_maskSingle) = Bs;
end

% calc aggregated data for groups
for igr = 1:length(ind_maskMulti)
    grInd = ind_maskMulti(igr);
    indices = indicesList(groupStartRef(grInd):groupStartRef(grInd)+groupCount(grInd)-1);
    
    % get values in group to aggregate
    if dim==1            
       values =  A(indices,:);
    else                
       values =  A(:,indices);
    end
    
    % calc aggregation value
    if  vectorize
        % vectorized calc method (for rows/columns in non-aggregation direction)
        valuesOut = func_( values );
    else
        % calc individual per column/row
        if dim==1
            valuesOut = values(1,:);
            for j=1:size(values,2)
                valuesOut(j)=func_(values(:,j));
            end
        else
            valuesOut = values(:,1);
            for j=1:size(values,1)
                valuesOut(j)=func_(values(j,:));
            end
        end
    end   
    
    % assign values
    if dim==1
        B(grInd,:) = valuesOut;
    else
        B(:,grInd) = valuesOut;
    end
end           


% special case: convert output of func which outputs position index in local aggregation group
% (eg 2nd output of min() or max()) to absolute index of given matrix dimension
if convGroupInd
    for igr = 1:Ngroups      
        indices = indicesList(groupStartRef(igr):groupStartRef(igr)+groupCount(igr)-1);
        if dim==1
           B(igr,:) = indices(B(igr,:));
        else
           B(:,igr) = indices(B(:,igr));
        end
    end
end

end
