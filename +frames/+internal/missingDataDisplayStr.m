function str = missingDataDisplayStr(value)                
% get display string for given missing datatype
if isnumeric(value) || isduration(value)
    str = "NaN";
elseif isdatetime(value)
    str = "NaT";
else                    
   str = "<missing>";                   
end
end