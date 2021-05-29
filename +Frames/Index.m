classdef Index
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name {mustBeTextScalar} = ""
    end
    properties (Dependent)
        value
    end
    properties (Access={?frames.UniqueIndex, ?frames.DataFrame})
        value_
    end
    
    methods
        function obj = Index(value, nameValue)
            %UNTITLED4 Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                value {mustBeDFvector} = []
                nameValue.name = ""
            end
            if isrow(value)
                value = value';
            end
            obj.value = value;
            obj.name = nameValue.name;
        end
        
        function idx = get.value(obj)
            idx = obj.getValue();
        end
        function obj = set.value(obj, value)
            value = obj.valueChecker(value);
            if isrow(value)
                value = value';
            end
            obj.value_ = value;
        end
        
        function len = length(obj)
            len = length(obj.value_);
        end
        
        function pos = positionOf(obj, selector)
            pos = findPositionIn(selector, obj.value);
        end
        function pos = positionIn(obj, target)
            pos = findPositionIn(obj.value, target);
        end
    end
    
    methods(Access=protected)
        function value = getValue(obj)
            value = obj.value_;
        end
    end
    methods(Static, Access=protected)
        function value = valueChecker(value)
            if ~isunique(value)
                warning('index is not unique')
            end
        end
    end
 
end

