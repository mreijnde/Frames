function mustBeSorted(x)
if ~(isunique(x))
    throwAsCaller(MException("frames:validators:mustBeSorted", ...
        "Value must contain sorted elements."))
end
end