function bool = areAligned(varargin)
bool = true;
idx = varargin{1}.rows;
for ii = 2:length(varargin)
    if ~isequal(idx,varargin{ii}.rows)
        bool = false;
        return
    end
end
end