function v = defaultValue(type,len)
if nargin < 2, len = 1; end
switch type
    case 'double'
        v = 1:len;
    case 'string'
        v = "Var" + (1:len);
    case 'cell'
        v = cellstr("Var" + (1:len));
    case 'frames.Index'
        v = frames.Index("Var");
    otherwise
        error('default data type not implemented')
end
end