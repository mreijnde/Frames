function index = transformIndex(index,type)
arguments
    index  % only occurences are when index is a frames.Index
    type (1,1) {mustBeMember(type,["unsorted","sorted","time"])}
end
if strcmp(type,"unsorted")
    index = frames.UniqueIndex(index);
elseif strcmp(type,"sorted")
    index = frames.SortedIndex(index);
elseif strcmp(type,"time")
    index = frames.TimeIndex(index);
end
end