function col = validColumnsName(col)
if isa(col,'double')
    col = "Var" + string(col);
end
col = validVariableName(col);
col = cellstr(col);
end