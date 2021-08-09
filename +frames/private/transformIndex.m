function index = transformIndex(index,type)
arguments
    index  % only occurences are when index is a frames.Index
    type {mustBeTextScalar,mustBeMember(type,["unique","sorted","duplicate"])}
end
switch type
    case "unique"
        index = frames.Index(index,Unique=true);
    case "sorted"
        index = frames.Index(index,UniqueSorted=true);
    case "duplicate"
        index = frames.Index(index);
end
end