function mustBeDFindex(x)
% ToDo unique is expensive
if ~isa(x,'frames.Index')
    if ~isempty(x) && ~(isvector(x) && isunique(x) && ~any(ismissing(x)))
        throwAsCaller(MException("frames:validators:mustBeDFindex", ...
            "Value must be a unique vector or a frames.Index."))
    end 
end
end