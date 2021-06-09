function dOut = interpMissing(dIn)
dOut = fillmissing(dIn,'linear',1,'EndValues','none');
end