classdef Index
% INDEX belongs to the objects that support columns in a DataFrame.
% It contains operations of selection and merging, and constrains.
%
% An INDEX is expected to have unique values.
% INDEX allows duplicates, but throw an error whenever it is modified.
% UniqueIndex only allows unique entries.
% SortedIndex only allows unique entries that are sorted.
% TimeIndex only allows unique chronological time entries.
%
% If the length is lower than or equal to 1, the Index can be a
% 'singleton', ie representing the index of a series, which will allow
% operations between Frames with different indices (see DataFrame.series)
%
% Copyright 2021 Benjamin Gaudin
%
% See also: TIMEINDEX
    
    properties
        name {mustBeTextScalar} = ""  % (textScalar) name of the Index
    end
    properties(Dependent)
        value  % Tx1 array
        singleton  % (logical, default false) set it to true if the Index represents a series, cf DataFrame.series
        requireUnique  % (logical, default false) whether the Index requires unique elements
        requireUniqueSorted  % (logical, default false) whether the Index requires unique and sorted elements
    end
    properties(Hidden,Access={?frames.TimeIndex,?frames.DataFrame})
        value_
        singleton_
        requireUnique_
        requireUniqueSorted_
    end
    
    methods
        function obj = Index(value,nameValue)
            % INDEX Index(value[,Name=name,Singleton=logical])
            arguments
                value {mustBeDFcolumns} = []
                nameValue.Name = ""
                nameValue.Unique (1,1) {mustBeA(nameValue.Unique,'logical')} = false
                nameValue.UniqueSorted (1,1) {mustBeA(nameValue.UniqueSorted,'logical')} = false
                nameValue.Singleton (1,1) {mustBeA(nameValue.Singleton,'logical')} = false
            end
            name = nameValue.Name;
            singleton = nameValue.Singleton;
            requireUnique = nameValue.Unique;
            requireUniqueSorted = nameValue.UniqueSorted;
            if isa(value,'frames.Index')
                singleton = value.singleton;
                name = value.name;
                value = value.value;
            end
            obj.requireUnique_ = requireUnique;
            obj.requireUniqueSorted = requireUniqueSorted;
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
        function idx = get.requireUnique(obj)
            idx = obj.requireUnique_;
        end
        function idx = get.requireUniqueSorted(obj)
            idx = obj.requireUniqueSorted_;
        end
        function obj = set.value(obj,value)
            arguments
                obj, value {mustBeDFcolumns} = []
            end
            if isa(value,'frames.Index')
                error('frames:index:setvalue','value of Index cannot be an Index')
            end
            value = obj.getValue_andCheck(value,true);
            if isrow(value)
                value = value';
            end
            obj.value_ = value;
        end
        function obj = set.singleton(obj,tf)
            arguments
                obj, tf (1,1) {mustBeA(tf,'logical')}
            end
            if tf && length(obj.value_) ~= 1
                error('frames:Index:setSingleton',...
                    'Index must contain 1 element to be a singleton')
            end
            obj.singleton_ = tf;
        end
        function obj = set.requireUnique(obj,tf)
            arguments
                obj, tf (1,1) {mustBeA(tf,'logical')}
            end
            if tf && ~isunique(obj.value_)
                error('frames:Index:setRequireUnique',...
                    'Index must be unique')
            elseif ~tf && obj.requireUniqueSorted_
                error('frames:Index:setRequireNotUniqueIsSorted',...
                    'Index must remain unique as it is uniquesorted')
            end
            obj.requireUnique_ = tf;
        end
        function obj = set.requireUniqueSorted(obj,tf)
            arguments
                obj, tf (1,1) {mustBeA(tf,'logical')}
            end
            if tf 
                if ~issorted(obj.value_)
                    error('frames:Index:setrequireUniqueSorted',...
                        'Index must be sorted.')
                end
                if ~obj.requireUnique
                    obj.requireUnique_ = true;
                end
            end
            obj.requireUniqueSorted_ = tf;
        end
        function v = getValue_(obj)
            v = obj.value_;
        end
        
        function len = length(obj)
            len = length(obj.value_);
        end
        
        function pos = positionOf(obj,selector,varargin)
            % find position of 'selector' in the Index
            selector = obj.getValue_andCheck(selector,varargin{:});
            if obj.requireUnique_
                assertFoundIn(selector,obj.value_)
                [~,~,pos] = intersect(selector,obj.value_,'stable');
            else
                pos = findPositionIn(selector,obj.value_);
            end
        end
        function pos = positionIn(obj,target,varargin)
            % find position of the Index into the target
            target = obj.getValue_andCheck(target,varargin{:});
            if obj.requireUnique_
                assertFoundIn(obj.value_,target)
                if obj.requireUniqueSorted_
                    pos = ismember(target,obj.value_);
                else
                    [~,~,pos] = intersect(obj.value_,target,'stable');
                end
            else
                pos = findPositionIn(obj.value_,target);
            end
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
            if obj.requireUnique_
                bool = true;
            else
                bool = isunique(obj.value_);
            end
        end
        function bool = issorted(obj)
            if obj.requireUniqueSorted_
                bool = true;
            else
                bool = issorted(obj.value_);
            end
        end
        
    end
    
    methods(Access=protected)
        function valueChecker(obj,value)
            if ~isvector(value)
                error('frames:Index:notVector','index must be a vector')
            end
            if ~isunique(value)
                if obj.requireUnique_
                    error('frames:UniqueIndex:valueCheckFail','index is not unique')
                else
                    warning('frames:Index:notUnique','index is not unique')
                end
            end
            if obj.requireUniqueSorted_ && ~issorted(value)
                error('frames:SortedIndex:valueCheckFail','Index is not sorted.')
            end
        end
        function u = unionData(obj,v1,v2)
            if obj.requireUnique_
                if obj.requireUniqueSorted_
                    u = union(v1,v2,'sorted');  % sorts by default
                else
                    u = union(v1,v2,'stable');
                end
            else
                u = [v1; v2];
                obj.valueChecker(u);
            end
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
        function valueOut = getValue_andCheck(obj,value,userCall)
            if nargin<3, userCall=false; end
            valueOut = obj.getValue_from(value);
            if userCall, obj.valueChecker(valueOut); end
        end
        
    end
 
end

