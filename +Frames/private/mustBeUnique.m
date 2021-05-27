function mustBeUnique(x)
if ~(isunique(x))
    throwAsCaller(MException("frames:validators:mustBeUnique", ...
        "Value must contain unique elements."))
end
end