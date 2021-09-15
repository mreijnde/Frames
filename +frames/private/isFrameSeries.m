function bool = isFrameSeries(varargin)
bool = false(1,nargin);
for ii = 1:nargin
    obj = varargin{ii};
    bool(ii) = frames.internal.isFrame(obj) && (obj.rowseries || obj.colseries);
end
end
