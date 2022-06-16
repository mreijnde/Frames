function bool = isIndex(varargin)
bool = false(1,nargin);
for i = 1:nargin
    obj = varargin{i};
    bool(i) = isa(varargin{i},'frames.Index');
end
end
