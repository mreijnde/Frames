function mustBeDFindex(x)
% ToDo unique is expensive
if ~isa(x,'frames.Index')
    if ~isempty(x) && ~isTextScalar(x) && ~(isvector(x) && isunique(x) && ~any(ismissing(x)))
        throwAsCaller(MException("frames:validators:mustBeDFindex", ...
            "Value must be a unique vector."))
    end 
end
end