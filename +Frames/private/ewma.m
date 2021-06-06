function y = ewma(data,alpha)
%Compute the exponentially weighted moving average.
% Formula:
% y_0 = data_0
% y_i = alpha .* data_i + (1-alpha) .* y_(i-1)
% NaNs are ignored in the computation, ie they are removed before
% computing.
y = arrayfun(@(x) ewma_(data(:,x),alpha),(1:size(data,2)),UniformOutput=false);
y = cell2mat(y);
end

function y = ewma_(data,alpha)
isvalid = ~isnan(data);
data = data(isvalid);
ema = filter(alpha,[1,alpha-1],data(2:end),(1-alpha).*data(1));
ema = [data(1);ema];
y = NaN(size(data));
y(isvalid) = ema;
end