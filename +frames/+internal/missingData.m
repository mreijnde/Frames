function d = missingData(type)
switch type
    case 'cell'
        d = {''};
    case 'logical'
        d = false;
    otherwise
        f = str2func(type);
        d = f(missing);
end
end