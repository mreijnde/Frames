function cc = compoundChange(relativeChange,changeType,base)
arguments
    relativeChange (:,:)
    changeType {mustBeTextScalar,mustBeMember(changeType,["simple","log"])} = "simple"
    base double = 1
end

switch changeType
    case 'simple'
        r = relativeChange + 1;
        cc = nancumprod(r);
    case 'log'
        lperf = nancumsum(relativeChange);
        cc = exp(lperf);
end
cc = replaceMissingStartBy(cc,1);
cc = cc .* base;
end


