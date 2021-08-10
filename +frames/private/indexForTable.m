function indexOut = indexForTable(index)
indexOut=cellstr(string(index));
indexOut=matlab.lang.makeUniqueStrings(indexOut,{},namelengthmax());
end

