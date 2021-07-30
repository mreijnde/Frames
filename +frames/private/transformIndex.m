function index = transformIndex(index,type)
arguments
    index  % only occurences are when index is a frames.Index
    type {mustBeTextScalar,mustBeMember(type,["unsorted","sorted","time","duplicate"])}
end
switch type
    case "unsorted"
        index = frames.Index(index,Unique=true);
    case "sorted"
        index = frames.Index(index,UniqueSorted=true);
    case "time"
        index = frames.TimeIndex(index);
    case "duplicate"
        index = frames.Index(index);
end
end