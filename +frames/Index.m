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
    
    properties(Dependent)
        value                % Tx1 array
        singleton            % (logical, default false) set it to true if the Index represents a series, cf DataFrame.series
        requireUnique        % (logical, default false) whether the Index requires unique elements
        requireUniqueSorted  % (logical, default false) whether the Index requires unique and sorted elements  
        name                 % (string array) names of index dimensions  
        Ndim                 % number of dimensions (1)
    end
    properties(Dependent, Hidden)
        value_uniq           % (cell array) stores unique values per dimension    
        value_uniqind        % (int array) stores position index to unique value for every value      
    end
    properties      %TEMPORARY FOR DEBUGGING (NO ACCESS LIMITATIONS)
        value_               % stores values   
    end
    properties(Hidden,Access={?frames.TimeIndex,?frames.DataFrame,?frames.MultiIndex})  
        name_                % store name of the index
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
            % seperate method to overcome matlab's limitation on overloading setters/getters
            obj = obj.setname(value);            
        end
        
        function out = get.name(obj)
            % seperate method to overcome matlab's limitation on overloading setters/getters
            out = obj.getname();
        end
        
        function Ndim = get.Ndim(obj)
            % seperate method to overcome matlab's limitation on overloading setters/getters
            Ndim = get_Ndim(obj);
        end 
        
        function obj = set.singleton(obj,tf)
            % seperate method to overcome matlab's limitation on overloading setters/getters
            obj = set_singleton(obj,tf);
        end        
        
        
        
        function obj = set.requireUnique(obj,tf)
            arguments
                obj, tf (1,1) {mustBeA(tf,'logical')}
            end
            if tf && ~obj.isunique()
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
                if ~obj.issorted()
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
            len = size(obj.value_,1);
        end
        
        function [selector, selectorInd] = getSelector(obj,selector, positionIndex, allowedSeries, userCall, allowMissing)
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
            %    - allowMissing   (logical):    allow selectors with no matches (default error)
            %
            % output:
            %    validated array indexer (colon, logical array or position index array)
            %
            if nargin<5, userCall = true; end
            if nargin<4, allowedSeries = 'all'; end
            if nargin<3, positionIndex = false; end
            if nargin<6, allowMissing=false; end            
            
            if iscolon(selector)
                % do nothing, just output colon
                selectorInd = 1;                                
            elseif islogical(selector) || isFrame(selector)
                %  logical selectors
                if userCall
                    obj.logicalIndexChecker(selector, allowedSeries);
                end
                selector = obj.getValue_from(selector);                
                selectorInd = 1:length(selector);
            elseif positionIndex
                % position index selector
                if userCall
                    obj.positionIndexChecker(selector);
                end
                selectorInd = 1:length(selector);
            else
                %  value selectors
                selector = obj.getValue_andCheck(selector,userCall);
                if obj.requireUnique_
                    if ~allowMissing
                        assertFoundIn(selector,obj.value_)
                    end
                    [~,selectorInd,selector] = intersect(selector,obj.value_,'stable');
                else
                    % for speedup, prevent unnecessary output
                    if (nargout>1)
                       [selector,selectorInd] = findPositionIn(selector,obj.value_, allowMissing);
                    else
                       [selector] = findPositionIn(selector,obj.value_, allowMissing);
                    end
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
           if isempty(index2)
               % nothing to do
               return
           elseif ~isIndex(index2)
               % convert to index               
               index2 = obj.setvalue(index2, false); %skip value checks/ unique warning                          
           end           
           if obj.requireUnique
               method = "unique";
           else
               method = "none";
           end
           obj = obj.union_({index2}, method);
           obj.singleton_ = false;
       end
        
       
        function obj = vertcat_(obj,varargin)
            % internal function for concatenation of multiple indices (no checks)
            others = [varargin{:}];
            val = vertcat(obj.value_, others.value_);
            obj.singleton_ = false;
            obj.value_ = val;
        end       
       
        function obj = vertcat(obj,varargin)
            % concatenation
            obj = obj.vertcat_(varargin{:});
            obj.setvalue(obj.value_); % check if properties are respected            
        end
        
        function out = ismember(obj, value)
            % check if value is present in index
            out = ismember(value, obj.value_);
        end
        
       
        
        function bool = isunique(obj)
            if obj.requireUnique_
                bool = true;
            else
                bool = isunique(obj.value_uniqind);
            end
        end
        function bool = issorted(obj)
            if obj.requireUniqueSorted_
                bool = true;
            else
                bool = issorted(obj.value_uniqind);
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
        
        function [obj, sortindex] = sort(obj)
            % get sorted index (and corresponding position index)
            [~, sortindex] = sortrows(obj.value_uniqind);
            obj = obj.getSubIndex(sortindex);            
        end
        
        function [obj, sortindex] = unique(obj, ordering)
            % get unique (sorted) index (and corresponding position index)
            % (in case of non-unique elements, the index of the first occourance is returned)
            %
            % input:
            %    ordering: (string) 'sorted' or 'stable'
            %
            % output:
            %   obj: new Index object with only unique values
            %   sortindex: position index of selected unique items
            %            
            if nargin<2; ordering='sorted'; end
            [~, sortindex] = unique(obj.value_uniqind, ordering);
            obj = obj.getSubIndex(sortindex);            
        end
        
        
        function [obj_new, ind_cell] = union_(obj, others_cell, alignMethod)
            % Internal union function to create combined index of obj and all supplied index objects            
            %
            % The output index will keep the requireUnique and requireUniqueSorted settings from obj object. 
            % Different alignment methods can be chosen.
            %
            % input:
            %   others_cell:  cell array with (one or more) index objects to combine
            %
            %   alignMethod:    string enum with the alignment method to use:            
            %     - 'unique':        align on unique values only. Output index only contains the unique values of the
            %                        all indices together.
            %                        (only option that is allowed for indexes that requireUnique)
            %
            %     - 'keepDuplicates: align values between different indices . If already indices have
            %                        duplicate values, keep them in. If multiple indices have the
            %                        same duplicate values, align them in the same order as they occur in the
            %                        index. (default option)            
            %
            %     - 'none':          no alignment of values, append all values of indices together, even if that
            %                        creates new duplicates.                                
            %
            %
            % output:
            %   obj_new:  new Index object
            %   ind_cell: cell array with position index per supplied index object,
            %             including obj itself as first item.
            %             Position index describes the position for each original line in the newly created index            
            %
            arguments
                obj
                others_cell cell
                alignMethod {mustBeMember(alignMethod, ["unique", "keepDuplicates", "none"])} = "KeepDuplicates"   
            end
                        
            % handle singletons indices
            singletons = cellfun(@(x) x.singleton, [{obj}, others_cell]);
            if any(singletons)
                if all(singletons)
                    obj_new = obj;
                    ind_cell = repmat({1},length(singletons),1);
                    return
                else
                    error('frames:Index:union:noMixingSingletonAndNonSingleton', ...
                        "Not all indices are singleton, not allowed to mix singleton and non-singleton.");
                end
            end
            
            % check uniqueness      
            if obj.requireUnique
                 assert(alignMethod=="unique", 'frames:Index:union:requireUniqueMethod', ...
                     "Only method 'unique' allowed in union for index with requireUnique.");     
                 %requireUnique_all = cellfun(@(x) x.requireUnique || length(x)==0, others_cell);                   
                 %assert(all(requireUnique_all), 'frames:Index:union:notAllRequiredUnique', ...
                 %    "Obj has requireUnique enabled and not all other indices have this enabled.");
            end
                                                                
            % concat all inputs
            lengths = [obj.length() cellfun(@length, others_cell)];            
            obj_new = obj.vertcat_(others_cell{:}); % no error checking on unique yet
            
            % get unique index and row position index            
            uniqind = obj_new.value_uniqind;
            ind = (1:obj_new.length())';
            
            if alignMethod=="none"
                % no aignment, keep all concatenated values (including duplicates)
                if obj.isunique() && ~obj_new.isunique()
                      warning('frames:Index:notUnique','Index value is not unique.')
                end
            else 
                % align values
                if ~obj.requireUnique && alignMethod=="keepDuplicates" && ~obj_new.isunique()
                    % align duplicates between different indices by its order
                    unique_section = cellfun(@(x) x.requireUnique || length(x)==0, [{obj} others_cell]);                                
                    label_dupl = labelDuplicatesInSections(uniqind, lengths, unique_section);
                    uniqind = [ uniqind label_dupl];
                end
                
                % align index and update position index accordingly
                if obj.requireUniqueSorted                    
                   [~, ia, ind] = unique(uniqind, 'rows', 'sorted');                                      
                else                                                         
                   [~, ia, ind] = unique(uniqind, 'rows', 'stable');                    
                end
                obj_new = obj_new.getSubIndex(ia);  
            end
                           
            % slice full position index for each input index
            ind_cell = mat2cell( ind, lengths, 1);
            
            
            function out = labelDuplicatesInSections(x, L, unique_section)
                % get label vector for duplicate values of x, per section defined by lengths in L
                % (for speedup: do not calculate if section is known to be unique)
                startpos=[1 cumsum(L)+1];
                out = zeros(size(x));
                for i=1:length(L)
                    p1 = startpos(i);
                    p2 = startpos(i+1)-1;
                    if unique_section(i)
                        out(p1:p2) = 1;
                    else
                        out(p1:p2) = labelDuplicates(x(p1:p2));
                    end
                end                
            end            
            
            function out = labelDuplicates(x)
                % label duplicate values in array
                [X, ind_sort] = sort(x);
                C = countWithReset([1; diff(X)]);
                [~, ind_revsort] = sort(ind_sort);
                out = C(ind_revsort);
            end
            
            function out = countWithReset(v)
                % count consecutive zero elements, reset count at other values
                count = 1;
                out = zeros(size(v));
                for i=1:length(v)
                    if v(i)
                        count = 1;
                    else
                        count = count + 1;
                    end
                    out(i) = count;
                end
            end
        end
        
        
        function [objnew, ind1_new, ind2_new] = alignIndex(obj1, obj2, method, ~)
            % function to create new aligned Index of two Index objects            
            %
            % input:
            %    - obj1,obj2:    Index objects to be aligned
            %
            %    - method: (string enum) select method
            %           "strict": both need to have same values (else error thrown)
            %           "subset": remove rows that are not common in both
            %           "keep":   keep rows as in obj1  (default)            
            %           "full":   keep all items (allow missing in both obj1 and obj2)
            %
            % output:
            %   - objnew:     Index object with new aligned index (1:N)
            %   - ind1_new:   position index (1:N) with reference to original item of obj1 (NaN for values of obj2)
            %   - ind2_new:   position index (1:N) with reference to original item of obj2 (NaN for values of obj1)
            %      
            
            % default parameters
            if nargin<3, method="keep"; end                                                
            
            % call internal alignIndex function
            [objnew, ind1_new, ind2_new] = alignIndex_(obj1, obj2, method, "unique");
        end
        
               
        
        
    end
    
    methods(Hidden)
        
         function [objnew, ind1_new, ind2_new, id1_raw, id2_raw] = alignIndex_(obj1, obj2, method, unionMethod)
            % internal function to create new aligned Index of two Index objects            
            %
            % see alignIndex() for description
            %
            % extra input (wrt alignIndex):
            %   - unionMethod
            %
            % extra output (wrt alignIndex):                        
            %   - id1_raw:    array with unique ids of values in obj1 (lenght of obj1)
            %   - id2_raw:    array with unique ids of values in obj2 (lenght of obj2)
            %          

            % handle equal Indices or singleton indices without alignment code (for performance)            
            [objnew, ind1_new, ind2_new, id1_raw, id2_raw] = alignIndex_handle_simple_(obj1, obj2);                        
            if ~isempty(objnew), return; end

            % get matching rows of both Index objects
            [objnew, ind_cell] = obj1.union_({obj2}, unionMethod);            
            [id1_raw, id2_raw] = ind_cell{:};

            % create common masks
            mask1 = ismember(id1_raw, id2_raw);
            mask2 = ismember(id2_raw, id1_raw);    

            % define row ids in new index based on chosen method
            switch method
                case "subset"                    
                    id = id1_raw(mask1);              
                case "keep"
                    id = id1_raw;                                                            
                case "strict"
                    assert( all(mask1) & all(mask2), 'frames:Index:alignIndex:unequalIndex', ...
                        "Unequal values in dimension not allowed in strict align method");
                    id = id1_raw;                    
                case "full"                                         
                    id = 1:length(objnew);                                                      
                otherwise 
                    error("unsupported alignMethod '%s'",method);
            end

            % only output selected rows in index
            objnew = objnew.getSubIndex(id);

            % get for each item in new index a position reference to original line in obj1 and obj2
            % (if given item does not exist in given object, value is NaN)
            ind1_new = nan(length(id),1);
            [~,pos1_obj,pos1_id] = intersect(id1_raw, id);
            ind1_new(pos1_id) = pos1_obj;            

            ind2_new = nan(length(id),1);
            [~,pos2_obj, pos2_id] = intersect(id2_raw, id);
            ind2_new(pos2_id) = pos2_obj;                                                                         
        end
              
        
        
        function [objnew, ind1_new, ind2_new, id1_raw, id2_raw] = alignIndex_handle_simple_(obj1, obj2)
            % internal function to check and handle simple cases (equal index or singleton)
            %            
            % check
            assert(isIndex(obj2), 'frames:Index:alignIndex:requireIndex', "obj2 is not a Index object.");   
            % default empty
            objnew = [];
            ind1_new = []; ind2_new = [];
            id1_raw = [];  id2_raw = [];            
            % handle equal and singleton cases
            if isequal(obj1.value,obj2.value)
                objnew = obj1;
                ind1_new = 1:length(obj1);
                ind2_new = ind1_new;                
            elseif ~obj1.singleton && obj2.singleton
                objnew = obj1;
                ind1_new = 1:length(obj1);
                ind2_new = ones(size(ind1_new));                
            elseif obj1.singleton && ~obj2.singleton
                objnew = obj2;
                ind2_new = 1:length(obj2);
                ind1_new = ones(size(ind2_new));                
            end            
        end
        
        
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


        function out = getvalue_uniqind(obj, ~)
            % get index positions to unique values (using cache for speedup)            
            out = obj.value_uniqind_;
        end        
        
    end
    
    methods(Access=protected)
        function obj = setvalue(obj,value, userCall)
            if nargin<3, userCall=true; end
            if isa(value,'frames.Index')
                error('frames:index:setvalue','value of Index cannot be an Index')
            end
            if islogical(value)
                error('frames:index:setvalueLogical','value of Index cannot be a logical')
            end
            value = obj.getValue_andCheck(value, userCall);            
            if isrow(value)
                value = value';
            end
            obj.value_ = value;                  
        end        
        
        function out = getname(obj)
            % get index name
            out = obj.name_;
        end
        
        function obj = setname(obj, value)
            % set index name
            obj.name_ = value;
        end

        function out = getvalue_uniq(obj)
            % get unique values (using cache for speedup)                        
            out = {obj.value_uniq_};
        end

        function Ndim = get_Ndim(obj)
            % get number of dimensions
            Ndim = 1;
        end
        
        function obj = set_singleton(obj,tf)
            % set singleton
            arguments
                obj, tf (1,1) {mustBeA(tf,'logical')}
            end
            if tf
                assert(obj.length()==1,'frames:Index:setSingleton',...
                    'Index must contain 1 element to be a singleton')
                obj.value_ = obj.getMissingData_();                
            elseif ~tf && obj.singleton_
                obj.value_ = obj.getDefaultValue_();
            end
            obj.singleton_ = tf;
        end    
        
        function obj = recalc_unique_cache(obj)
            % recalculate unique cache based on stored value_           
            if obj.singleton
                obj.value_uniq_=missing;
                obj.value_uniqind_=1;                
            elseif obj.length()==0
                obj.value_uniq_=[];
                obj.value_uniqind_=[];
            else
                [obj.value_uniq_,~ ,obj.value_uniqind_] = unique(obj.value_, 'sorted');                
            end
        end                        
        
        function valueChecker(obj,value,fromSubsAsgnIdx,b)
            if obj.singleton_
                assert(isSingletonValue(value),'frames:Index:valueChecker:singleton', ...
                    'The value of a singleton Index must be missing.')
                return
            end
            if nargin >= 4
                assert( ~any(ismissing(value)) || isa(b, class(value)), ...
                    'frames:Index:valueChecker:differentType', ...
                    "value type ("+class(b)+") is different than type of existing values (" + ...
                    class(value)+ ") and cannot automaticaly be converted.");
            end                        
            if obj.requireUnique_
                if ~isunique(value) && ~islogical(value)
                    error('frames:Index:requireUniqueFail', ...
                        'Index value is required to be unique.')
                end
            else
                if nargin >= 4                    
                    valTmp = value;
                    valTmp(fromSubsAsgnIdx) = [];  % this is slow
                    b_ = value(fromSubsAsgnIdx); % to handle type conversion
                    if ~isunique(b_) || any(ismember(b_,valTmp))
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
            mustBeFullVector(value)
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
                    assert( isequal(obj.value_,selector.rows_.value_), 'frames:logicalIndexChecker:differentRows', ...
                           "colSeries Selector has different rows");
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
        
        function out = getMissingData_(obj),  out = missingData( class(obj.value_));  end
        function out = getDefaultValue_(obj),  out = defaultValue( class(obj.value_));  end 
        
        
    end  
end

