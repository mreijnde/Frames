classdef Index
% INDEX is the object that supports index and columns in a DataFrame.
% It contains operations of selection and merging, and constrains.
%
% An INDEX is expected to have unique values.
% INDEX allows duplicates, but throw an error whenever it is modified.
% UniqueIndex only allows unique entries.
% SortedIndex only allows unique entries that are sorted.
% TimeIndex only allows unique chronological time entries.
% See also: UNIQUEINDEX, SORTEDINDEX, TIMEINDEX
    
    properties
        name {mustBeTextScalar} = ""
    end
    properties(Dependent)
        value
        singleton
    end
    properties(Access={?frames.UniqueIndex,?frames.DataFrame})
        value_
        singleton_
    end
    
    methods
        function obj = Index(value,nameValue)
            % INDEX Index(value[,Name=name,Singleton=logical])
            arguments
                value {mustBeDFcolumns} = []
                nameValue.Name = ""
                nameValue.Singleton {mustBeA(nameValue.Singleton,'logical')} = false
            end
            name = nameValue.Name;
            singleton = nameValue.Singleton;
            if isa(value,'frames.Index')
                singleton = value.singleton;
                name = value.name;
                value = value.value;
            end
            obj.value = value;
            obj.name = name;
            obj.singleton_ = singleton;
        end
        
        function idx = get.value(obj)
            idx = obj.getValue();
        end
        function idx = get.singleton(obj)
            idx = obj.singleton_;
        end
        function obj = set.value(obj,value)
            arguments
                obj, value {mustBeDFcolumns} = []
            end
            value = obj.valueChecker(value);
            if isrow(value)
                value = value';
            end
            obj.value_ = value;
        end
        function obj = set.singleton(obj,tf)
            arguments
                obj, tf {mustBeA(tf,'logical')}
            end
            if tf && length(obj.value_) > 1
                error('frames:Index:setSingleton',...
                    'Index must contain 0 or 1 element to be a singleton')
            end
            obj.singleton_ = tf;
        end
        function v = getValue_(obj)
            v = obj.value_;
        end
        
        function len = length(obj)
            len = length(obj.value_);
        end
        
        function pos = positionOf(obj,selector)
            % find position of 'selector' in the Index
            selector = obj.getValue_from(selector);
            pos = findPositionIn(selector,obj.value_);
        end
        function pos = positionIn(obj,target)
            % find position of the Index into the target
            target = obj.getValue_from(target);
            pos = findPositionIn(obj.value_,target);
        end
        
        function obj = union(obj,index2)
            % unify two indices
            index1 = obj.value_;
            index2 = obj.getValue_from(index2);
            assert(isequal(class(index1),class(index2)), ...
                sprintf( 'indexes are of different types: [%s] [%s]',class(index1),class(index2)));
            obj.value_ = obj.unionData(index1,index2);
            obj.singleton_ = false;
        end
        function obj = vertcat(obj,varargin)
            % concatenation
            val = obj.value_;
            for ii = 1:nargin-1
                val = [val;varargin{ii}.value_]; %#ok<AGROW>
            end
            obj.value = val;  % check if properties are respected
            obj.singleton_ = false;
        end
            
        function bool = isunique(obj)
            bool = isunique(obj.value_);
        end
        function bool = issorted(obj)
            bool = issorted(obj.value_);
        end


    end

    
    methods(Access=protected)
        function value = valueChecker(~,value)
            if ~isunique(value)
                warning('frames:Index:notUnique','index is not unique')
            end
        end
        function u = unionData(obj,v1,v2)
            u = [v1; v2];
            obj.valueChecker(u);
        end
        
        function value = getValue(obj)
            value = obj.value_;
        end
        function value = getValue_from(~,value)
            if isa(value,'frames.Index')
                value = value.value_;
            end
            if isrow(value)
                value = value';
            end
        end
        
    end
 
end

