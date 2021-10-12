function str = validVariableName(str,allowRepeating)
str = string(str);
str = str.replace(' ','_');
str(ismissing(str)) = "";
str = matlab.lang.makeValidName(str,ReplacementStyle='underscore');
if ~(nargin==2) && ~allowRepeating
    str = matlab.lang.makeUniqueStrings(str,{},namelengthmax());
end
end