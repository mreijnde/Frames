function mustBeSorted(x)
if ~(issorted(x))
    throwAsCaller(MException("frames:validators:mustBeSorted", ...
        "Value must contain sorted elements."))
end
end