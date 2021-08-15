classdef Index
% INDEX is the object that supports the index and columns properties in a DataFrame.
% They are stored in the index_ and columns_ properties of DataFrame.
% It contains operations of selection and merging, and constrains.
%
% The INDEX of the columns accepts duplicate values by default.
% The INDEX of the index accepts only unique values by default.
%
% This property can be defined explicitly in the constructor of INDEX,
% or changed with the methods .setIndexType and .setColumnsType of
% DataFrame.
% An INDEX can 1) accept duplicate values, 2) require unique value, or 3)
% require unique and sorted values.
% 
%
% If the length of value is equal to 1, the INDEX can be a
% 'singleton', ie it represents the index of a series, which will allow
% operations between Frames with different indices (see DataFrame.series)
%
% Use:
%  INDEX(value[,Unique=logical,UniqueSorted=logical,Singleton=logical,Name=name])
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
            % INDEX Index(value[,Unique=logical,UniqueSorted=logical,Singleton=logical,Name=name])
            arguments
                value = double.empty(0,1)
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
            elseif isequal(value,[])
                value = double.empty(0,1);
            end
            
            obj.requireUnique_ = requireUnique;
            obj.requireUniqueSorted = requireUniqueSorted;
            obj.name = name;
            obj.singleton_ = singleton;
            obj.value = value;
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
            if tf 
                assert(length(obj.value_)==1,'frames:Index:setSingleton',...
                    'Index must contain 1 element to be a singleton')
                obj.value_ = missingData(class(obj.value_));
            elseif ~tf && obj.singleton_ && ismissing(obj.value_)
                obj.value_ = defaultValue(class(obj.value_));
            end
            obj.singleton_ = tf;
        end
        function obj = set.requireUnique(obj,tf)
            arguments
                obj, tf (1,1) {mustBeA(tf,'logical')}
            end
            if tf && ~isunique(obj.value_)
                error('frames:Index:setRequireUnique',...
                    'Index value must be unique.')
            elseif ~tf && obj.requireUniqueSorted_
                error('frames:Index:setRequireNotUniqueIsSorted',...
                    'Index must remain unique as it is uniquesorted.')
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
                        'Index must be unique and sorted.')
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
            obj.singleton_ = false;
            obj.value = val;  % check if properties are respected
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
        function bool = ismissing(obj)
            bool = ismissing(obj.value_);
        end
        
    end
    
    methods(Hidden)
        function obj = subsasgn(obj,s,b)

            if length(s)==2
                [beingAssigned,selectors] = s.subs;
                if strcmp(beingAssigned,'value')
                    
                    mustBeFullVector(b);
                    mustBeNonempty(b);
                    obj.([beingAssigned,'_']).value(selectors{1}) = b;

            else
                obj = builtin('subsasgn',obj,s,b);
    
            end
send
            switch s.type
                case '()'
                    idxNew = s.subs{1};
                    if obj.singleton_
                        assert(isSingletonValue(b),'frames:Index:asgnNotSortedsingleton', ...
                                'The value of a singleton Index must be missing.')
                        obj.value_(idxNew) = b;
                        return
                    end
                    mustBeFullVector(b)
                    b_ = obj.getValue_from(b);
                    val_ = obj.value_;
                    val_(idxNew) = b_;
                    if obj.requireUniqueSorted && ~issorted(val_)
                        error('frames:Index:asgnNotSorted',...
                            'The assigned values make the Index not sorted.')
                    end
                    if obj.requireUnique
                        if ~isunique(val_)
                            error('frames:Index:asgnNotUnique',...
                                'The assigned values make the Index not unique.')
                        end
                    else
                        valTmp = val_;
                        valTmp(idxNew) = [];
                        if ~isunique(b) || any(ismember(b,valTmp))
                            warning('frames:Index:notUnique',...
                                'The assigned values make the Index not unique.')
                        end
                    end
                    
                    obj.value_ = val_;
                case '{}'
                    error('frames:Index:asgnCurly','subasgn is not defined for curly brackets.')
                case '.'
                    obj.(s.subs) = b;
            end
        end
      %  function n = numArgumentsFromSubscript(varargin), n = 1; end
     %   function e = end(obj,~,~), e = builtin('end',obj.value_,1,1); end
    end
    
    methods(Access=protected)
        function valueChecker(obj,value,fromSubsAsgnIdx)
            if obj.singleton_
                assert(isSingletonValue(value),'frames:Index:valueChecker:singleton', ...
                        'The value of a singleton Index must be missing.')
                    return
            end
            mustBeFullVector(value)
            if ~isunique(value)
                if obj.requireUnique_
                    error('frames:Index:requireUniqueFail','Index value is required to be unique.')
                else
                    warning('frames:Index:notUnique','Index value is not unique.')
                end
            end
            if obj.requireUniqueSorted_ && ~issorted(value)
                error('frames:Index:requireSortedFail','Index value is required to be sorted and unique.')
            end
        end
        function u = unionData(obj,v1,v2)
            if obj.requireUnique_
                if obj.requireUniqueSorted_
                    u = union(v1,v2,'sorted');  % sorts by default
                else
                    u = union(v1,v2,'stable');
                end
                if isrow(u), u=u'; end
            else
                u = [v1; v2];
                if ~isunique(v2) || any(ismember(v2,v1))
                    warning('frames:Index:notUnique','Index value is not unique.')
                end
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

