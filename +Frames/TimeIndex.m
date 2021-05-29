classdef TimeIndex < frames.OrderedIndex
    properties
        format {mustBeTextScalar} = "dd.MM.yyyy"
    end
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    methods
        function obj = TimeIndex (value, nameValue)
            %UNTITLED4 Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                value
                nameValue.name
                nameValue.format = "dd.MM.yyyy"
            end
            if isdatetime(value); nameValue.format = value.Format; end
            obj = obj@frames.OrderedIndex(value,name=nameValue.name);
            obj.format = nameValue.format;
        end
    end
    methods (Access = protected)
        function value = getValue(obj)
            value = datetime(obj.value_, ConvertFrom='datenum', Format=obj.format);
        end
    end
    
    methods(Access=protected)
        function value = valueChecker(obj, value)
            if ~isunique(value) || ~issorted(value)
                error('index is not unique and sorted')
            end
            switch class(value)
                case 'datetime'
                case {'string','cell'}
                    value = datetime(value, Format=obj.format);
                case 'double'
                    return
                otherwise
                    error('type of time index not recognized')
            end
            value = datenum(value);
        end
    end
    
end