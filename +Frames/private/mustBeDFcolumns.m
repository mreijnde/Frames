function mustBeDFcolumns(x)
if ~(isempty(x) || isvector(x) || isa(x, 'frames.Index'))
    throwAsCaller(MException("frames:validators:mustBeDFcolumns", ...
        "Value must be a vector or a frames.Index."))
end
end
