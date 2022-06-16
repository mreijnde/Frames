function [out, outind] = expandCombinationsCell( cellinput, orderColumnMajor)
% EXPANDCOMBINATIONSCELL create a 2d array based on the combinations per row specified in the cell array.
%
% for example:
%
%   expandCombinationsCell( { 1, 11, 111 ; ...
%                           [2 3], [22 33], 222})
%       =  [ 1  11  111; ...
%            2  22  222; ...
%            2  33  222; ...
%            3  22  222; ...
%            3  33  222 ]
%
%
% INPUT: 
%    cellinput:         2d cell array (Nrows, Ndim) with each cell scalar or vector
%    orderColumnMajor:  logical, expand with column-major ordering (true)
%                                           or row-major ordering (false, default)
%
% OUTPUT:
%   2d array (Nrows_expanded, Ndim) with the rows expanded to multiple rows in case of multiple values per cell.
%    
%
if nargin<2, orderColumnMajor=false; end
% get number of options
[Nrows,Ndims] = size(cellinput);
Noptions = cellfun(@numel, cellinput);
NoptionsTot = prod(Noptions,2);
% get multiplication factors
onevec = ones(Nrows,1);
if orderColumnMajor
    % column-major ordered index
    repetitons = cumprod( [Noptions(:,2:end) onevec], 2,'reverse');
else
    % row-major ordered index
    repetitons = cumprod( [onevec Noptions(:,1:end-1)] ,2);
end
% calc expanded cell
NrowsOut = sum(NoptionsTot);
out = zeros(NrowsOut, Ndims);
outind = zeros(NrowsOut, 1);
irowOut = 1;
% assign values with expansion
for irow = 1:Nrows
    NvalueOut = NoptionsTot(irow);
    if NvalueOut>0        
        for idim = 1:Ndims
            value = cellinput{irow,idim};
            if NvalueOut==1
                % no expansion required
                out(irowOut,idim) = value;
            else
                % expand values to all combinations
                Nrepmat = repetitons(irow,idim);
                Nrepelem = NoptionsTot(irow) / Nrepmat / length(value);
                valueOut =  repmat( reshape(repelem(value, Nrepelem),[],1) ,Nrepmat,1);
                out(irowOut:irowOut+NvalueOut-1,idim) = valueOut;
            end                   
        end
        outind(irowOut:irowOut+NvalueOut-1) = irow;
        irowOut = irowOut+NvalueOut;
    end    
end
end
