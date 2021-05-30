classdef Index
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name {mustBeTextScalar} = ""
    end
    properties(Dependent)
        value
    end
    properties(Access={?frames.UniqueIndex,?frames.DataFrame})
        value_
    end
    
    methods
        function obj = Index(value,nameValue)
            %UNTITLED4 Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                value {mustBeDFvector} = []
                nameValue.name = ""
            end
            if isa(value,'frames.Index')
                nameValue.name = value.name;
                value = value.value;
            end
            obj.value = value;
            obj.name = nameValue.name;
        end
        
        function idx = get.value(obj)
            idx = obj.getValue();
        end
        function obj = set.value(obj,value)
            value = obj.valueChecker(value);
            if isrow(value)
                value = value';
            end
            obj.value_ = value;
        end
        
        function len = length(obj)
            len = length(obj.value_);
        end
        
        function pos = positionOf(obj,selector)
            pos = findPositionIn(selector,obj.value);
        end
        function pos = positionIn(obj,target)
            pos = findPositionIn(obj.value,target);
        end
        
        function obj = union(obj,index2)
            index1 = obj.getValue_(obj.value);
            index2 = obj.getValue_(index2);
            assert(isequal(class(index1),class(index2)), ...
                sprintf( 'indexes are of different types: [%s] [%s]',class(index1),class(index2)));
            obj.value_ = obj.unionData(index1,index2);
        end
        function obj = vertcat(obj,varargin)
            val = obj.value_;
            for ii = 1:nargin-1
                val = [val;varargin{ii}.value_]; %#ok<AGROW>
            end
            obj.value = val;  % check if properties are respected
        end
            
        function bool = isunique(obj)
            bool = isunique(obj.value_);
        end
        function bool = issorted(obj)
            bool = issorted(obj.value_);
        end

        function value = getValue(obj)
            value = obj.value_;
        end
        function value = getValue_(~,value)
            if isa(value,'frames.Index')
                value = value.value_;
            end
            if isrow(value)
                value = value';
            end
        end
    end

    
    methods(Access=protected)
        function value = valueChecker(~,value)
            if ~isunique(value)
                warning('frames:Index:notUnique','index is not unique')
            end
        end
    end
    methods(Access=protected)
        function u = unionData(obj,v1,v2)
            u = [v1; v2];
            obj.valueChecker(u);
        end
        
    end
 
end

