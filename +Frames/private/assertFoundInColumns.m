function assertFoundInColumns(x, y)
notin = findNotIn(x, y);
if ~isempty(notin)
    msg = 'Elements ['  + join(string(notin), ', ') + '] are not in columns.';
    error('frames:DataFrame:locCol', msg)
end
end