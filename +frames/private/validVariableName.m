function str = validVariableName(str)
str = string(str);
str = str.replace(' ','_');
str(ismissing(str)) = "";
str = matlab.lang.makeUniqueStrings(matlab.lang.makeValidName( ...
    str,ReplacementStyle='underscore'),{},namelengthmax());
end