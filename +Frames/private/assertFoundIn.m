function assertFoundIn(x, y)
notin = findNotIn(x, y);
if ~isempty(notin)
    msg = 'Elements ['  + join(string(notin), ', ') + '] are not in second list.';
    error('frames:assertFoundIn', msg)
end
end