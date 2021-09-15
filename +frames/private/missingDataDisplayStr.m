function str = missingDataDisplayStr(value)                
% get display string of missing of datatype of the supplied value
if isnumeric(value) || isduration(value)
    str = "NaN";
elseif isdatetime(value)
    str = "NaT";
else                    
   str = "<missing>";                   
end
end