function [groups, groupCount, groupInd, groupStartPos, indicesList, groupidInd] = getIndicesForEachGroup(groupid)
% get position indices for each unique group required for aggregation
%
% input: 
%    groupid: vector with groupids (numeric or strings)
%
% output:
%    groups:         array with groupid for each group 
%    groupCount:     array with number of elements per group
%    groupInd:       array with position index to first occurance of groupid for each group
%    groupStartPos:  array with start index of each group in indicesList output
%    indicesList:    array with ordered list of indices to assign in sequence to groups
%    groupidInd      array with for each item in groupid corresponding group index
[groups, groupInd, groupidInd] = unique(groupid,'sorted');
if length(groups)==length(groupid)
    % all single values, no groups ==> shortcut for performance
    groupCount = [];     
    groupStartPos = [];
    indicesList = [];
    return    
end
[~,indicesList] = sort(groupidInd);
groupCount = histc(groupidInd, 1:max(groupidInd)); %#ok<HISTC>
groupStartPos = cumsum(groupCount) - groupCount + 1;
end
