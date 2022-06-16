function index = transformIndex(index,type)
arguments
    index  % only occurences are when index is a frames.Index
    type {mustBeTextScalar,mustBeMember(type,["unique","sorted","duplicate"])}
end
switch type
    case "unique"
        index.requireUniqueSorted = false;
        index.requireUnique = true;        
    case "sorted"
        index.requireUniqueSorted = true;                
    case "duplicate"
        index.requireUniqueSorted = false;
        index.requireUnique = false;                
end
end