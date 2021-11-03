function [rows_uniq, rows_uniqInd, val_uniq, val_ind] = uniqueCellRows(data,order)
% get unique row values of cell array
% 
% input: 
%  - data: cell array(Nrows,Ncols)
%  - order: string enum ('stable', 'sorted'), defines numbering order of indices values
%
% output:
%  - rows_uniq:   cell array(Nrows_unique, Ncols) with unique row values
%  - rows_uniqInd array(Nrows_unique) with index to unique row value
%  - val_uniq:    cell (1,Ncols) with array of unique values per column
%  - val_ind:     array(Nrows,Ncols) with index to unique values per column
%
if nargin<2, order="stable"; end
% check input
assert( iscell(data), "needs to be cell array");
% get unique values per dimension
[Nrows, Ncols] = size(data);
val_uniq  = cell(1,Ncols);
val_ind   = zeros(Nrows,Ncols);
for i=1:Ncols
    [val_uniq{i}, ~, val_ind(:,i)] = unique([data{:,i}],order);
end
% get unique rows index
[rows_valind, ~, rows_uniqInd] = unique(val_ind,'rows',order);
% get unique row values as cell(Nrow,Ncol)
Nrows_uniq = size(rows_valind,1);
rows_uniq  = cell(Nrows_uniq ,Ncols);
for i=1:Ncols
    colvalues = arrayfun(@(x) {x}, val_uniq{i}(rows_valind(:,i)));
    rows_uniq(:,i) = colvalues;
end
end