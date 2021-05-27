classdef Index
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Dependent)
        value
    end
    properties (Access=?frames.DataFrame)
        value_
    end
    
    methods
        function obj = Index(value)
            %UNTITLED4 Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                value {mustBeDFvector} = []
            end
            if isrow(value)
                value = value';
            end
            obj.value = value;
        end
        
        function idx = get.value(obj)
            idx=obj.value_;
        end
        function obj = set.value(obj, value)
            value = obj.valueChecker(value);
            obj.value_ = value;
        end
        
        function pos = positionOf(obj, selector)
            pos = findPositionIn( selector, obj.value );
        end
    end
    
    methods(Access=protected)
        function value = valueChecker(value)
            if ~isunique(value)
                warning('index is not unique')
            end
        end
    end
 
end

