classdef MultiIndex < frames.Index
    % MULTIINDEX: class to create multi dimensional index
    %
    % work-in-progress
    %
    properties(Dependent)
        Ndim
    end
    
    
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
                nameValue.Name = ""
                nameValue.Unique (1,1) = false
                nameValue.UniqueSorted (1,1) = false
                nameValue.Singleton (1,1) = false
            end
            %obj = obj@frames.Index(value); % name-value options ignored
            obj = obj.setIndex(value, nameValue.Name);
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
            if nargin<3; dimindex=1:obj.Ndim; end            
            for i=1:length(dimindex)
                idim = dimindex(i);
                obj.value_(idim) = obj.value_(idim).getSubIndex(selector);
            end
            % remove dims (if required)
            if length(dimindex)<obj.Ndim
                removedims=setdiff(1:obj.Ndim, dimindex);
                obj.value_(removedims) = [];
            end
        end
        
        
        function selector = getSelector(obj,selector, positionIndex, allowedSeries, userCall)
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
            %    - allowedSeries: (string enum: 'all','onlyRowSeries','onlyColSeries')
            %                                   accept only these logical dataframe series
            %    - positionIndex  (logical):    selector is position index instead of value index
            %    - userCall       (logical):    perform full validation of selector
            %
            % output:
            %    validated array indexer (colon, logical array or position index array)
            %
            if nargin<5, userCall = false; end
            if nargin<4, allowedSeries = 'all'; end
            if nargin<3, positionIndex = false; end
            
            if iscolon(selector)
                % colon selector
                selector = ':'; % note: this also converts colon in cell to just a colon
                
            elseif positionIndex
                % position index selector (so no selector per dimension allowed)
                assert(~iscell(selector),"No cell selector allowed in combination with position indexing.");                
                selector = getSelector@frames.Index(obj, selector, positionIndex, allowedSeries, userCall);
                
            elseif islogical(selector) || isFrameSeries(selector)
                %  value selector (with logicals)                
                selector = getSelector@frames.Index(obj, selector, positionIndex, allowedSeries, userCall);
                
            else
                %  value selector (with 'selector set(s)')
                assert(iscell(selector),"Need cell selector in case of value indexing in MultiIndex.");
                isnestedcell = cellfun(@iscell, selector);
                if ~any(isnestedcell)
                    % add celllayer (simplifies processing)
                    selector = {selector};
                elseif ~all(isnestedcell)
                    error("Some cells in selector contain a nested cell array and other's do not. " + ...
                        "This is not allowed. Nested cell arrays are interpreted as separate 'selector sets'. " + ...
                        "If used, all cells must contain nested cell arrays.");
                end
                % calculate logical mask as selector
                mask = false(obj.length(),1);
                for iset = 1:length(selector)                    
                    % get mask of maskset by looping over supplied dimensions
                    maskset = true(obj.length(),1);                    
                    selectorset = selector{iset};
                    assert(length(selectorset)<=obj.Ndim, ...
                        "More cells (%i) in selector (set %i) than dimensions in MultiIndex (%i).", ...
                        length(selectorset), iset, obj.Ndim);
                    for j = 1:length(selectorset)
                        masklayer = obj.value_(j).getSelectorMask(selectorset{j},positionIndex, allowedSeries, userCall);
                        maskset = maskset & masklayer;
                    end
                    % combine masks of different masksets
                    mask = mask | maskset;
                end
                selector = mask;
            end
        end
        
        
        
        function [rows_ind1, rows_ind2, common_mask1, common_mask2, rows_uniqval, ...
                val_uniq, val_ind1, val_ind2]= getMatchingRows(obj1, obj2, dims)
            % function finds indices of matching rows between two MultiIndex 
            % for given common dimensions.
            % 
            % input:
            %   obj1,obj2: MultiIndex
            %   dims: string array with common dimension names
            %
            % output:
            %   rows_indX:    array with unique indices per row matching MultiIndex object X
            %   common_maskX: logical array indicating row is common between both MultiIndex objects
            %   rows_uniqval: cell(Nunique, Ndim_common) values of unique rows
            %
            %   val_uniq: cell with uniqe values per dimension
            %   val_indX: array(Nrows, Ndim_common) indices to val_uniq           
            %            
            % get dim index of specified (common) dimension
            dimInd1 = obj1.getDimInd(dims);
            dimInd2 = obj2.getDimInd(dims);
            % get all unique row of given dim combination
            value1 = obj1.value(:,dimInd1);
            value2 = obj2.value(:,dimInd2);
            %valueAll = obj1.concatRowValues(value1, value2);
            valueAll = [value1; value2];
            % get unique row ind for total
            [rows_uniqval, rows_ind, val_uniq, val_ind] = uniqueCellRows(valueAll);
            % separate in both indexes
            N1 = length(obj1);
            rows_ind1 = rows_ind(1:N1);
            rows_ind2 = rows_ind(N1+1:end);
            val_ind1 = val_ind(1:N1,:);
            val_ind2 = val_ind(N1+1:end,:);
            % create common masks
            common_ind = intersect(rows_ind1, rows_ind2);
            common_mask1 = ismember(rows_ind1, common_ind);
            common_mask2 = ismember(rows_ind2, common_ind);
        end
        
        
        function [objnew, ind1_new , ind2_new] = alignIndex(obj1, obj2, alignMethod, allowDimExpansion)
            % function to create new aligned MultiIndex based on common dimensions 
            % of both MultiIndex objects and implicit expansion of missing dimensions
            %
            % input:
            %    - obj1,obj2: MultiIndex objects to be aligned
            %
            %    - alignMethod: (string enum) align method for common dimension(s)
            %           "subset": remove rows that are not common in both
            %           "keep":  keep rows as in obj1  (default)            
            %           "full":   keep all items (allow missing in both obj1 and obj2)
            %
            %   - allowDimExpansion (bool) allow expansion to add new dimensions to obj1
            %
            
            % default parameters
            if nargin<3, alignMethod="keep"; end
            if nargin<4, allowDimExpansion=true; end
            
            % find common dimensions            
            [dim_common, dim_common_ind1, dim_common_ind2, dim_unique_ind1, dim_unique_ind2] = obj1.getMatchingDims(obj2);                       
            NextraDims2 = length(dim_unique_ind2);
            NextraDims1 = length(dim_unique_ind1);
            assert(allowDimExpansion | NextraDims2==0, ...
                          "Dimension expansion disabled, while obj2 has new dimension(s)");
                        
            % get matching rows of both MultiIndex objects
            [id1_raw, id2_raw, mask1, mask2, rows_uniqval]  = obj1.getMatchingRows(obj2, dim_common);            
            Nunique = size(rows_uniqval,1);
             
            % define row ids in new index based on chosen alignment method
            switch alignMethod
                case "subset"
                    id = id1_raw(mask1);                    
                case "keep"
                    id = id1_raw;                    
                case "full"                                         
                    id = [id1_raw; setdiff(id2_raw, id1_raw)];                                                            
                otherwise 
                    error("unsupported alignMethod '%s'",alignMethod);
            end     
           
            % get row numbers of aligned index for obj1
            id_freq2 = histc(id2_raw, 1:Nunique); %#ok<HISTC>   
            replicate_count = max(id_freq2(id),1); % replicate rows in obj1 with freq obj2, keep minimal 1 copy            
            ind1_new = repelem(1:length(id), replicate_count )'; 
            ind1_new(ind1_new>length(id1_raw))=NaN; 
                                                        
            % get row numbers of aligned index for obj2            
            ind2_cell = getPosIndicesForEachValue(id2_raw, Nunique);
            ind2_cell_aligned = ind2_cell(id);
            ind2_new = vertcat(ind2_cell_aligned{:});
                                                  
            % create new expanded MultiIndex (with dimensions as in obj1)                        
            assert( (NextraDims1==0 || ~any(isnan(ind1_new)) ) && ...
                    (NextraDims2==0 || ~any(isnan(ind2_new)) ), ...
                    "Cannot expand dimensions in case rows exist in output index that are not common in both objects.");                    
            if ~any(isnan(ind1_new))
                % only a combination of rows in ob1
                objnew = obj1.getSubIndex(ind1_new);
            else
               % combination of both MultiIndex
               mask_rows_from_obj2 = isnan(ind1_new);
               objnew1 = obj1.getSubIndex(ind1_new(~mask_rows_from_obj2), dim_common_ind1);
               objnew2 = obj2.getSubIndex(ind2_new(mask_rows_from_obj2), dim_common_ind2);
               objnew = [objnew1; objnew2];
            end
                                    
            % add new dimensions
            if NextraDims2>0
                objnew2 = obj2.getSubIndex(ind2_new);
                for i=1:NextraDims2
                    dimind = dim_unique_ind2(i);
                    objnew = objnew.addDimension( objnew2.value_(dimind) );
                end   
            end
            
            
            function ind_cell = getPosIndicesForEachValue(x, N)
                % get cell array(N) with cell(i) the position indices of vector x with value i
                % (values of vector x has to be in range 1 to N)
                [~,ix] = sort(x);
                c = histc(x, 1:N); %#ok<HISTC>
                ind_cell = mat2cell(ix(:),c,1);
                ind_cell( cellfun(@isempty, ind_cell) ) = {NaN}; % convert missing values to NaN
            end
        end
        
        
        
        
        function disp(obj)
            % display MultiIndex values and properties
            dispnames = obj.name;
            dispnames(dispnames=="")="<missing>";
            disptable = table( obj.value_.value, 'VariableNames', cellstr(dispnames));
            disp(disptable);
            details(obj);
        end
        
        function val = getValueForTable(obj)
            % convert value to strings to use with a table
            val = join(string(obj.value)," ");
            val = matlab.lang.makeUniqueStrings(val,{},namelengthmax());
            val = cellstr(val);
        end
        
        
        function obj = setIndex(obj, value, name)
            % assign index and dimension names
            obj.value = value;
            assert(isstring(name) && length(name)==obj.Ndim, "Name should be string array with Ndim values.");
            % assign name strings to Index objects
            for i=1:obj.Ndim
                if name(i)~=""
                    obj.value_(i).name = name(i);
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
            if isa(values,'frames.Index')
                % use existing Index object
                newIndexObj = values;
                if name~="", newIndexObj.name=name; end                
            else
                % convert values to Index object
                assert(obj.Ndim==0 || length(values)==obj.length(), ...
                    "Length value not same as existing index length");
                assert(name~="", "Error no valid name supplied");
                newIndexObj = frames.Index(values, Name=name);                
            end
            % append to multiindex
            obj.value = [obj.value_ newIndexObj];
        end
        
        
        function [common, common_ind1, common_ind2, unique_ind1, unique_ind2] = getMatchingDims(obj1, obj2)
            % find common and unique dimensions between two MultiIndex
            %
            % input: obj1,obj2: MultiIndex objects
            %
            % output:
            %    common:       string array of common dimensions
            %    common_indX:  array with common dimension indices of MultiIndex object X
            %    unique_indX:  array with unique dimension indices of MultiIndex object X
            %
            [common, common_ind1, common_ind2] = intersect(obj1.name, obj2.name);
            [~, unique_ind1, unique_ind2] = setxor(obj1.name, obj2.name);
        end
        
        function dimind = getDimInd(obj, dim)
            % get position index of specified dimension names
            [~, dimind, ~ ] = intersect(obj.name, dim);
            assert(length(dimind)==length(dim), "error not all dimension are present");
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
                    out = {obj.value_.value};
                case "row"
                    % cell array with every row a nested cell with row values
                    out = cell(length(obj),1);
                    for j=1:length(obj)
                        row = cell(1,obj.Ndim);
                        for i=1:obj.Ndim
                            row{i} = obj.value_(i).value(j);
                        end
                        out{j} = row;
                    end
                case "rowcol"
                    % every value in separate cell
                    out  = cell(obj.length() ,obj.Ndim);
                    for i=1:obj.Ndim
                        dimvalues = arrayfun(@(x) {x}, obj.value_(i).value);
                        out(:,i) = dimvalues;
                    end
                otherwise
                    error("unsupported type '%s'.", type);
            end
        end                
        
    end
    methods(Access=protected)
        
        function obj = setvalue(obj, value)
            % SETVALUE: store index values of every dimension as Index objects and validate row uniqueness
            %
            % input value: 
            %    - cells array(1:Ndim) with each cell the linear index data
            %        - frames.Index object or
            %        - array of input types supported by frames.Index            
            
            %    - array(1:Ndim) with frames.index objects 
            %
            % each dimension should have the same number of elements, and combination of values has to be unique
            %
            if isempty(value)
                % in case no value, just add empty Index object
                obj.value_=frames.Index();
                return;
            end
            if all( arrayfun(@(x) isa(x,'frames.Index'), value))
                % handle array of Index objects by first converting to cell array
                % (TODO: find more elegant solution)
                value = num2cell(value);
            end
            assert( iscell(value), "Not a cell array.");
            assert( isvector(value), "error, should be 1d cell vector");
            % convert all (linear) indexes to Index objects
            Ndims = length(value);
            indices = frames.Index();
            for i = 1:Ndims
                val = value{i};
                if length(val)==1 && isa(val, frames.Index)
                    % linear index should not be unique
                    indices(i) = val.requireUnique(false);
                else
                    % convert to linear index
                    indices(i) = frames.Index(val, Unique=false);
                end
                % get default names (TODO: think better about behavior)
                if indices(i).name==""
                    if length(obj.value_) >= i
                        % use name of existing dimension
                        indices(i).name = obj.value_(i).name;
                    else
                        indices(i).name = "dim"+i;
                    end
                end
            end
            % assign new values
            obj.value_ = indices;
            % check dimension names and uniqueness of rows
            obj.valueChecker();
            obj.nameChecker();
        end
        
        
        function out = getname(obj)
            % get array of names for every dimension (from Index objects)
            if obj.Ndim > 0
                out = [obj.value_.name];
            else
                out="";
            end
        end
        
        function v = getValue(obj)
            % output MultiIndex values
            v = obj.getvalue_cell("rowcol"); %as cell(Nindex,Ndim)
            %v = obj.getvalue_cell("col");   % as cell(Ndim) with cell an array
        end
        
        function out = getvalue_uniq(obj)
            % get unique values of every dimension (from Index Objects)
            if obj.Ndim>0
                out = [obj.value.value_uniq];
            else
                out = {};
            end
        end
        
               
        
        function out = getvalue_uniqind(obj)
            % get index positions to unique values of every dimension
            if obj.Ndim>0
                out = [obj.value_.value_uniqind];
            else
                out = [];
            end
        end
        
        
        function nameChecker(obj)
            % check if names of dimensions are valid
            name_unique = unique(obj.name);
            assert(length(obj.name)==length(name_unique), "dimension names not unique");
        end
        
        function valueChecker(obj,fromSubsAsgnIdx,b)
            % validate current multiindex values
            %
            % check if rows are unique
            Nindex = obj.length();
            rows_uniqind = unique(obj.value_uniqind,'rows','stable');
            if size(rows_uniqind,1)~= Nindex
                rows_not_unique = setdiff(1:Nindex, rows_uniqind);
                error("Combination of dimension values should be unique. " + ...
                    "The following multi-index rows are not unique: " + ...
                    num2str(rows_not_unique));
            end
        end
        
        
        function valueOut = getValue_andCheck(obj,value,userCall)
            % TODO
            valueOut = value;
        end
        
    end
    
    
    
    methods
        function Ndim = get.Ndim(obj)
            % get number of dimensions
            Ndim = numel(obj.value_);
        end
        
        function Nindex = length(obj)
            % number of items in index
            if isempty(obj.value_)
                Nindex = 0;
            else
                Nindex = length(obj.value_(1));
            end
        end
               
        
        function obj = vertcat(obj,varargin)
            % concatenate multiple MultiIndex objects with same dimensions
            newvalue=obj.value_;
            % combine indices
            for i=1:length(varargin)
                item = varargin{i};
                assert(isa(item,'frames.MultiIndex'), "error, can only concatenate MultiIndex objects");
                assert(all(obj.name==item.name), "error, dimensions not equal");
                for j=1:obj.Ndim
                    newvalue(j) = newvalue(j).vertcat(item.value_(j));
                end
            end
            % assign to MultiIndex
            obj = obj.setvalue(num2cell(newvalue));
        end
        
    end
    
    
    
end