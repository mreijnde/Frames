function notin = findNotIn(x, y)
isin = ismember(x, y);
notin = x(~isin);
end