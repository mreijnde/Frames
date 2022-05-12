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
    properties(Hidden,Access={?frames.TimeIndex,?frames.DataFrame,?frames.MultiIndex})  
        value_               % stores values
        name_                % store name of the index
        singleton_
        requireUnique_
        requireUniqueSorted_
        value_uniq_          % cached unique values
        value_uniqind_       % cached indices to unique values
        value_isuniq_        % cached bool if values are unique
        warningNonUnique_    % (logical, default true) produce warning in case index is made non unique
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
                nameValue.warningNonUnique (1,1) {mustBeA(nameValue.warningNonUnique,'logical')} = true
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
            obj.warningNonUnique_ = nameValue.warningNonUnique;
            obj.name = name;
            obj.singleton_ = singleton;
            obj.value = value;
        end
        
        function obj=getSubIndex(obj,selector, dimindex)
            % get Index object of sub selection based on (matlab) selector
            % 
            % input:
            %    - selector: valid matlab selector for rows
            %    - dimindex: position index of dimensions select (default: all dimensions)
            %
            % output:
            %    - MultiIndex object with subselection                        
            if nargin<3; dimindex=':'; end
            % select
            obj = obj.getSubIndex_(selector, dimindex);
            % check if set values are allowed
            obj.valueChecker(obj.value_);
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
        
        function selector = getSelector(obj,selector, positionIndex, allowedSeries, userCall, allowMissing)
            % get valid matlab indexer for array operations based on supplied selector
            % supports:
            %    - colon
            %    - index value array / index position array
            %    - logical array/ logical Series
            % ----------------            
            % Parameters:
            %    - selector
            %    - allowedSeries: (string enum: 'all' ,'onlyRowSeries','onlyColSeries') (default 'all')
            %                                   accept only these logical dataframe series
            %    - positionIndex  (logical):    selector is position index instead of value index (default false)
            %    - userCall       (logical):    perform full validation of selector (default true)
            %    - allowMissing   (logical):    allow selectors with no matches (default error)
            %
            % output:
            %    validated array indexer (colon, logical array or position index array)
            %
            if nargin<5, userCall = true; end
            if nargin<4, allowedSeries = 'all'; end
            if nargin<3, positionIndex = false; end
            if nargin<6, allowMissing=false; end            
            % call internal function
            selector = obj.getSelector_(selector, positionIndex, allowedSeries, userCall, allowMissing);
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
            pos = obj.positionIn_(obj.value_, target);
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
               duplicateOption = "unique";
           else
               duplicateOption = "none";
           end
           obj = obj.alignIndex(index2, duplicateOption=duplicateOption);
           obj.singleton_ = false;
       end
        
       
        function obj = vertcat(obj,varargin)
            % concatenation
            obj = obj.vertcat_(varargin{:});            
            obj.valueChecker(obj.value_); % check if properties are respected            
        end
        
        function out = ismember(obj, value)
            % check if value is present in index
            out = ismember(value, obj.value_);
        end
                       
        function bool = isunique(obj)
            % check if Index values are unique
            bool = obj.value_isuniq_;  % use cached value            
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
            %    ordering: (string) 'sorted' (default) or 'stable'
            %
            % output:
            %   obj: new Index object with only unique values
            %   sortindex: position index of selected unique items
            %            
            if nargin<2; ordering='sorted'; end
            [~, sortindex] = unique(obj.value_uniqind, ordering);
            obj = obj.getSubIndex(sortindex);            
        end
        
        
              

      function [obj_new, ind] = alignIndex(objs, options)
            % ALIGNINDEX create combined index of obj and all supplied index objects            
            %
            % The output index will keep the requireUnique and requireUniqueSorted settings from first object. 
            % Different option for handling duplicate values are supported.
            %
            % INPUT:
            %   objs:      multiple Index objects to combine
            %
            %   options:   name-value combinations
            %
            %    - duplicateOption:  string enum with options:            
            %
            %       - 'unique':        align on first occurrence of unique values between indices (removes duplicates). 
            %                          Output index only contains the unique values of the all indices. 
            %                          (only option that is allowed for indexes that requireUnique)                      
            %            
            %       - 'duplicates':    align values between indices. If multiple indices have the
            %                          same duplicate values, align them in the same order as they occur in the
            %                          index. (default option)            
            %
            %       - 'duplicatesstrict': align values between different indices. Only duplicate values allowed in
            %                          case of exact equal indices (for which 1:1 mapping will be used). An
            %                          error will be raised in case of duplicates and not exactly equal.            
            % 
            %       - 'expand':        align values between indices. In case of duplicates, all combinations
            %                          between indices are added.
            %                          (option currently is limited to union between 2 indices)
            %
            %       - 'none':          no alignment of values, append all values of indices together, even if that
            %                          creates new duplicates.    
            %
            %
            %   - alignMethod: (string enum) select alignment method
            %       - 'strict': all indices need to have same unique values (else error thrown)
            %       - 'inner':  keep only unique values that are common in all indices
            %       - 'left':   keep only unique values as in the first index            
            %       - 'full':   keep all values (allow values missing in some indices) (default)
            %            
            %
            % OUTPUT:
            %   obj_new:   new Index object with new aligned index with N values
            %   ind:       index array(N,Nobj) with each column the position index into the original object
            %              for each corresponding input index object.
            %              (position index contain a NaN value if given index value is not present)

            arguments(Repeating)
                objs {isa(objs, 'frames.Index')}
            end
            arguments
                options.duplicateOption {mustBeMember(options.duplicateOption, ...
                                ["unique", "duplicates", "duplicatesstrict", "none", "expand"])} = "duplicates"
                options.alignMethod {mustBeMember(options.alignMethod, ["strict", "inner", "left", "full"])} = "full"  
                options.allowDimExpansion logical=false; % not used by Index, only MultiIndex
            end
            
            % get index objects
            obj = objs{1};
            Nobj = length(objs);
                                   
            % handle singletons indices
            singletons = cellfun(@(x) x.singleton, objs);
            if all(singletons)
                 obj_new = obj;
                 ind = ones(1, Nobj);
                return
            end
            objs_nosingleton = objs(~singletons);
            Nobj_nosingleton = length(objs_nosingleton);
            
            % handle equal indices
            if (options.duplicateOption=="duplicates" || options.duplicateOption=="duplicatesstrict") || ...
               (options.duplicateOption=="unique" && obj.isunique()) || Nobj_nosingleton==1               
                allsame = all(cellfun(@(x) isequal(x.value_,objs_nosingleton{1}.value_), objs_nosingleton));
                if allsame
                    % shortcut for performance: 1-to-1 mapping of indices
                    obj_new = objs_nosingleton{1};                    
                    ind = repmat((1:obj_new.length())', 1, Nobj);
                    if any(singletons)
                        ind(:,singletons) = 1;
                    end
                    return
                end                
            end
                                  
            % check uniqueness option      
            if obj.requireUnique
                 assert(options.duplicateOption=="unique", 'frames:Index:alignIndex:requireUniqueMethod', ...
                     "Only duplicateOption 'unique' allowed in union for index with requireUnique.");     
            end
                                                                
            % concat all (no singleton) inputs & get combined unique index
            objlen = cellfun(@length, objs);  
            objlen(singletons) = 0;
            obj_new = objs_nosingleton{1}.vertcat_(objs_nosingleton{2:end}); % no error checking on unique yet
            uniqind = obj_new.value_uniqind;
            
            if options.duplicateOption=="none"
                % no alignment, keep all raw concatenated values (including duplicates)
                if obj.warningNonUnique_ && obj.isunique() && ~obj_new.isunique()
                      warning('frames:Index:notUnique','Index value is not unique.')
                end
                
                % create simple position index - no alignment
                ind = nan(obj_new.length(), Nobj);
                p0 = 1;                
                for iobj=1:Nobj                   
                     p1 = p0+objlen(iobj);
                     ind(p0:p1-1, iobj) = 1:objlen(iobj);
                     p0 = p1;                                                               
                end
                
             elseif options.duplicateOption=="expand"
                    % align values, and expand duplicates
                    assert(length(objs)<=2,'frames:Index:alignIndex:expandtoomany', ...
                                            "expand option only allowed with 2 index objects"); %current implementation limitation
                    
                    % create indices per index object
                    uniqind1 = uniqind(1:objlen(1));
                    uniqind2 = uniqind(objlen(1)+1:end);
                    
                    % get expanded index (outer product of duplicates of both indices)
                    [posind1_expand, posind2_expand, posind_expand] = expandIndex(uniqind1,uniqind2);
                                                       
                    % create new index obj + cell index
                    if ~obj.requireUniqueSorted                        
                        ind = [posind1_expand posind2_expand];                                                
                    else                        
                        % sort by uniqind if required
                        [~, sortind] = sort(uniqind(posind_expand));                        
                        ind = [posind1_expand(sortind) posind2_expand(sortind)];                        
                    end
                    obj_new = obj_new.getSubIndex_(posind_expand,':');  

            else 
                % align values
                if  (options.duplicateOption=="duplicates" || options.duplicateOption=="duplicatesstrict")&& ~obj_new.isunique()
                    % align duplicates between different indices by its order
                    unique_section = cellfun(@(x) x.requireUnique || x.length()==0, objs);                        
                    label_dupl = labelDuplicatesInSections(uniqind, objlen, unique_section);
                    % define new uniq_ind with seperate values for duplicates based on its label
                    uniqind = uniqind*(length(label_dupl)+1) + label_dupl; 
                end
                
                % align index and update position index accordingly
                if obj.requireUniqueSorted                    
                   [~, ia, id] = unique(uniqind, 'sorted');
                else                                                         
                   [~, ia, id] = unique(uniqind, 'stable');                    
                end
                obj_new = obj_new.getSubIndex_(ia,':');  
           
            
                % handle 'duplicatesstrict' error condition
                if options.duplicateOption=="duplicatesstrict"
                    % remark: at this point it is known that the indices are not equal (that is handled above)  
                    assert(obj_new.isunique(), 'frames:Index:alignIndex:notUnique', ...
                        "Duplicates values in (unequal) indices not allowed in combination with duplicateOption 'duplicatesstrict'");                
                end            
                
                % get for each item in new index a position reference to original line
                % (if given item does not exist in given object, value is NaN)
                ind = nan(obj_new.length(), Nobj); 
                p0 = 1;
                for iobj=1:Nobj
                    if ~singletons(iobj)
                        p1 = p0 + objlen(iobj);
                        id_slice = id(p0:p1-1);
                        ind(flip(id_slice),iobj)= objlen(iobj):-1:1; %flipped to keep first occurrence in case of (overlapping) duplicates                    
                        p0 = p1;
                    else
                        % reference 1st element in case of singleton
                        ind(:,iobj) = 1;
                    end 
                end
                
            end
            
            % filter output based on alignMethods             
            maskNaN = ~isnan(ind);
            switch options.alignMethod
                case "full"
                    mask = true; % nothing to filter
                case "strict"
                    assert( all(maskNaN,'all'), 'frames:Index:alignIndex:unequalIndex', ...
                        "Unequal unique values not allowed in alignMethod 'strict'.");
                    mask = true; % nothing to filter
                case "inner"
                    mask = all(maskNaN,2);
                case "left"
                    mask = maskNaN(:,1);
            end            
            % only output selected rows in index
            if ~all(mask)
                obj_new = obj_new.getSubIndex_(mask,':');                
                ind = ind(mask,:);                
            end
           
             
            function [posind1_expand, posind2_expand, posind_expand] = expandIndex(uniqind1, uniqind2)
                % internal function to align both input vectors value, and output position index to the aligned vector.
                % duplicate values between the vectors will be expanded with all combinations (outer product).
                %
                % first focus on values present in obj1
                mask_obj2 = ismember(uniqind2,uniqind1);
                uniqind2_common = uniqind2(mask_obj2);                   % selection of obj2 values also present in obj1
                uniqind2_common_conv = (1:length(mask_obj2))';
                uniqind2_common_conv = uniqind2_common_conv(mask_obj2);  % to convert pos indices of uniqind2common to to original uniqind2

                % get unique ids (sequential, without missing values as needed for grouping method with histc in next step)
                [uniqind_seq_val, ~, uniqind_seq]= unique([uniqind1;uniqind2_common],'stable');
                uniqind1_seq = uniqind_seq(1:length(uniqind1));
                uniqind2common_seq = uniqind_seq(end-length(uniqind2_common)+1:end);        

                % find position indices in obj2 for each unique id
                [~,indicesList2common] = sort(uniqind2common_seq);
                indicesList2 = uniqind2_common_conv(indicesList2common); % convert to pos indices original uniqind2 (compensate for shift in numbering from applying mask_obj2 before)
                groups = (1:length(uniqind_seq_val))';
                groupCount2 = histc(uniqind2common_seq, groups);         %#ok<HISTC>
                posind2_cell = mat2cell(indicesList2, groupCount2, 1);   % cell array with position reference to each unique id in obj2
                posind2_cell((groupCount2==0)) = {NaN};                  % add NaN position index value if missing from obj2

                % get expanded position index obj1
                posind1 = (1:length(uniqind1_seq))';
                groupCount2_nonzero = groupCount2;
                groupCount2_nonzero(groupCount2==0) = 1;                 % minimal 1 
                posind1_expandcount = groupCount2_nonzero(uniqind1_seq);                
                posind1_expand = repelem(posind1, posind1_expandcount);
                
                % get expanded position index obj2
                posind2_expand = cell2mat( posind2_cell(uniqind1_seq) );

                % handle values only in obj2
                Nmissing_obj1 = sum(~mask_obj2);
                if Nmissing_obj1>0
                    posind1_expand = [posind1_expand; nan(Nmissing_obj1,1)];
                    posind2_exclusive = find(~mask_obj2);
                    posind2_expand = [posind2_expand; posind2_exclusive ];
                end
                
                % get combined expanded index (without NaN, referencing values of concatented obj_new)
                posind_expand = posind1_expand;
                if Nmissing_obj1>0
                   posind_expand(end-Nmissing_obj1+1:end) = posind2_exclusive + length(uniqind1);
                end                
            end
            
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
                    if iscolon(idxNew)
                       val_ = b_;
                    else
                        val_(idxNew) = b_;
                    end

                    obj.valueChecker(val_,idxNew,b_);
                    obj.value_ = val_;
                end
            else
                obj = builtin('subsasgn',obj,s,b);
            end
        end
        
       
        
    end
    
    methods(Access={?frames.TimeIndex,?frames.DataFrame,?frames.MultiIndex,?frames.Index})

        function pos = positionIn_(obj,objvalue, targetvalue)
            % internal, find position of the Index into the target            
            if obj.requireUnique_
                assertFoundIn(objvalue,targetvalue)
                if obj.requireUniqueSorted_
                    pos = ismember(targetvalue,objvalue);
                else
                    [~,~,pos] = intersect(objvalue,targetvalue,'stable');
                end
            else
                pos = findPositionIn(objvalue,targetvalue);
            end
        end         
        
  
        
 

       function obj = vertcat_(obj,varargin)
            % internal function for concatenation of multiple indices (no checks)
            others = [varargin{:}];
            val = vertcat(obj.value_, others.value_);
            obj.singleton_ = false;
            obj.value_ = val;
        end              
        
       function [selector, selectorInd] = getSelector_(obj,selector, positionIndex, allowedSeries, userCall, allowMissing)
            % get valid matlab indexer for array operations based on supplied selector
            % (internal function with extra optional output, see detailed description getSelector())            
            %
            % output:
            %    - selector:     validated array indexer (colon, logical array or position index array)
            %    - selectorInd:  (extra optional) array with for each item in selector corresponding selector entry id
            %             
            if iscolon(selector)
                % do nothing, just output colon
                if (nargout>1)
                   selectorInd = 1;
                end                   
            elseif islogical(selector) || isFrame(selector)
                %  logical selectors
                if userCall
                    obj.logicalIndexChecker(selector, allowedSeries);
                end
                selector = obj.getValue_from(selector);
                if (nargout>1)
                    selectorInd = find(selector);
                end
            elseif positionIndex
                % position index selector
                if userCall
                    obj.positionIndexChecker(selector);
                end
                if (nargout>1)
                   selectorInd = 1:length(selector);
                end
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
               
        
        function obj = setvalue(obj,value, userCall)
            if nargin<3, userCall=true; end
            if isIndex(value)
                value = value.value_;                
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
        
        function obj=getSubIndex_(obj,selector,~)
            % get Index object of sub selection based on matlab selector
            obj.value_ = obj.value_(selector);                        
        end
        
        function out = getname(obj)
            % get index name
            out = obj.name_;
        end
        
        function obj = setname(obj, value)
            % set index name
            assert(length(value)==1, 'frames:Index:setname:invalidcount', "only single dimension name allowed.");
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
                obj.value_isuniq_ = true;
            elseif obj.length()==0
                obj.value_uniq_=[];
                obj.value_uniqind_=[];
                obj.value_isuniq_ = true;
            else
                [obj.value_uniq_,~ ,obj.value_uniqind_] = unique(obj.value_, 'sorted');
                obj.value_isuniq_ = (length(obj.value_uniq_)==length(obj.value_));
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
                if obj.warningNonUnique_
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
                    assert( isequal(obj.value,selector.rows_.value), 'frames:logicalIndexChecker:differentRows', ...
                           "colSeries Selector has different rows");
                elseif allowedSeries=="onlyRowSeries"                   
                    assert(selector.rowseries, 'frames:logicalIndexChecker:onlyRowSeries', ...
                           "Indexing of columns only allowed with DataFrame logical rowSeries.");
                    assert( isequal(obj.value,selector.columns_.value), 'frames:logicalIndexChecker:differentColumns', ...
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
    
    methods(Static, Hidden)
        function fh = getPrivateFuncHandle(funcname)
            % helper function to access private methods/package functions from unit-tester
            % (not to be used in own code)
            fh = str2func(funcname);
        end
    end    
    
end

