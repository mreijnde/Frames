function bool = isTextScalar(text)
bool = isCharRowVector(text) || (isstring(text) && isscalar(text));
end

function bool = isCharRowVector(text)
    bool = ischar(text) && (isrow(text) || isequal(size(text),[0 0]));
end