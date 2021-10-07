classdef Index
% INDEX is the object that supports the rows and columns properties in a DataFrame.
% They are stored in the rows_ and columns_ properties of DataFrame.
% It contains operations of selection and merging, and constrains.
%
% The INDEX of the columns accepts duplicate values by default.
% The INDEX of the rows accepts only unique values by default.
%
% This property can be defined explicitly in the constructor of INDEX,
% or changed with the methods .setRowsType and .setColumnsType of
% DataFrame.
% An INDEX can 1) accept duplicate values, 2) require unique value, or 3)
% require unique and sorted values.
%
%
% If the length of value is equal to 1, the INDEX can be a
% 'singleton', ie it represents the rows of a series, which will allow
% operations between Frames with different indices (see DataFrame.series)
%
% Use:
%  INDEX(value[,Unique=logical,UniqueSorted=logical,Singleton=logical,Name=name])
%
% Copyright 2021 Benjamin Gaudin
% Contact: frames.matlab@gmail.com
%
% See also: TIMEINDEX
    
    %properties
    %    name = "" % {mustBeTextScalar} = ""  % (textScalar) name of the Index
    %end
    properties(Dependent)
        value                % Tx1 array
        singleton            % (logical, default false) set it to true if the Index represents a series, cf DataFrame.series
        requireUnique        % (logical, default false) whether the Index requires unique elements
        requireUniqueSorted  % (logical, default false) whether the Index requires unique and sorted elements  
        name                 % (string array) names of index dimensions  
    end
    properties(Dependent, Hidden)
        value_uniq           % (cell array) stores unique values per dimension    
        value_uniqind        % (int array) stores position index to unique value for every value      
    end
    properties      %TEMPORARY FOR DEBUGGING (NO ACCESS LIMITATIONS)
        value_               % stores values   
    end
    properties(Hidden,Access={?frames.TimeIndex,?frames.DataFrame,?frames.MultiIndex})  
        name_                % store name
        singleton_
        requireUnique_
        requireUniqueSorted_
        value_uniq_          % cached unique values
        value_uniqind_       % cached indices to unique values        
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
        
        function obj=getSubIndex(obj,selector)
            % get Index object of sub selection based on matlab selector
            obj.value_ = obj.value_(selector);         
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
            % seperate method to overcome matlab's limitation on overloading setters/getters
            obj = obj.setvalue(value); 
        end
        function obj = set.value_(obj,value)
            % set lowlevel value, and trigger cache update
            obj.value_ = value;
            obj = obj.recalc_unique_cache();
        end        
        function obj = set.name(obj,value)
            obj.name_ = value;
        end
        
        function out = get.name(obj)
            % seperate method to overcome matlab's limitation on overloading setters/getters
            out = obj.getname();
        end
        
        function obj = set.singleton(obj,tf)
            arguments
                obj, tf (1,1) {mustBeA(tf,'logical')}
            end
            if tf
                assert(obj.length()==1,'frames:Index:setSingleton',...
                    'Index must contain 1 element to be a singleton')
                obj.value_ = missingData(class(obj.value_));
            elseif ~tf && obj.singleton_
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
        
        function val = getValueForTable(obj)
            % convert value to strings to use with a table (note that
            % timetable rows does not need this conversion)
            val = obj.value;
            if isnumeric(val)
                val = compose('%.10g',val);
            elseif isscalar(val) && ismissing(val)
                val = missingDataDisplayStr(val);
            else
                val = cellstr(string(val));
            end
            val = matlab.lang.makeUniqueStrings(val,{},namelengthmax());
        end
        
        function len = length(obj)
            len = length(obj.value_);
        end
        
        function selector = getSelector(obj,selector, positionIndex, allowedSeries, userCall)
            % get valid matlab indexer for array operations based on supplied selector
            % supports:
            %    - colon
            %    - index value array / index position array
            %    - logical array/ logical Series
            % ----------------            
            % Parameters:
            %    - selector
            %    - allowedSeries: (string enum: 'all','onlyRowSeries','onlyColSeries')
            %                                   accept only these logical dataframe series
            %    - positionIndex  (logical):    selector is position index instead of value index
            %    - userCall       (logical):    perform full validation of selector
            %
            % output:
            %    validated array indexer (colon, logical array or position index array)
            %
            if nargin<5, userCall = true; end
            if nargin<4, allowedSeries = 'all'; end
            if nargin<3, positionIndex = false; end  
                        
            if iscolon(selector)
                % do nothing
            elseif islogical(selector) || isFrame(selector)
                %  logical selectors
                if userCall
                    obj.logicalIndexChecker(selector, allowedSeries);
                end
                selector = obj.getValue_from(selector);
            elseif positionIndex
                % position index selector
                if userCall
                    obj.positionIndexChecker(selector);
                end
            else
                %  value selectors
                selector = obj.getValue_andCheck(selector,userCall);
                if obj.requireUnique_
                    assertFoundIn(selector,obj.value_)
                    [~,~,selector] = intersect(selector,obj.value_,'stable');
                else
                    selector = findPositionIn(selector,obj.value_);
                end
            end
        end        
        
        function pos = positionOf(obj, selector, varargin)
            % output position index array for given selector
            %
            % Parameters: see getSelector()
            %
            selector = obj.getSelector(selector, varargin{:});
            if iscolon(selector)                
                pos = 1:length(obj.value_);
            elseif islogical(selector)                
                pos = find(selector);
            else
                pos = selector;
            end
        end
        
        function mask = getSelectorMask(obj, selector, varargin)
            % output logical mask array for given selector
            %
            % Parameters: see getSelector()
            %
            selector = obj.getSelector(selector, varargin{:});   
            if iscolon(selector)                
                mask = true(obj.length(),1);
            elseif islogical(selector)                
                mask = selector;
            else
                mask = false(obj.length(),1);
                mask(selector) = true;
            end
        end
        
        function pos = positionIn(obj,target,userCall)
            % find position of the Index into the target
            if nargin < 3, userCall = true; end
            target = obj.getValue_andCheck(target,userCall);
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
        
        function out = get.value_uniq(obj)
            % seperate method to overcome matlab's limitation on overloading setters/getters            
            out = getvalue_uniq(obj);                        
        end
        
        function out = get.value_uniqind(obj)
            % seperate method to overcome matlab's limitation on overloading setters/getters
            out = getvalue_uniqind(obj);            
        end                   
        
    end
    
    methods(Hidden)
        function obj = subsasgn(obj,s,b)
            if length(s) == 2 && strcmp([s.type],'.()') && strcmp(s(1).subs,'value')
                idxNew = s(2).subs{1};
                if isequal(b,[])
                    obj.value_(idxNew) = [];
                    if obj.singleton_
                        assert(isSingletonValue(obj.value_),'frames:Index:valueChecker:singleton', ...
                            'The value of a singleton Index must be missing.')
                    end
                else
                    b_ = obj.getValue_from(b);
                    val_ = obj.value_;
                    val_(idxNew) = b_;

                    obj.valueChecker(val_,idxNew,b_);
                    obj.value_ = val_;
                end
            else
                obj = builtin('subsasgn',obj,s,b);
            end
        end
        
        function N = getSelectorCount(obj, selector)
            % get number of elements from matlab compatible selector            
            if iscolon(selector)
                N = length(obj);
            elseif islogical(selector)
                N = sum(selector);
            else
                N = length(selector);
            end                
        end
        
    end
    
    methods(Access=protected)
        function obj = setvalue(obj,value)
            if isa(value,'frames.Index')
                error('frames:index:setvalue','value of Index cannot be an Index')
            end
            if islogical(value)
                error('frames:index:setvalueLogical','value of Index cannot be a logical')
            end
            value = obj.getValue_andCheck(value,true);
            if isrow(value)
                value = value';
            end
            obj.value_ = value;                  
        end        
        
        function out = getname(obj)
            out = obj.name_;
        end

        function out = getvalue_uniq(obj)
            % get unique values (using cache for speedup)                        
            out = {obj.value_uniq_};
        end
        
        function out = getvalue_uniqind(obj)
            % get index positions to unique values (using cache for speedup)            
            out = obj.value_uniqind_;
        end
        
        function obj = recalc_unique_cache(obj)
            % recalculate unique cache based on stored value_
            if obj.length()>0 && ~any(ismissing(obj.value_))
                [obj.value_uniq_,~ ,obj.value_uniqind_] = unique(obj.value_, 'sorted');
            else
                obj.value_uniq_=[];
                obj.value_uniqind_=[];
            end
        end                        
        
        function valueChecker(obj,value,fromSubsAsgnIdx,b)
            if obj.singleton_
                assert(isSingletonValue(value),'frames:Index:valueChecker:singleton', ...
                    'The value of a singleton Index must be missing.')
                return
            end
            mustBeFullVector(value)
            
            if obj.requireUnique_
                if ~isunique(value) && ~islogical(value)
                    error('frames:Index:requireUniqueFail', ...
                        'Index value is required to be unique.')
                end
            else
                if nargin >= 3
                    valTmp = value;
                    valTmp(fromSubsAsgnIdx) = [];  % this is slow
                    if ~isunique(b) || any(ismember(b,valTmp))
                        warning('frames:Index:subsagnNotUnique', ...
                            'The assigned values make the Index not unique.')
                    end
                else
                    if ~isunique(value) && ~islogical(value)
                        warning('frames:Index:notUnique', ...
                            'Index value is not unique.')
                    end
                end
            end
            if obj.requireUniqueSorted_ && ~issorted(value)
                error('frames:Index:requireSortedFail', ...
                    'Index value is required to be sorted and unique.')
            end
        end
        
        function positionIndexChecker(obj, selector)    
            % validate position index    
            assert(~obj.requireUnique_ || isunique(selector), 'frames:Index:requireUniqueFail', ...
                'Index value is required to be unique.')
            assert(~obj.requireUniqueSorted_ || issorted(selector), 'frames:Index:requireSortedFail', ...
                'Index value is required to be sorted.')            
        end
        
       function logicalIndexChecker(obj, selector, allowedSeries)
          % validate logical index array (or logical dataframe series)
            %  Parameters:
            %     seriesType:  ('all'/'onlyRowSeries'/'onlyColSeries') acceptable logical dataframe series
            %
            if nargin<3, allowedSeries = 'all'; end            
            if isFrame(selector)
                % check logical series and convert to logical array
                if allowedSeries=="onlyColSeries"   
                    assert(selector.colseries, 'frames:logicalIndexChecker:onlyColSeries', ...
                           "Indexing of rows only allowed with DataFrame logical colSeries.");
                    assert( isequal(obj.value_,selector.rows_.value_), 'frames:logicalIndexChecker:differentIndex', ...
                           "colSeries Selector has different index");
                elseif allowedSeries=="onlyRowSeries"                   
                    assert(selector.rowseries, 'frames:logicalIndexChecker:onlyRowSeries', ...
                           "Indexing of columns only allowed with DataFrame logical rowSeries.");
                    assert( isequal(obj.value_,selector.columns_.value_), 'frames:logicalIndexChecker:differentColumns', ...
                           "rowSeries selector has different columns");                       
                else
                    error("Unsupported allowedSeries parameter.");
                end                
                selector = selector.data_;
            else
                % check logical vector
                assert(isvector(selector), 'frames:logicalIndexChecker:VectorRequired', ...
                   "Logical index array should be vector (no matrix)");   
            end
            assert(islogical(selector), 'frames:logicalIndexChecker:LogicalRequired', ...
                       "Selector is not logical");                    
                                     
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
            elseif isFrame(value)
                value = value.data_;
            end
            if isrow(value)
                value = value';
            end
        end
        function valueOut = getValue_andCheck(obj,value,userCall)
            valueOut = obj.getValue_from(value);
            if userCall, obj.valueChecker(valueOut); end
        end
    end  
end

