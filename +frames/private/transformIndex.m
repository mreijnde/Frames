function index = transformIndex(index,type)
arguments
    index  % only occurences are when index is a frames.Index
    type {mustBeTextScalar,mustBeMember(type,["unsorted","sorted","time","duplicate"])}
end
switch type
    case "unsorted"
        index = frames.UniqueIndex(index);
    case "sorted"
        index = frames.SortedIndex(index);
    case "time"
        index = frames.TimeIndex(index);
    case "duplicate"
        index = frames.Index(index);
end
end