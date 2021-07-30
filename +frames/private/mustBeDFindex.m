function mustBeDFindex(x)
% ToDo unique is expensive
if ~(isa(x,'frames.Index') && x.requireUnique)
    if isa(x,'frames.Index') || ...
            (~isempty(x) && ~isTextScalar(x) && ~(isvector(x) && isunique(x) && ~any(ismissing(x))))
        throwAsCaller(MException("frames:validators:mustBeDFindex", ...
            "Value must be a unique vector or a frames.UniqueIndex."))
    end 
end
end