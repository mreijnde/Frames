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
    otherwise
        error( 'empty data type not implemented' )
end
end