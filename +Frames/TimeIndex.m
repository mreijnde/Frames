classdef TimeIndex < frames.SortedIndex
    properties
        format {mustBeTextScalar} = "dd-MMM-yyyy"
    end
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    methods
        function obj = TimeIndex(value,nameValue)
            %UNTITLED4 Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                value
                nameValue.name = ""
                nameValue.format = "dd-MMM-yyyy"
            end
            if isdatetime(value); nameValue.format = value.Format; end
            obj = obj@frames.SortedIndex(value,name=nameValue.name);
            obj.format = nameValue.format;
        end
        
        function pos = positionOf(obj,selector)
            if isTextScalar(selector) && contains(selector,':')
                selector = obj.getTimerange(selector);
            end
            if isa(selector,'timerange')
                tt = timetable(obj.value);
                [~,whichRows] = overlapsrange(tt,selector);
                ids = (1:length(obj.value_))';
                pos = ids(whichRows);
                return
            end
            pos = positionOf@frames.SortedIndex(obj,selector);
        end
        
        
    end
    methods(Access = protected)
        function value = valueChecker(obj,value)
            if ~isunique(value) || ~issorted(value)
                error('index is not unique and sorted')
            end
            value = obj.getValue_from(value);
        end
        
        function value = getValue(obj)
            value = datetime(obj.value_,ConvertFrom='datenum',Format=obj.format);
        end
        function value = getValue_from(obj,value)
            value = getValue_from@frames.SortedIndex(obj,value);
            switch class(value)
                case 'datetime'
                case {'string','cell'}
                    value = datetime(value,Format=obj.format);
                case 'double'
                    return
                otherwise
                    error('type of time index not recognized')
            end
            value = datenum(value);
        end
        function selector = getTimerange(obj,selector)
            splitted = split(selector,':');
            if length(splitted)==3
                format_ = splitted{3};
                splitted = splitted(1:2);
            elseif length(splitted)==2
                format_ = obj.format;
            else
                error('timerange selection from string must be of type "dateStart:dateEnd[:format]"')
            end
            selector = timerangeFromString(splitted,format_);
        end
    end
    
end

