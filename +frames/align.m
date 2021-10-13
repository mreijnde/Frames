function varargout = align(dfs)
%ALIGN align frames to each others and ouputs each of them aligned
arguments(Repeating)
    dfs frames.DataFrame
end
warning('off','frames:Index:notUnique')
concatenate = [dfs{:}];  % align
warning('on','frames:Index:notUnique')
colID = 1;
for ii=1:nargin  % split into varargout
    nbCols = size(dfs{ii}.data_,2);
    varargout{ii} = concatenate.iloc_(':',colID:colID+nbCols-1); %#ok<AGROW>
    colID=colID+nbCols;
end

