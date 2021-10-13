function bool = isunique(x,varargin)
bool = numel(x)==numel(unique(x,varargin{:}));
end