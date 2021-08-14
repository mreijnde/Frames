function bool = isSingletonValue(val)
bool = length(val)==1 && ismissing(val);
end