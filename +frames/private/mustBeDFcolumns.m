function mustBeDFcolumns(x)
if ~isa(x, 'frames.UniqueIndex')
    if ~isempty(x)
        if ~(isvector(x) && ~any(ismissing(x)))
    throwAsCaller(MException("frames:validators:mustBeDFcolumns", ...
        "Value must be a vector or a frames.Index."))
        end
    end
end
end
