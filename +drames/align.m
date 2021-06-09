function varargout = align(dfs)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here
arguments(Repeating)
    dfs frames.DataFrame
end
warning('off','frames:Index:notUnique')
concatenate = [dfs{:}];  % align
warning('on','frames:Index:notUnique')
colID = 1;
for ii=1:nargin  % split into varargout
    nbCols = length(dfs{ii}.columns);
    varargout{ii} = concatenate.iloc(':',colID:colID+nbCols-1); %#ok<AGROW>
    colID=colID+nbCols;
end

