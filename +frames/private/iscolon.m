function bool = iscolon(x)
bool = strcmp(x,':');
if numel(bool)~=1, bool=false; end
end