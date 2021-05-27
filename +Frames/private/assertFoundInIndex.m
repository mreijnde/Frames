function assertFoundInIndex(x, y)
notin = findNotIn(x, y);
if ~isempty(notin)
    msg = 'Elements ['  + join(string(notin), ', ') + '] are not in index.';
    error('frames:DataFrame:locInd', msg)
end
end