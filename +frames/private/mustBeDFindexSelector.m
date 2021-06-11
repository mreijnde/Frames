function mustBeDFindexSelector(x)
if ~(islogical(x) || isa(x,'timerange'))
    mustBeDFindex(x)
end
