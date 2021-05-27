function mustBeDFvector(x)
% ToDo must also be a UniqueIndex
if ~(isempty(x) || isvector(x))
    throwAsCaller(MException("frames:validators:mustBeDFvector", ...
        "Value must be a vector."))
end
end