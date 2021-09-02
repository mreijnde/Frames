function q = emvar(data,alpha)
%Compute the exponentially weighted moving variance.
% implementation of https://en.wikipedia.org/wiki/Moving_average#Exponentially_weighted_moving_variance_and_standard_deviation
% emvar_i = (1-alpha)*(emvar_(i-1) + alpha*d^2)
% NaNs are ignored in the computation, ie they are removed before
% computing.
q = arrayfun(@(x) emvar_(data(:,x),alpha),1:size(data,2),'UniformOutput',false);
q = cell2mat(q);
end

function out = emvar_(data,alpha)
minWindow = ceil(1./alpha-1);  % center of mass
isvalid = ~isnan(data);
data = data(isvalid);

% initialisation of var and mean
initialData = data(1:minWindow);
data(1:minWindow) = mean(initialData);
emvar0 = var(initialData,1);  % one could choose the unbiased version, but it can be large if alpha is large. Wikipedia starts with emvar0 = 0.

ema = frames.internal.ewma(data,alpha);
d1 = data - frames.internal.shift(ema,1);
d1 = d1(minWindow+1:end);
d2 = d1 .^ 2;

emvar = filter(alpha.*(1-alpha),[1,(alpha-1)],d2,(1-alpha).*emvar0);
emvar = [NaN(size(initialData));emvar];

out = NaN(size(data));
out(isvalid) = emvar;
end