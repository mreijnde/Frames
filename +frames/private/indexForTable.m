function indexOut = indexForTable(index)
if isnumeric(index)
    indexOut = compose('%.10g',index);
elseif isscalar(index) && ismissing(index)
    indexOut = missingDataDisplayStr(index);    
else
    indexOut=cellstr(string(index));
end
indexOut=matlab.lang.makeUniqueStrings(indexOut,{},namelengthmax());
end

