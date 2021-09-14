function columns = columnsForTable(columns)
% convert DataFrame columns to string colums for table
if isnumeric(columns)
    columns = compose('%.10g',columns);
elseif isscalar(columns) && ismissing(columns)
    columns = missingDataDisplayStr(columns);
else
    columns =cellstr(string(columns));
end
end