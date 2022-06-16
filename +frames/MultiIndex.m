classdef MultiIndex < frames.Index
% MULTIINDEX: class to create multi dimensional index
%
% The MultiIndexs class enables multi-dimensional indexing. It stores the multi-dimensional index by storing a single
% Index object for each dimension. Methods, internal, as public exist to align these multi-indexes, perform selections
% and aggregations.
% 
% Use:  
%    frames.MultiIndex( ["a";"b";"c"] )                   % 1d array (limited to single dim)
%    frames.MultiIndex( ["a","A";"b","A";"c","B"] )       % 2d array (limited to same type per dimension)
%    frames.MultiIndex( {["a";"b";"c"],["A";"A";"B"]} )   % cell with array per dim
%    frames.MultiIndex( {"a","b","c" ; "A","A","B"} )     % 2d cell
%    frames.MultiIndex( {{"a","A"},{"b","A"},{"c","B"}} ) % nested cell   
% 
%    frames.MultiIndex( {1:3,5:7}, name=["dimX","dimY"] ) % assign dimension names

% Copyright 2022 Merijn Reijnders
%
    methods
        function obj = MultiIndex(value, nameValue)
            % constructor for MultiIndex
            %
            % value: cellarray(1:Ndim) with each cell the linear index data
            %    - frames.Index object (or compatible subclass)
            %    - array of input types supported by frames.Index
            %
            % each dimension should have the same number of elements, and combination of values has to be unique
            %
            arguments
                value = double.empty(0,1)
                nameValue.Name string = ""
                nameValue.Unique (1,1) = false
                nameValue.UniqueSorted (1,1) = false
                nameValue.Singleton (1,1) = false
            end
            % empty MultiIndex object with specified settings
            obj = obj@frames.Index(Unique=nameValue.Unique, UniqueSorted=nameValue.UniqueSorted, ...
                                   Singleton=nameValue.Singleton);
            if nameValue.Name==""
                obj = obj.setIndex(value);
            else
                obj = obj.setIndex(value, nameValue.Name);
            end
            % clear name if singleton
            if nameValue.Singleton
                obj.name = "";
            end                        
        end
                                           
        
        function [obj_new, ind] = align(objs, options)
            % ALIGN create new aligned MultiIndex based on common dimensions 
            % of both MultiIndex objects and implicit expansion of missing dimensions
            %
            % Remarks:            
            % The output index will keep the requireUnique and requireUniqueSorted settings from first object. 
            % 
            % 
            %
            % INPUT:
            %   objs:      multiple Index/MultiIndex objects to combine
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
            %   - allowDimExpansion (bool) allow expansion to add new dimensions
            %                              (expansion currently is limited to union between 2 indices)            
            %
            %
            % OUTPUT:
            %   obj_new:   new Index object with new aligned index with N values
            %   ind:       index array(N,Nobj) with each column the position index into the original object
            %              for each corresponding input index object.
            %              (position index contain a NaN value if given index value is not present)
            %                                    
            %  
            arguments(Repeating)
                objs {isa(objs, 'frames.Index')}
            end
            arguments
                options.duplicateOption frames.enum.duplicateOption = "duplicates"
                options.alignMethod frames.enum.alignMethod = "full"
                options.allowDimExpansion logical = true;
            end           
                                      
            % shortcut alignment code in case of equal Indices or singleton (for performance)             
            [obj_new, ind] = objs{1}.align_handle_simple_(objs);
            if ~isempty(obj_new), return; end 
            
            % convert all Index objects to MultiIndex
            Nobj = length(objs);
            for i = 2:Nobj
               if ~isMultiIndex(objs{i})                        
                    objs{i} = frames.MultiIndex(objs{i});
               end
            end            
            
            % handle equal dimensions names (and order)
            obj1 = objs{1};
            allSameDim = all( cellfun(@(x) x.singleton || (x.Ndim==obj1.Ndim && isequal(x.name,obj1.name)), objs(2:end)) );
            if allSameDim
               % no dimension expansion required, handle by Index.align() method
               [obj_new, ind] = align@frames.Index(objs{:}, duplicateOption=options.duplicateOption, ...
                     alignMethod=options.alignMethod, allowDimExpansion=options.allowDimExpansion);
               return;
            end
            
            % check limitations            
            assert(Nobj<=2, 'frames:MultiIndex:align:unsupportedexpansion', ...
                "Only 2 index objects supported in case of different dimension that require expansion."); 
            obj2 = objs{2};
            
            % find common dimensions            
            [dim_common_ind1, dim_common_ind2, dim_unique_ind1, dim_unique_ind2] = obj1.getMatchingDims(obj2);                       
            NextraDims2 = length(dim_unique_ind2);
            NextraDims1 = length(dim_unique_ind1);
            extraDimsNeeded = NextraDims1>0 || NextraDims2>0;
            assert(options.allowDimExpansion | NextraDims2==0, 'frames:MultiIndex:align:expansiondisabled', ...
                          "Dimension expansion disabled, while obj2 has other dimension(s) as obj1.");                        
                       
            if ~isempty(dim_common_ind1)            
                 % get common dimension indices to align on
                 obj1_common = obj1.getSubIndex_(':', dim_common_ind1);
                 obj2_common = obj2.getSubIndex_(':', dim_common_ind2);                 
                 % use 'expansion' option in case of adding new dimensions
                 if extraDimsNeeded && options.duplicateOption~="expand"
                     assert(obj1.isunique() && obj2.isunique(), 'frames:MultiIndex:align:invalidduplicatesexpansion', ...
                        "Index is not unique. Duplicate values are not supported in case of dimension expansion " + ...
                        "using duplicateOption " + string(options.duplicateOption));                                                                       
                     options.duplicateOption="expand";
                 end                     
                 % run align from Index on common dimensions             
                 [obj_new, ind_new] = ...
                     align@frames.Index(obj1_common, obj2_common, alignMethod=options.alignMethod, ...
                                                                       duplicateOption=options.duplicateOption);
                 ind1_new = ind_new(:,1);
                 ind2_new = ind_new(:,2);
                
                % add extra dimensions to index (after expansion)
                assert( (NextraDims1==0 || ~any(isnan(ind1_new)) ) && ...
                        (NextraDims2==0 || ~any(isnan(ind2_new)) ), 'frames:MultiIndex:align:invalidexpansion', ...
                        "Cannot expand dimension(s) if common dimension(s) contain uncommon values between objects.");                 
                if NextraDims1>0                    
                    obj1_newdim = obj1.getSubIndex_(ind1_new, dim_unique_ind1);
                    obj_new.value_(end+1:end+obj1_newdim.Ndim) = obj1_newdim.value_;
                    % restore dimension ordering of obj1
                    [~, dimorderobj1]=intersect(obj_new.name, obj1.name);
                    obj_new.value_ = obj_new.value_(dimorderobj1);
                end
                if NextraDims2>0
                    obj2_newdim = obj2.getSubIndex_(ind2_new, dim_unique_ind2);
                    obj_new.value_(end+1:end+obj2_newdim.Ndim) = obj2_newdim.value_;                                        
                end                                                                                               
             
            else
                % no common dimensions: no alignment required
                % create indices with all combinatons using meshgrid               
                [ind1_new,ind2_new] = meshgrid(1:length(obj1), 1:length(obj2));
                ind1_new = ind1_new(:);
                ind2_new = ind2_new(:);                
                % get expanded obj1 as basis
                obj_new = obj1.getSubIndex_(ind1_new,':');                
                % add expanded obj2 dimensions
                obj2_new = obj2.getSubIndex_(ind2_new,':');                
                obj_new.value_(end+1:end+obj2_new.Ndim) = obj2_new.value_;
            end
                                                     
             % sort if required
            if obj1.requireUniqueSorted
                % sort output index
                [obj_new, sortindex] = obj_new.sort();
                % update position indices accordingly
                ind1_new = ind1_new(sortindex);
                ind2_new = ind2_new(sortindex);
            end 
            ind = [ind1_new ind2_new];
        end
        
        
    end
    methods(Access={?frames.TimeIndex,?frames.DataFrame,?frames.MultiIndex,?frames.Index})
        
        
        function out = getSelector_(obj,selector, positionIndex, allowedSeries, allowMissing, asFilter, userCall)
            % get valid matlab indexer for array operations based on supplied selector
            %
            % selector definition:
            %    - colon
            %    - logical array/ logical Series
            %
            %    - index position array               ***only in case of position indexing***
            %
            %    - cell array with 'selector set(s)'  ***only in case of value indexing***
            %
            %         A 'selector set' consists of a cell array(1:Ndim).
            %         The values in the cells are passed to the getSelector function for each dimension.
            %         If selector has less cells than number of dimensions stored, there will be no
            %         selection criteria applied for those missing dimensions.
            %
            %         Multiple 'selector sets' can be combined by nesting them in a cell array.
            %
            % ----------------
            % Parameters:
            %    - selector            
            %    - positionIndex  (logical):    selector is position index instead of value index (default false)
            %    - allowedSeries: (string enum: 'all','onlyRowSeries','onlyColSeries') (default 'all')
            %                                   accept only these logical dataframe series            
            %    - allowedMissing (logical):    allow selectors with no matches (default false)
            %    - asFilter       (logical):    interpret selector as filter criteria of index (default false)
            %                                   (keep original order independent of order in selector,
            %                                    ignore duplicates and allow not matching selector sets)
            
            %    - userCall       (logical):    perform full validation of selector (default true)            
            %
            % output:
            %    validated array indexer (colon, logical array or position index array)
            %
            if nargin<3, positionIndex = false; end
            if nargin<4, allowedSeries = 'all'; end
            if nargin<5, allowMissing=false; end  
            if nargin<6, asFilter = false; end
            if nargin<7, userCall = true; end
            
            if iscolon(selector)
                % colon selector
                out = ':'; % note: this also converts colon in cell to just a colon
                
            elseif positionIndex
                % position index selector (so no selector per dimension allowed)
                assert(~iscell(selector), 'frames:MultiIndex:noCellAllowedPositionIndex', ...
                    "No cell selector allowed in combination with position indexing.");
                out = getSelector_@frames.Index(obj,selector, positionIndex, allowedSeries, allowMissing, asFilter, userCall);
                
            elseif islogical(selector) || isFrame(selector)
                % value selector (with logicals)
                out = getSelector_@frames.Index(obj,selector, positionIndex, allowedSeries, allowMissing, asFilter, userCall);
                
            else
                % value selector (with 'selector set(s)')
                selector = obj.convertCellSelector(selector); % make sure it is nesdted cell with selector sets
                % calculate logical mask as selector
                if asFilter
                    out = false(obj.length(),1);  % output is a logical array
                else
                    out = [];                     % output is a position array
                end
                for iset = 1:length(selector)
                    % get mask of maskset by looping over supplied dimensions
                    selectorset = selector{iset};
                    
                    maskset = getSelectorSetFilterMask_(obj, selectorset, iset, positionIndex, allowedSeries);
                    if ~any(maskset) && ~isempty(selectorset{1})
                        if asFilter
                            warning('frames:MultiIndex:emptySelectorSet',"No matches found for selector set %i.", iset);
                        else
                            error( 'frames:MultiIndex:emptySelectorSet', "No matches found for selector set %i.", iset);
                        end
                    end
                    
                    if ~asFilter
                        
                        if ~all(cellfun(@length, selectorset)==1)                            
                             % pre-filter Multi-Index based on logical mask (for speedup)                                                                                                    
                             objfilt = obj.getSubIndex(maskset);
                             % replace logical selectors by ':' for usage in combination with objfilt
                             selectorsetFilt = selectorset;
                             selectorsetLogical = cellfun(@islogical, selectorset);
                             if any(selectorsetLogical) 
                                selectorsetFilt{selectorsetLogical}= ':';                             
                             end
                             % get order of items based on selectorset
                             posIndexFilt = getSelectorSetPosIndex_(objfilt, selectorsetFilt, positionIndex, allowedSeries);
                             % convert positon to original (unfiltered) positions
                             maskpos = find(maskset);
                             posIndex = maskpos(posIndexFilt);
                        else
                            % in case of only single indices, skip filtering
                            posIndex = find(maskset);
                        end
                    end
                                        
                    % combine masks of different masksets
                    if asFilter
                        out = out | maskset;
                    else
                        out = [out ; posIndex]; %#ok<AGROW>
                    end
                end
            end
            if asFilter && ~any(out)
                warning('frames:MultiIndex:emptySelection',"No matches found, empty selection");
            end
            
            
            % sub-helper functions
            
            function [mask] = getSelectorSetFilterMask_(obj,selectorset, iset, positionIndex, allowedSeries)
                % functions gets logical mask for given selectorset filter
                mask = true(obj.length(),1);
                assert(length(selectorset)<=obj.Ndim, 'frames:MultiIndex:tooManyDim', ...
                    "More cells (%i) in selector (set %i) than dimensions in MultiIndex (%i).", ...
                    length(selectorset), iset, obj.Ndim);
                for j = 1:length(selectorset)                    
                    masklayer = obj.value_{j}.getSelectorMask(selectorset{j}, positionIndex=positionIndex, ...
                                                              allowedSeries=allowedSeries, allowMissing=true, ...
                                                              asFilter=false, userCall=false);
                    mask = mask & masklayer;
                end
                
            end
            
            function posIndex = getSelectorSetPosIndex_(obj,selectorset, positionIndex, allowedSeries)
                % function gets position index for given selectorset (non-filtered), keep order and duplicates
                % as specified in selector
                
                % shortcut main code (for speedup) in case of just a single dimension specified
                iscolonDim = cellfun(@iscolon, selectorset);
                if sum(~iscolonDim)==1
                    % only a single non-colon dimension
                    dim = find(~iscolonDim);
                    posIndex = obj.value_{dim}.getSelector_(selectorset{dim},positionIndex, allowedSeries, true, false, false); 
                    return
                end
                                
                % get linear-index position selections for every dimension in selector
                Nindex = length(obj);
                NselectorDim = length(selectorset);
                pos = cell(1, NselectorDim);
                indseq = cell(1, NselectorDim);                
                for i=1:NselectorDim
                    if ~iscolonDim(i)
                        % get linear-index selector
                        [pos{i}, indseq{i}] = obj.value_{i}.getSelector_(selectorset{i},positionIndex, allowedSeries, true, false, false);                        
                    else
                        % special case: handle colon
                        pos{i} = (1:Nindex)';
                        indseq{i} = ones(Nindex,1);                        
                    end
                end                               
                % dimensions to use
                rootDim = 1;
                loopDims = 2:NselectorDim; 
                p = pos{rootDim};
                
                % align cell array with indexes with selector dim1
                indseq_grouped_aligned = cell(1,NselectorDim );
                indseq_grouped_aligned{1} = num2cell(indseq{rootDim });
                for i=loopDims
                    % get for each MultiIndex row the selector sequence number(s) of values responsible for selection
                    indseq_grouped = getSelectorIndicesForEachValue(pos{i}, indseq{i}, Nindex);                               
                    % align indices according the main reference dimension
                    indseq_grouped_aligned{i} = indseq_grouped(p);
                end
                
                % convert nested cell array to 2d cell (required for further manipulation)
                ind_alignAll = horzcat(indseq_grouped_aligned{:});
                
                % expand rows with all combinations
                [posIndexRaw,outind] = expandCombinationsCell(ind_alignAll);
                
                % get sorted row positions
                [~, sortind] = sortrows(posIndexRaw);
                outind_sorted = outind(sortind);
                posIndex = p(outind_sorted);                
            end
            
            function ind_cell = getSelectorIndicesForEachValue(pos, indseq, N)
                % get cell array(N) with cell(i) the position indices of vector x with value i
                % (values of vector x has to be in range 1 to N)
                [~,ix] = sort(pos);
                c = histc(pos, 1:N); %#ok<HISTC>
                ind_cell = mat2cell(indseq(ix),c,1);
            end
            
        end        
        
        
        
        function [objnew, ind] = align_handle_simple_(obj, objs)
                % internal function to check and handle simple cases (equal index or singleton)
                %
                % default empty
                objnew = []; 
                ind = [];
                % handle single index case
                Nobj = length(objs);             
                if Nobj==1
                    obj_new = objs{1};
                    ind = (1:length(obj_new))';
                    return
                elseif Nobj>2
                    % not handled by this simple function
                    return
                end            

                % handle equal and singleton cases
                obj1 = objs{1};
                obj2 = objs{2};
                assert(isIndex(obj2), 'frames:Index:align:requireIndex', "obj2 is not a Index object.");
                if isequal(obj1.value_,obj2.value_)
                    objnew = obj1;
                    ind1 = (1:length(obj1))';
                    ind2 = ind1;
                elseif ~obj1.singleton && obj2.singleton
                    objnew = obj1;
                    ind1 = (1:length(obj1))';
                    ind2 = ones(size(ind1));
                elseif obj1.singleton && ~obj2.singleton
                    objnew = obj2;
                    ind2 = (1:length(obj2))';
                    ind1 = ones(size(ind2));
                else 
                    return
                end
                ind = [ind1 ind2];
            end               
        end
        

    
    
    methods
        
                     
        
        function disp(obj)
            % display MultiIndex values and properties
            dispnames = obj.name;
            dispnames(dispnames=="")="<missing>";
            val = cellfun(@(x) x.value, obj.value_,'UniformOutput',false);
            if ~isempty(val)
               disptable = table( val{:}, 'VariableNames', cellstr(dispnames));            
               disp(disptable);
            end
            details(obj);
        end
        
        function val = getValueForTable(obj)
            % convert value to strings to use with a table
            val = string(obj.getvalue_cell('rowcol'));
            if ~iscolumn(val)
               val = join(val," ");
            end
            val(ismissing(val))="<missing>";
            val = matlab.lang.makeUniqueStrings(val,{},namelengthmax());
            val = cellstr(val);
        end
        
        
        function obj = setIndex(obj, value, name)            
            % assign index and dimension names
            %            
            % default parameters
            if nargin<3, name=[]; end            
            % assign values (+ default names)
            obj.value = value;            
            % assign supplied names                                                
            if ~isempty(name)
               assert(isstring(name) && length(name)==obj.Ndim, "Name should be string array with Ndim values.");
               for i=1:obj.Ndim                                    
                 if name(i)~=""
                     % assign supplied name
                     obj.value_{i}.name = name(i);
                 end
               end
            end
            obj.nameChecker();
        end
        
        function obj = addDimension(obj, values, name)
            % add (single) linear dimension to MultiIndex
            %
            % parameters:
            %    values: array(1:Nrows) with values as new index
            %            Index object to add
            %    name: string with dimension name            
            %
            if nargin<3, name=""; end
            if isIndex(values)
                % use existing Index object
                newIndexObj = values;
                if name~="", newIndexObj.name=name; end                
            else
                % convert values to Index object
                assert(obj.Ndim==0 || length(values)==obj.length(), ...
                    "Length value not same as existing index length");
                assert(name~="", "Error no valid name supplied");
                newIndexObj = frames.Index(values, Name=name, warningNonUnique=false);                
            end
            % append to multiindex
            obj.value = [obj.value_ {newIndexObj}];
        end
        
        
        function [common_ind1, common_ind2, unique_ind1, unique_ind2] = getMatchingDims(obj1, obj2)
            % find common and unique dimensions between two MultiIndex
            %
            % input: obj1,obj2: MultiIndex objects
            %
            % output:
            %    common:       string array of common dimensions
            %    common_indX:  array with common dimension indices of MultiIndex object X
            %    unique_indX:  array with unique dimension indices of MultiIndex object X
            %
            [~, common_ind1, common_ind2] = intersect(obj1.name, obj2.name, 'stable');
            [~, unique_ind1, unique_ind2] = setxor(obj1.name, obj2.name);
        end
        
        function dimind = getDimInd(obj, dim)
            % get position index of specified dimension names
            [~, dimind, ~ ] = intersect(obj.name, dim);
            assert(length(dimind)==length(dim), 'frames:MultiIndex:getDimInd:notAllDimFound',...
                "error not all dimension are present");
        end
        
        function out = getvalue_cell(obj, type)
            % get values of multiindex (stored in multiple Index objects) as cell array
            % supports multiple arrangements
            %
            % type:
            %   - "col":    cell(1,Ndim), separate dimensions as array in cell
            %   - "row":    cell(Nindex,1), rows in nested cell array <== does not look so usefull (remove?)
            %   - "rowcol": cell(Nindex,Ndim), all individual values in cell (default)
            %
            if nargin<2, type="rowcol"; end
            switch type
                case "col"
                    % columns/dimensions in single cell
                    out = cellfun(@(x) x.value, obj.value_, 'UniformOutput', false);
                case "row"
                    % cell array with every row a nested cell with row values
                    out = cell(length(obj),1);
                    for j=1:length(obj)
                        row = cell(1,obj.Ndim);
                        for i=1:obj.Ndim
                            row{i} = obj.value_{i}.value_(j);
                        end
                        out{j} = row;
                    end
                case "rowcol"
                    % every value in separate cell
                    out  = cell(obj.length() ,obj.Ndim);
                    for i=1:obj.Ndim
                        out(:,i) = arrayfun(@(x) {x}, obj.value_{i}.value);
                    end
                otherwise
                    error("unsupported type '%s'.", type);
            end
        end                
      
     function len = length(obj)
       if isempty(obj.value_)
          len = 0;
       else
          len = obj.value_{1}.length();
       end
     end
     
     function bool = isunique(obj)
         % check if MultiIndex values are unique
         if obj.requireUnique_
             bool = true;
         elseif obj.Ndim<=1
             % from cache of the single linear index object 
             bool = obj.value_{1}.value_isuniq_;
         else
             % calculate with unique
             bool = isunique(obj.value_uniqind);
         end
     end
        
        
    end
    methods(Access={?frames.TimeIndex,?frames.DataFrame,?frames.MultiIndex,?frames.Index})
        
        function obj = vertcat_(obj,varargin)
            % concatenate multiple MultiIndex objects with same dimensions (limited checks)
            newvalue=obj.value_;
            % combine indices
            for i=1:length(varargin)
                item = varargin{i};
                assert(isa(item,'frames.MultiIndex'), 'frames:MultiIndex:vertcat_:onlyMultiIndex', ...
                    "error, can only concatenate MultiIndex objects");
                assert(all(obj.name==item.name | item.name==""), 'frames:MultiIndex:vertcat_:dimsNotEqual', ...
                    "error, dimensions not equal");
                for j=1:obj.Ndim
                    newvalue{j} = newvalue{j}.vertcat_(item.value_{j});
                end
            end
            % assign to MultiIndex
            obj = obj.setvalue(newvalue, false); %skip value checks / unique warning            
        end        
        
        
        function obj = setvalue(obj, value, userCall)
            % SETVALUE: store index values of every dimension as Index objects and validate row uniqueness
            %
            % input:
            %  -  value: (multiple syntaxes)
            %      - 1d cell array(1:Ndim) with each cell 
            %          - frames.Index object or
            %          - array of input types supported by frames.Index
            %
            %      - 2d cell array(1:Nrow, 1:Ndim) with each cell a dim value
            %
            %      - nested cell(1:Nrows): with each item a cell array with a single row entry, eg:
            %            { {val_row1_dim1, val_row1_dim2}, {val_rowN_dim1, val_rowN_dim2} }
            %                    
            %      - array(1:Ndim) with frames.index objects
            %
            %      - array(1:Nrows,1:Ndim) with index values (numerical, strings, ...)
            %
            %      each dimension should have the same number of elements
            %
            %  - userCall: logical, to enable checks on values
            %
            if nargin<3, userCall=true; end
            if isempty(value)
                % in case no value, just add empty Index object
                nameold = obj.name;                
                obj.value_ = {frames.Index(value, warningNonUnique=false)};                
                if nameold~=""
                    obj.value_{1}.name = nameold;
                else
                    obj.value_{1}.name = "dim1";
                end
                return;
            end
            
            % flag to create builtup MultiIndices
            createIndices = true;
            
            % handle: [frames.Index, frames.Index, ...]
            if isvector(value) && isIndex(value(1)) && ~isMultiIndex(value(1))
                % handle array of Index objects by first converting to cell array
                value = num2cell(value);
                userCall = false; % prevent check of conversion of already existing index object
            end
            
            % handle different syntax of cell arrays
            if iscell(value)                                    
                if all(cellfun(@iscell, value))
                    % handle: nested cells: {cell_array_row_values1, ..., cell_array_row_valuesM}
                    % interpret every nested cell as a row of MultiIndex, convert to 1d cell array with index objects
                    Ndims = length(value{1});
                    assert( all(cellfun(@length, value)==Ndims), ...
                        'frames:MultiIndex:setvalue:requireSameNrDimsNestedCell', ...
                        "Nested cell array interpreted as rows of MultiIndex. Each nested cell should " + ...
                        "have the same number of elements.");
                    value_new = cell(Ndims,1);
                    for i=1:Ndims
                        if ~ischar(value{1}{i})
                            % concatenate values from cell array to array
                            values_dim = cellfun(@(x) x{i}, value);
                        else
                            % exception for char, concatenated array should be cell array
                            values_dim = cellfun(@(x) x{i}, value, 'UniformOutput', false);
                        end
                        value_new{i} = frames.Index(values_dim, warningNonUnique=false);
                    end
                    value = value_new;          
                elseif ~isvector(value) || (numel(value)>1 && length(value{1})==1)
                    % handle: 1d/2d cell array (Nrows,Ndim) with single elements
                    %         ==> convert to 1d cell array (Ndim) with Index Objects
                    Ndims = size(value,2);
                    value_new = cell(Ndims,1);
                    for i=1:Ndims
                        value_array = [value{:,i}];
                        value_new(i) = {frames.Index(value_array, warningNonUnique=false)};
                    end
                    value = value_new;                        
                else
                    % handle: 1d cell(1:Ndim) with arrays per dimension
                    DimLengths = length(value{1});
                    assert( all(cellfun(@length, value)==DimLengths), ...
                        'frames:MultiIndex:setvalue:dimensionsNotSameLength', ...
                        "Not all dimensions in cell array have the same number of elements.");                    
                end
                
            else
                if ~isMultiIndex(value(1))
                    % handle: 1d & 2d array(Nrows, Ndim)
                    Ndim = size(value,2);
                    Nrows = size(value,1);
                    value = mat2cell(value, Nrows , ones(1, Ndim));                                    
                else
                    % handle MultiIndex
                    assert(numel(value)==1, 'frames:MultiIndex:setvalue:requireSingleMultiIndex', ...
                        "Only single MultiIndex allowed.")                                        
                    createIndices = false;
                    indices = value.value_;  % cell array of Index() objects for each dim
                end
            end
            
            % create Index objects for all dimensions
            if (createIndices)
                Ndims = length(value);
                indices = cell(1,Ndims);
                for i = 1:Ndims
                    val = value{i};
                    if numel(val)==1 && isIndex(val)
                        % linear index should not be unique
                        val.requireUniqueSorted=false;
                        val.requireUnique=false;
                        val.warningNonUnique_=false;
                        indices{i} = val;
                    else
                        % convert to linear index
                        indices{i} = frames.Index(val, Unique=false, Singleton=obj.singleton, ...                       
                                       warningNonUnique=obj.singleton); % no unique warning
                        %                     (except in case of singleton to produce the same
                        %                     objects as by DataFrame (by .row, .columns, aggregation etc),
                        %                     usefull for current defined unit test cases)                                                
                                                
                    end
                    % get default names
                    if indices{i}.name=="" && ~obj.singleton
                        if numel(obj.value_) >= i && obj.value_{i}.name~=""
                            % use name of existing dimension
                            indices{i}.name = obj.value_{i}.name;
                        else
                            % use default name
                            indices{i}.name = "dim"+i;
                        end
                    end
                end
            end
            
            % assign new values to object
            obj.value_ = indices;
            
            % handle singleton case
            if obj.Ndim==1 && indices{1}.singleton
                obj.singleton = true;
            end
            
            % check dimension names and uniqueness of rows
            if userCall
               obj.valueChecker();
               obj.nameChecker();
            end
        end

        function obj=getSubIndex_(obj,selector, dimindex)
            % get Index object of sub selection based on (matlab) selector
            %
            % internal use: no validation checks, see details at getSubIndex()
            %                         
            % select dimensions            
            if ~iscolon(dimindex)
                obj.value_ = obj.value_(dimindex);
            end
            % select rows
            if ~iscolon(selector)
                for i=1:obj.Ndim
                  obj.value_{i} = obj.value_{i}.getSubIndex(selector);
                end
            end
        end        
        
        function out = getname(obj)
            % get array of names for every dimension (from Index objects)
            if obj.Ndim > 0
                out = cellfun(@(x) x.name, obj.value_);
            else
                out="";
            end
        end
                
        function obj = setname(obj, value)
            % set names of every dimension             
            if obj.Ndim > 0
                assert(length(value)==obj.Ndim, 'frames:MultiIndex:setname:invalidcount',...
                                                "number of names should be equal to number of dimensions");
                for i=1:obj.Ndim
                    obj.value_{i}.name = value(i);
                end
            end
        end
        
        
        function v = getValue(obj)
            % output MultiIndex values
            %v = obj.getvalue_cell("rowcol"); %as cell(Nindex,Ndim)
            %v = obj.getvalue_cell("col");   % as cell(Ndim) with cell an array
            v = obj.getvalue_cell("row");   % as nested cell(Nindex) cell(Ndim)
        end
        
        function Ndim = get_Ndim(obj)
            % get number of dimensions            
            Ndim = size(obj.value_,2);
        end
        
        
        function obj = set_singleton(obj,tf)
            % set singleton
            obj = set_singleton@frames.Index(obj, tf);
            obj.name = ""; % remove name (for MultiIndex keeping name is not consistent in case of multiple dimensions)            
        end    
        
        function out = getvalue_uniq(obj)
            % get unique values of every dimension (from Index Objects)
            if obj.Ndim>0
                out = cellfun(@(x) x.value_uniq, obj.value_);
            else
                out = {};
            end
        end
        
        function obj = recalc_unique_cache(obj)
            % recalculate unique cache
            % <do nothing at MultiIndex>
        end
        
        function nameChecker(obj)
            % check if names of dimensions are valid
            name_unique = unique(obj.name);
            assert(length(obj.name)==length(name_unique), "dimension names not unique");
        end
        
        function valueChecker(obj,~,fromSubsAsgnIdx,b)
            % validate current multiIndex values
            %            
            % check if rows are unique
            Nindex = obj.length();
            rows_uniqind = unique(obj.value_uniqind,'stable');
            if size(rows_uniqind,1)~= Nindex
                if obj.requireUnique_
                    rows_not_unique = setdiff(1:Nindex, rows_uniqind);
                    error('frames:MultiIndex:requireUniqueFail', ...
                        "Combination of dimension values should be unique. " + ...
                        "The following multi-index rows are not unique: " + ...
                        num2str(rows_not_unique));
                else
                    warning('frames:MultiIndex:notUnique', ...
                        'MultiIndex row values are not unique.')
                end
            end
            % check sorted            
            assert(~obj.requireUniqueSorted || issorted(obj.value_uniqind), ...
                'frames:MultiIndex:requireSortedFail',  ...
                'Index value is required to be sorted and unique.')
        end
        
        
        function valueOut = getValue_andCheck(obj,value,userCall)
            % TODO
            valueOut = value;
        end
        
        %function out = getMissingData_(~),  out = {missingData('frames.Index')};  end
        %function out = getDefaultValue_(~),  out = {defaultValue('frames.Index')};  end 
        
        function out = getMissingData_(~)
            val = missingData('frames.Index');
            val.warningNonUnique_=true;
            out = {val};
        end
        
        function out = getDefaultValue_(~)
            val = defaultValue('frames.Index');
            val.warningNonUnique_=true;
            out = {val};
        end 

        
        function selector = convertCellSelector(obj, selector, singleItemPerSet)
            % convert selector to nested cell array with 'selector sets' and perform checks
            if nargin<3, singleItemPerSet=false; end
            if ~iscell(selector)                    
                    % single value selector (allowed in case of single dimension, like in Index)
                    assert(obj.Ndim<=1, ...
                        'frames:MultiIndex:getSelector:cellselectorrequired', ...
                        "Cell selector required in case of value-indexing in MultiIndex with more than 1 dimension.");
                    if ~singleItemPerSet
                       selector = {{selector}}; 
                    else
                       %selector = {mat2cell(selector(:)', 1, ones(1,length(selector)))}; 
                       selector = num2cell(num2cell(selector(:)')); 
                    end
            end            
            isnestedcell = cellfun(@iscell, selector);
            if ~any(isnestedcell)
                % add celllayer (simplifies processing to make all the same)
                selector = {selector};
            elseif ~all(isnestedcell)
                error('frames:MultiIndex:getSelector:notallnestedcells', ...
                    "Some cells in selector contain a nested cell array and other's do not. " + ...
                    "This is not allowed. Nested cell arrays are interpreted as separate 'selector sets'. " + ...
                    "If used, all cells must contain nested cell arrays.");
            end           
        end
        
        
        function out = getvalue_uniqind(obj, orderColumnMajor)
            % get uniqind vector based on all dimensions
            % 
            % input:
            %    column_major_ordering: logical 
            %             true:  column-major (default)
            %             false: row-major             
            if nargin<2, orderColumnMajor=true; end                   
            if obj.Ndim==1
                % single linear index
                out = obj.value_{1}.value_uniqind;
            elseif obj.Ndim>1                
                % multiple linear indices
                uniqind = cell2mat(cellfun(@(x) x.value_uniqind, obj.value_,'UniformOutput',false));  % all uniqind as columns                                                
                Ndim_uniq = cellfun(@(x) length(x.value_uniq{1}), obj.value_);  % number of unique values per dimension
                % get multiplication factor per dim
                if orderColumnMajor
                    % column-major ordered index
                    DimMultiplicationFactor = cumprod( [Ndim_uniq(2:end) 1], 'reverse');                                  
                else
                    % row-major ordered index
                    DimMultiplicationFactor = cumprod( [1 Ndim_uniq(1:end-1)] );                               
                end
                    % matrix multiplication to calc combined uniqind vector
                    out = (uniqind-1) * DimMultiplicationFactor' + 1;
            else
                out = [];
            end
        end                
        
    end
    
    methods(Hidden)
        function obj = subsasgn(obj,s,b)
            if s(1).type=="." && s(1).subs=="value"
                assert(length(s)<=2, "Nested subsasgn of MultiIndex value property not supported.");
                % get selector index
                if length(s)==1
                    rowIdx = ':';
                    dimIdx = ':';
                elseif s(2).type=="()" || s(2).type=="{}"
                    rowIdx = s(2).subs{1};
                    if length(s(2).subs)>1                    
                        dimIdx = s(2).subs{2};
                        if isstring(dimIdx) && ~iscolon(dimIdx)
                           dimIdx = obj.getDimInd(dimIdx);                         
                        end
                        assert(iscolon(dimIdx) || length(dimIdx)==1, "Only selection of single dimension allowed");
                    else
                        dimIdx = ':';
                    end
                else
                    error("unsupported selector type");
                end

                if isequal(b,[])
                    % remove full rows from index
                    assert((ischar(dimIdx) || isstring(dimIdx)) && dimIdx==":", ...
                        "All dimensions should be selected to delete a multiIndex value.");
                    % loop over dimensions and remove selected items
                    for idim=1:obj.Ndim
                        obj.value_{idim}.value_(rowIdx) = [];
                    end
                    if obj.singleton_
                        assert(isSingletonValue(obj.value_),'frames:Index:valueChecker:singleton', ...
                             'The value of a singleton Index must be missing.')
                    end
                else
                    %update value(s) in underlying dimensions indices
                    b_ = obj.getValue_from(b);
                    if isrow(b), b_=b_'; end
                    if obj.Ndim==1 && isrow(b_), b_=b_'; end
                    if iscolon(dimIdx)
                        % assign full rows               
                        if isvector(b_) && all(iscell(b_)) && all(cellfun(@iscell,b_))
                           % convert nested cell to cell(Nrows, Ndim)
                           b_ = reshape([b{:}], [length(b{1}), length(b)])';
                        end                                              
                        assert(size(b_,2)==obj.Ndim, ...
                             "Number of columns in new value (b) not equal to number of dimensions.");
                        %assert(size(b_,1)==obj.length(), ...
                        %    "Number of rows in new value (b) not equal to number of rows in object.");
                        for idim=1:obj.Ndim                           
                           if iscell(b_)
                               val = [b_{:,idim}];
                           else
                               val = b_(:,idim);
                           end                           
                           % call index object subsasgn method to handle custom data formats (eg timeIndex formats)
                           obj.value_{idim}.value(rowIdx) = val; 
                        end                    
                    else
                        % assign single dimension
                        if iscell(b_), b_=cell2mat(b_); end
                        obj.value_{dimIdx}.value(rowIdx) = b_;                        
                    end
                end
                obj.valueChecker(); % check if properties are respected                
            else
                obj = builtin('subsasgn',obj,s,b);
            end            
        end
        
        
        function varargout = subsref(obj,s)
            % implementation of custom data access methods
            if length(s)==2 && s(1).type=="." && s(1).subs=="value" && ...
                    ismember(s(2).type,["()","{}"]) && length(s(2).subs)==2
                % access linear dimension value array by .value(ind, dimind)            
                rowSelector = s(2).subs{1};
                dimSelector = s(2).subs{2};
                assert(length(dimSelector)==1,"Only selection of single dimension allowed (or ':' for 2d cell array).");
                if iscolon(dimSelector)
                    % output 2d cell array
                    out = obj.getvalue_cell("rowcol");
                    varargout = {out(rowSelector,:)};
                else
                    % output single linear dimension
                    if isstring(dimSelector)
                        dimind = obj.getDimInd(dimSelector);
                    else
                        dimind = dimSelector;
                    end
                    varargout = {obj.value_{dimind}.value(rowSelector)};                  
                end
            else
                [varargout{1:nargout}] = builtin('subsref',obj,s);
            end
        end
      
        
    end
    
    
    
    methods                                  
        
        function obj = vertcat(obj,varargin)
            % concatenate multiple MultiIndex objects with same dimensions
            obj = obj.vertcat_(varargin{:});
            obj.setvalue(obj.value_); % check if properties are respected    
        end
        

        function pos = positionIn(obj,target, ~)
            % find position of the Index into the target
            if ~isIndex(target)
                target=frames.MultiIndex(target);
                assert(target.Ndim==obj.Ndim, 'frames:MultiIndex:positionIn:unequalDim', ...
                     "Unequal dimensions obj (%i) and target (%i).", obj.Ndim, target.Ndim);
                target.name = obj.name;
            end
            % get common unique index 
            obj_new = obj.vertcat_(target); % no error checking on unique yet
            uniqind = obj_new.value_uniqind;
            uniqind_obj = uniqind(1:length(obj));
            uniqind_target = uniqind(length(obj)+1:end);
            % get position index
            pos = obj.positionIn_(uniqind_obj, uniqind_target);
        end
                    
        
       function out = ismember(obj, value)
            % check if value(s) is/are present in index
            value = obj.convertCellSelector(value, true);
            N = length(value);
            out = false(N,1);
            r = obj.value;            
            for i=1:N
                out(i) = any(cellfun(@(x) isequal(x,value{i}), r));
            end              
        end
    

        
    
      end
end