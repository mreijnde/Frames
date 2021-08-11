function mustBeDFindex(x)
if ~isa(x,'frames.Index')
    if ~isempty(x) && ~(isvector(x) && ~any(ismissing(x)))
        throwAsCaller(MException("frames:validators:mustBeDFindex", ...
            "Value must be a vector or a frames.Index."))
    end 
end
end