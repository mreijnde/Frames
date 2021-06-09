function bool = isunique(x)
bool = numel(x)==numel(unique(x));
end