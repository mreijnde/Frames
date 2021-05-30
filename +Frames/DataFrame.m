classdef DataFrame
    %DATAFRAME Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Dependent)
        % Provide the interface. Includes tests in the getters and setters.
        
        data
        index
        columns
        name
        t
    end
    properties
        description {mustBeText} = ""
    end
    properties(Hidden, Access=protected)
        % Encapsulation. Internal use, there are no tests in the getters
        % and setters.
        
        data_
        index_
        columns_
        name_
    end
    properties(Hidden, Dependent)
        constructor
    end
    
    methods
        function obj = DataFrame(data,index,columns,name)
            %DATAFRAME Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                data (:,:) = []
                index {mustBeDFindex} = []
                columns {mustBeDFcolumns} = []
                name {mustBeTextScalar} = ""
            end
            if isempty(index)
                index = obj.defaultIndex(size(data,1));
            end
            if isempty(columns)
                columns = obj.defaultColumns(size(data,2));
            end
            if isempty(data)
                data = obj.defaultData(length(index),length(columns),class(data));
            end
            if iscolumn(data)
                data = repmat(data,1,length(columns));
            end
            if isrow(data)
                data = repmat(data,length(index),1);
            end
                
            obj.data_ = data;
            obj.index = index;
            obj.columns = columns;
            obj.name_ = name;
            
        end
        
        %------------------------------------------------------------------
        % Setters and Getters
        
        function obj = set.index(obj, value)
            arguments
                obj, value {mustBeDFindex}
            end
            assert(length(value) == size(obj.data,1), ...
                'index does not have the same size as data')
            if ~isa(value,'frames.Index')
                value = obj.getIndexObject(value);
            end
            obj.index_ = value;
        end
        function obj = set.columns(obj, value)
            arguments
                obj, value {mustBeDFcolumns}
            end
            assert(length(value) == size(obj.data,2), ...
                'columns do not have the same size as data')
            value = obj.getColumnsObject(value);
            obj.columns_ = value;
        end
        function obj = set.data(obj, value)
            assert(all(size(value)==size(obj.data_)), ...
                'data is not of the correct size' )
            obj.data_ = value;
        end
        function obj = set.name(obj, value)
            arguments
                obj, value {mustBeTextScalar}
            end
            obj.name_ = value;
        end
        
        function index = get.index(obj)
            index = obj.index_.value;
        end
        function columns = get.columns(obj)
            columns = obj.columns_.value';
        end
        function data = get.data(obj)
            data = obj.data_;
        end
        function name = get.name(obj)
            name = obj.name_;
        end
        function t = get.t(obj)
            t = obj.getTable();
        end
        function idx = getIndex_(obj)
            idx = obj.index_;
        end
        function col = getColumns_(obj)
            col = obj.columns_;
        end
        
        function t = head(obj, varargin); t = head(obj.t,varargin{:}); end
        function t = tail(obj, varargin); t = tail(obj.t,varargin{:}); end
        
        function obj = iloc(obj,idxPosition,colPosition)
            arguments
                obj
                idxPosition {mustBeDFindex}
                colPosition {mustBeDFcolumns} = ':'
            end
            obj.data_ = obj.data_(idxPosition,colPosition);
            obj.index_.value_ = obj.index_.value_(idxPosition);
            obj.columns_.value_ = obj.columns_.value_(colPosition);
        end
        function obj = loc(obj,idxName,colName)
            arguments
                obj
                idxName {mustBeDFindex}
                colName {mustBeDFcolumns} = ':'
            end
            if ~iscolon(idxName)
                idxID = obj.index_.positionOf(idxName);
                obj.index_.value_ = obj.index_.value_(idxID);
            else
                idxID = idxName;
            end
            if ~iscolon(colName)
                colID = obj.columns_.positionOf(colName);
                obj.columns_.value_ = obj.columns_.value_(colID);
            else
                colID = colName;
            end
            obj.data_ =  obj.data_(idxID,colID);
        end
        
        function obj = replace(obj,valToReplace,valNew)
            if ismissing(valToReplace)
                idx = ismissing(obj.data_);
            else
                idx = obj.data_==valToReplace;
            end
            obj.data_(idx) = valNew;
        end
        
        function df = dropMissing(obj,nameValue)
            arguments
                obj
                nameValue.how {mustBeMember(nameValue.how,["any","all"])} = "all";
                nameValue.axis {mustBeMember(nameValue.axis,[1,2])} = 1;
            end
            
            axis = abs(nameValue.axis-3);  % if dim = 1 I want to drop rows, where we check if they contain NaNs in the 2. dimension
            if strcmp(nameValue.how,'all')
                drop = all(ismissing(obj.data_),axis);
            else
                drop = any(ismissing(obj.data_),axis);
            end
            if nameValue.axis==1
                df = obj.iloc(~drop,':');
            else
                df = obj.iloc(':',~drop);
            end
        end
        function obj = ffill(obj)
            obj.data_ = fillmissing(obj.data_,'previous');
        end
        function obj = bfill(obj)
            obj.data_ = fillmissing(obj.data_,'next');
        end
        
        function other = extendIndex(obj,index)            
            newIndex = obj.index_.union(index);
            newData = obj.defaultData(length(newIndex),length(obj.columns_));
            
            idx = obj.index_.positionIn(newIndex.value);
            newData(idx,:) = obj.data_;
            
            other = obj;
            other.data_ = newData;
            other.index_ = newIndex; 
        end
        function other = dropIndex(obj,index)
            idxToRemove = obj.index_.positionOf(index);
            idxToKeep = setdiff(1:length(obj.index_),idxToRemove);
            other = obj.iloc(idxToKeep);
        end
        function other = extendColumns(obj,columns)
            if isrow(columns), columns=columns'; end
            newCols = setdiff(columns,obj.columns_.value);
            newColumns = [obj.columns_.value;newCols];
            newData = obj.defaultData(length(obj.index_),length(newColumns));
            newData(:,1:length(obj.columns_)) = obj.data_;
            
            other = obj;
            other.data_ = newData;
            other.columns_.value_ = other.columns_.getValue_(newColumns);
        end
        function other = dropColumns(obj,columns)
            colToRemove = obj.columns_.positionOf(columns);
            colToKeep = setdiff(1:length(obj.columns_),colToRemove);
            other = obj.iloc(':',colToKeep);
        end
        function other = resample(obj,index,nameValue)
            arguments
                obj, index
                nameValue.firstValueFilling = "noFfill"
            end
            if ~isa(obj.index_, 'frames.OrderedIndex')
                error('Only use resample with sorted index')
            end
            firstValueFilling = nameValue.firstValueFilling;
            if ~iscell(firstValueFilling)
                firstValueFilling = {firstValueFilling};
            end
            acceptedValues = ["noFfill","ffillLastAvailable","ffillFromInterval"];
            assert(ismember(firstValueFilling{1}, acceptedValues), ...
                sprintf("'firstValueFilling' must take a value in [%s]",acceptedValues))
            
            if strcmp(firstValueFilling{1},"ffillFromInterval")
                try
                    if length(firstValueFilling) == 2
                        interval = firstValueFilling{2};
                    else
                        interval = index(2)-index(1);
                    end
                    if isrow(index), index=index'; end
                    index = [index(1)-interval;index];
                catch me 
                    error('The interval is not valid. It must be substractable from the index.')
                end
            end
            other = obj.extendIndex(index);
            posSelector = other.index_.positionOf(index);
            noFfill = strcmp(firstValueFilling{1},"noFfill") && ~isempty(posSelector);
            if noFfill
                dataStart=other.data_(posSelector(1),:);
            end
            hasEntry = intervalHasEntry(other.data,posSelector);
            other = other.ffill().loc(index);
            other.data_(~hasEntry)=missingData(class(other.data_));
            
            if noFfill, other.data_(1,:) = dataStart; end
            if strcmp(firstValueFilling{1}, "ffillFromInterval")
                other = other.iloc(2:length(obj.index_));
            end
        end
        function other = horzcat(obj,varargin)
            
            % compute a merged index, only in case they are not the same
            idx = obj.index_;
            sameIndex = true;
            lenCols = zeros(length(varargin)+1,1);
            lenCols(1) = length(obj.columns_);
            for ii = 1:nargin-1
                lenCols(ii+1) = length(varargin{ii}.columns_);
                idx_ = varargin{ii}.index_;
                if sameIndex && isequal( idx, idx_ )
                    continue
                else
                    sameIndex = false;
                end
                idx = idx.union(idx_);
            end
            
            % expand each DF with the new idx, and merge their data_
            sizeColumns = cumsum(lenCols);
            dataH = obj.defaultData(length(idx),sizeColumns(end));
            
            function df = getExtendedIndexDF(df)
                % Expand DF, keeping the order of idx
                if ~sameIndex
                    df = df.extendIndex(idx);
                    if ~isa(obj.index_,'frames.OrderedIndex')
                        df = df.loc(idx.value);
                    end
                end
            end
            other = getExtendedIndexDF(obj);
            dataH(:,1:lenCols(1)) = other.data_;
            columnsNew = obj.columns_;
            type = class(obj.data_);
            for ii = 1:nargin-1
                extendedDF = getExtendedIndexDF(varargin{ii});
                assert(isa(extendedDF.data_,type), ...
                    'frames do not have the same data type')
                dataH(:,sizeColumns(ii)+1:sizeColumns(ii+1)) = extendedDF.data_;
                columnsNew = [columnsNew;varargin{ii}.columns_]; %#ok<AGROW>
            end
            other.data_ = dataH;
            other.columns_ = columnsNew;
            other.name_ = ""; other.description = "";
        end
        function other = vertcat(obj,varargin)
            
            % DF must each have unique columns
            % compute a merged columns, only in case they are not the same
            col = obj.columns_.value_;
            sameCols = true;
            lenIdx = zeros(length(varargin),1);
            lenIdx(1) = length(obj.index_);
            for ii = 1:nargin-1
                lenIdx(ii+1) = length(varargin{ii}.index_);
                col_ = varargin{ii}.columns_.value_;
                if sameCols && isequal(col,col_)
                    continue
                else
                    sameCols = false;
                end
                col = union(col,col_,'stable');  % requires unique columns
            end
            
            sizeIndex = cumsum(lenIdx);
            dataV = obj.defaultData(sizeIndex(end),length(col));
            
            function df = getExtendedColsDF(df)
                % Expand DF, keeping the order of col
                if ~sameCols
                    df = df.extendColumns(col).loc(':',col);
                end
            end
            
            other = getExtendedColsDF(obj);
            dataV(1:lenIdx(1),:) = other.data_;
            type = class(obj.data_);
            for ii = 1:nargin-1
                extendedDF = getExtendedColsDF(varargin{ii});
                assert(isa(extendedDF.data_,type), ...
                    'frames do not have the same data type')
                idxConc = [other.index_;extendedDF.index_];

                dataV(sizeIndex(ii)+1:sizeIndex(ii+1),:) = extendedDF.data_;
            end
            other.data_ = dataV;
            other.index_ = idxConc;
            other.name_ = ""; other.description = "";
        end
        
        function obj=shift(obj,varargin)
            obj.data_=shift(obj.data_,varargin{:});
        end
        
        function varargout = plot(obj,params)
            arguments
                obj
                params.Title {mustBeTextScalar} = obj.name
                params.Legend (1,1) logical = true
                params.Log (1,1) logical = false
                params.WholeIndex (1,1) logical = false
            end
            
            if issorted(obj.index_)
                obj.data_ = interpMissing(obj.data_);
            end
            
            useIndex = obj.index_.issorted() && ...
                (isnumeric(obj.index) || isdatetime(ob.index));  % any type that can be shown on the x axis
            figure()
            if useIndex
                args = {obj.index,obj.data};
            else
                args = {obj.data};
            end
            if params.Log
                p = semilogy(args{:});
            else
                p = plot(args{:});
            end
            if ~useIndex, xtick([]); end
            grid on
            title(params.Title)
            if params.Legend
                cols = string(obj.columns);
                legend(cols,Location='Best');
            end
            if params.WholeIndex
                xlim(obj.index(1),obj.index(end))
            end
            if nargout == 1, varargout{1} = p; end
        end
        
        
        %  subsref subsasgn.
        %  Index for cols and index.
        % ToDo operations: plus, minus, returns, replace
        %  add drop columns, index, missing.
        %  missingData value, size.
        %  [] cat
        %  resample, shift, oneify, bool
        % ToDo plot, heatmap
        % ToDo cov corr rolling ewm
        %  ffill bfill.
        % ToDo start and end valid, fill
        % ToDo constructors zeros
        % ToDo max min std sum
        % ToDO sortby
        % ToDo split apply
        % toDo read write
        % ToDo setIndexType, setIndexName, setColumnsType, Name
        
        
        
        function varargout = subsref(obj,s)
            if length(s)>1  % when there are several subsref
                if strcmp(s(1).type,'.')
                    [varargout{1:nargout}] = builtin('subsref',obj,s);
                else  % to handle the () and {} cases (Matlab struggles otherwise).
                    other = subsref(obj,s(1));
                    [varargout{1:nargout}] = subsref(other,s(2:end));
                end
                return
            end
            
            nargoutchk(0,1)
            switch s.type
                case '()'
                    [idx,col] = getSelectorsFromSubs(s.subs);
                    varargout{1} = obj.loc(idx,col);
                case '{}'
                    [idx,col] = getSelectorsFromSubs(s.subs);
                    varargout{1} = obj.iloc(idx,col);
                case '.'
                    varargout{1} = obj.(s.subs);
            end
        end
        
        function obj = subsasgn(obj,s,b)
            if length(s)==2
                [islocFct,selectors] = s.subs;
                if strcmp(islocFct,'iloc') || strcmp(islocFct,'loc') 
                    if strcmp(islocFct,'iloc') 
                        fromPosition = true;
                    else
                        fromPosition = false;
                    end
                    obj = modify(obj,b,selectors{1},selectors{2},fromPosition);
                    return
                end
            end
            if length(s)>1
                error('cannot assign with multiple references')
            end
            switch s.type
                case '()'
                    [idx,col] = getSelectorsFromSubs(s.subs);
                    obj = modify(obj,b,idx,col);
                case '{}'
                    [idx,col] = getSelectorsFromSubs(s.subs);
                    obj = modify(obj,b,idx,col,true);
                case '.'
                    if strcmp(s(1).subs,properties(obj))
                        obj.(s.subs) = b;
                    else
                         error(('''%s'' is not a public property of the ''%s'' class.'),s(1).subs,class(obj));
                    end
            end
        end
        
    end
    
    methods(Access=protected)
        function tb = getTable(obj)
            idx = indexForTable(obj.index);
            col = columnsForTable(obj.columns);
            tb = cell2table(num2cell(obj.data),RowNames=idx,VariableNames=col);
        end
        function d = defaultData(obj,lengthIndex,lengthColumns,type)
            if nargin<4; type = class(obj.data); end
            d = repmat(missingData(type),lengthIndex,lengthColumns);
        end
        function idx = getIndexObject(~,index)
            idx = frames.UniqueIndex(index);
        end
        function col = getColumnsObject(~,columns)
            col = frames.Index(columns);
        end
        function obj = modify(obj,data,index,columns,fromPosition)
            if nargin<5; fromPosition = false; end
            if ~fromPosition
                [index,columns] = localizeSelectors(obj,index,columns);
            end
            obj.data_(index,columns) = data;
        end
        function [index,columns] = localizeSelectors(obj,index,columns)      
            if ~iscolon(index)
                index = obj.index_.positionOf(index);
            end
            if ~iscolon(columns)
                columns = obj.columns_.positionOf(columns);
            end
        end
    end
    
    methods(Hidden)
        function disp(obj)
            maxRows = 100;
            maxCols = 50;  % Matlab is struggles to show many columns
            if all(size(obj) < [maxRows,maxCols])
                disp(obj.t);
            else
                details(this);
            end
        end
        
        function n = numArgumentsFromSubscript(varargin), n = 1; end
        function e = end(obj,q,w), e = builtin('end',obj.data_,q,w); end
        
    end
    
    methods(Hidden, Static, Access=protected)
        function idx = defaultIndex(len)
            idx = (1:len)';
        end
        function col = defaultColumns(len)
            col = "Var" + (1:len);
        end
        
    end
end

%--------------------------------------------------------------------------
function [idx, col] = getSelectorsFromSubs(subs)
len = length(subs);
if ~ismember(len, [1,2]); error('Error in reference for index and columns.'); end
if len==1; col = ':'; else; col = subs{2}; end
idx = subs{1};
end

%--------------------------------------------------------------------------
function hasEntry = intervalHasEntry(data,selector)
hasEntry = true(length(selector),size(data,2));

isValid = ~ismissing(data);
for ii = 2:length(selector)
    hasEntry(ii,:) = any(isValid(selector(ii-1)+1:selector(ii),:),1);
end
end



