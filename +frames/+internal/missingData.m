function d = missingData(type)
switch type
    case 'cell'
        d = {''};
    case 'logical'
        d = false;
    case 'frames.Index'
        d = frames.Index(missing, Singleton=true);
    otherwise
        f = str2func(type);
        d = f(missing);
end
end