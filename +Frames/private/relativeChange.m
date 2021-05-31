function [pctChg,idx] = relativeChange(data,changeType,lag,overlapping)
arguments
    data (:,:)
    changeType {mustBeTextScalar,mustBeMember(changeType,["simple","log"])} = "simple"
    lag (1,1) {mustBeInteger, mustBePositive} = 1
    overlapping (1,1) logical = true
end

isna = ismissing(data);
data = fillmissing(data,'previous');
pctChg = NaN(size(data));
if strcmp(changeType,'simple')
    pctChg(1+lag:end,:) = data(1+lag:end,:) ./ data(1:end-lag,:) - 1;
elseif strcmp(changeType,'log')
    logData = log(data);
    pctChg(1+lag:end,:) = logData(1+lag:end,:) - logData(1:end-lag,:);
end

pctChg(isna) = NaN;
if ~overlapping
    idx = fliplr(size(pctChg,1):-lag:1);
    pctChg = pctChg(idx,:);
else
    idx = 1:size(pctChg,1);
end
end