function bool = areAligned(varargin)
bool = true;
idx = varargin{1}.index;
for ii = 2:length(varargin)
    if ~isequal(idx,varargin{ii}.index)
        bool = false;
        return
    end
end
end