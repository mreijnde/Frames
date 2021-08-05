function bool = isFrame(varargin)
bool = false(1,nargin);
for ii = 1:nargin
    bool(ii) = isa(varargin{ii},'frames.DataFrame');
end
end
