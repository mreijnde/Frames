function mustBeDFindex(x)
% ToDo must also be a UniqueIndex
if ~(isempty(x) || (isvector(x)&&isunique(x)) || isa(x, 'frames.UniqueIndex'))
    throwAsCaller(MException("frames:validators:mustBeDFindex", ...
        "Value must be a unique vector or a frames.UniqueIndex."))
end
end