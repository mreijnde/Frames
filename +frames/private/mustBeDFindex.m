function mustBeDFindex(x)
% ToDo must also be a UniqueIndex
if ~isa(x, 'frames.UniqueIndex')
    if isa(x,'frames.Index') || ...
            (~isempty(x) && ~isTextScalar(x) && ~(isvector(x) && isunique(x)))
        throwAsCaller(MException("frames:validators:mustBeDFindex", ...
            "Value must be a unique vector or a frames.UniqueIndex."))
    end 
end
end