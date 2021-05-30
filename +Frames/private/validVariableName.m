function str = validVariableName(str)
str = str.replace(' ','_');
str = matlab.lang.makeUniqueStrings(matlab.lang.makeValidName( ...
    str,ReplacementStyle='underscore'),{},namelengthmax());
end