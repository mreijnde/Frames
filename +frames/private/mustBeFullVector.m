function mustBeFullVector(x)
if ~(isa(x,'frames.Index') || (isvector(x) && ~any(ismissing(x))))
    throwAsCaller(MException("frames:validators:mustBeFullVector", ...
        "Value must be a vector or a frames.Index."))
end
end