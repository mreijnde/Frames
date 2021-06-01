function columns = columnsForTable(columns)
%ToDo handle duplicates
if ~istext(columns)
    columns = "Var" + columns;
end
columns = validVariableName(columns);
end