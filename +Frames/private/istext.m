function bool = istext(str)
bool = isstring(str) || iscellstr(str) || ischar(str);
end