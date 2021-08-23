function d = missingData(type)
switch type
    case 'double'
        d = NaN;
    case 'string'
        d = string(missing);
    case 'cell'
        d = {''};
    case 'logical'
        d = false;
    case 'duration'
        d = duration(missing);
    otherwise
        error('missing data type not implemented')
end
end