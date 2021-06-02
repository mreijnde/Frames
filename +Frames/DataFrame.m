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
            obj.indexValidation(value);
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
            if ~isa(value,'frames.Index')
                value = obj.getColumnsObject(value);
            end
            obj.columns_ = value;
        end
        function obj = set.data(obj, value)
            assert(all(size(value)==size(obj.data_)), ...
                'data is not of the correct size')
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
        function c = get.constructor(obj)
            c = str2func(class(obj));
        end
        function idx = getIndex_(obj)
            idx = obj.index_;
        end
        function col = getColumns_(obj)
            col = obj.columns_;
        end
        function obj = setIndexType(obj,type)
            % ToDo in Timeframe do type is format
            obj.index_ = transformIndex(obj.index_,type);
        end
        function obj = setColumnsType(obj,type)
            obj.columns_ = transformIndex(obj.columns_,type);
        end
        function obj = setIndexName(obj,name)
            obj.index_.name = name;
        end
        function obj = setColumnsName(obj,name)
            obj.columns_.name = name;
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
            obj.data_ = obj.data_(idxID,colID);
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
                nameValue.how {mustBeTextScalar,mustBeMember(nameValue.how,["any","all"])} = "all";
                nameValue.axis (1,1) {mustBeMember(nameValue.axis,[1,2])} = 1;
            end
            
            axis = abs(nameValue.axis-3);  % if dim = 1 I want to drop rows, where we check if they contain missings in the 2. dimension
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
            other.columns_.value = newColumns;
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
            if ~isa(obj.index_, 'frames.SortedIndex')
                error('Only use resample with SortedIndex (set obj.setIndexType("sorted"))')
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
                if sameIndex && isequal(idx,idx_)
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
                    if ~isa(obj.index_,'frames.SortedIndex')
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
        
        function other = sortBy(obj,columnName)
            series = obj.loc(':',columnName);
            [~,sortedID] = sort(series.data);
            obj.index_ = frames.UniqueIndex(obj.index_);
            other = obj.iloc(sortedID);
        end
        function obj = sortIndex(obj)
            [obj.index_.value_,sortedID] = sort(obj.index_.value_);
            obj.data_ = obj.data_(sortedID,:);
        end
        
        function obj = shift(obj,varargin)
            obj.data_ = shift(obj.data_,varargin{:});
        end
        
        function obj = clip(obj,floorVal,ceilVal)
            if nargin < 3
                ceilVal = floorVal;
            else
                obj.data_(obj.data_ < floorVal) = floorVal;
            end
            obj.data_(obj.data_ > ceilVal) = ceilVal;
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
        
        function varargout = heatmap(obj,varargin)
            figure()
            p = heatmap(obj.columns,obj.index,obj.data,varargin{:});
            title(obj.name);
            if nargout == 1, varargout{1} = p; end
        end
        
        function s = split(obj,varargin)
            s = frames.internal.Split(obj,varargin{:});
        end
        
        
        function obj = relChg(obj,varargin)
            obj.data_ = relativeChange(obj.data_,varargin{:});
        end
        function obj = compoundChange(obj,varargin)
            obj.data_ = compoundChange(obj.data_,varargin{:});
        end
        function obj = replaceStartBy(obj,varargin)
            obj.data_ = replaceStartBy(obj.data_,varargin{:});
        end
        function obj = emptyStart(obj,window)
            obj.data_ = replaceStartBy(obj.data_,window);
        end
        function idx = firstCommonIndex(obj)
            % returns the first index where data are "all" not missing
            ix = find(all(~ismissing(obj.data_),2),1);
            idx = obj.index(ix);
        end
        function idx = firstValidIndex(obj)
            % returns the first index where data are not "all missing"
            ix = find(any(~ismissing(obj.data_),2),1);
            idx = obj.index(ix);
        end
        
        function varargout = size(obj,varargin)
            [varargout{1:nargout}] = size(obj.data_,varargin{:});
        end
        function bool = isempty(obj), bool = isempty(obj.data_); end
        function obj = cumsum(obj), obj.data_ = cumsum(obj.data_); end
        function obj = cumprod(obj), obj.data_ = cumprod(obj.data_); end
        
        function other = plus(df1,df2)
            other = operator(@plus,@elementWiseHandler,df1,df2);
        end
        function other = mtimes(df1,df2)
            other = operator(@mtimes,@matrixOpHandler,df1,df2);
        end
        function other = times(df1,df2)
            other = operator(@times,@elementWiseHandler,df1,df2);
        end
        function other = minus(df1,df2)
            other = operator(@minus,@elementWiseHandler,df1,df2);
        end
        function other = mrdivide(df1,df2)
            other = operator(@mrdivide,@matrixOpHandler,df1,df2);
        end
        function other = rdivide(df1,df2)
            other = operator(@rdivide,@elementWiseHandler,df1,df2);
        end
        function other = mldivide(df1,df2)
            other = operator(@mldivide,@matrixOpHandler,df1,df2);
        end
        function this = ldivide(df1,df2)
            this = operator(@ldivide,@elementWiseHandler,df1,df2);
        end
        function this = power(df1,df2)
            this = operator(@power,@elementWiseHandler,df1,df2);
        end
        function this = mpower(df1,df2)
            this = operator(@mpower,@matrixOpHandler,df1,df2);
        end
        
        function this = lt(df1,df2)
            this = operator(@lt,@elementWiseHandler,df1,df2);
        end
        function this = gt(df1,df2)
            this = operator(@gt,@elementWiseHandler,df1,df2);
        end
        function this = le(df1,df2)
            this = operator(@le,@elementWiseHandler,df1,df2);
        end
        function this = ge(df1,df2)
            this = operator(@ge,@elementWiseHandler,df1,df2);
        end
        function bool = equals(df1,df2,tol)
            if nargin<3, tol=eps; end
            try
                diff = df1-df2;
                iseq = diff.abs().data <= tol;
                bool = all(iseq(:));
            catch
                bool = false;
            end  
        end
        function bool = eq(df1,df2)
            bool = df1.equals(df2,0);
        end
        function bool = ne(df1,df2)
            bool = ~df1.eq(df2);
        end
        
        function obj = ctranspose(obj)
            obj = frames.DataFrame(obj.data_',obj.columns,obj.index,obj.name_);
        end
        function obj = transpose(obj)
            obj = frames.DataFrame(obj.data_.',obj.columns,obj.index,obj.name_);
        end
        
        % these function overloads are to make chaining possible
        % e.g. df.abs().sqrt()
        function obj = uminus(obj), obj.data_ = uminus(obj.data_); end
        function obj = uplus(obj), obj.data_ = uplus(obj.data_); end
        function obj = abs(obj), obj.data_ = abs(obj.data_); end
        function obj = exp(obj), obj.data_ = exp(obj.data_); end
        function obj = log(obj), obj.data_ = log(obj.data_); end
        function obj = tanh(obj), obj.data_ = tanh(obj.data_); end
        function obj = floor(obj), obj.data_ = floor(obj.data_); end
        function obj = ceil(obj), obj.data_ = ceil(obj.data_); end
        function obj = sign(obj), obj.data_ = sign(obj.data_); end
        function obj = sqrt(obj), obj.data_ = sqrt(obj.data_); end

        %  subsref subsasgn.
        %  Index for cols and index.
        %  operations: plus, minus.
        %  returns, replace.
        %  add drop columns, index, missing.
        %  missingData value, size.
        %  [] cat.
        %  resample, shift, oneify, bool.
        %  plot, heatmap.
        % ToDo cov corr rolling ewm
        %  ffill bfill.
        %  start and end valid, fill.
        % ToDo max min std sum
        %  sortby.
        %  split apply.
        %  read write.
        %  setIndexType, setIndexName, setColumnsType, Name.
        
        
        
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
                    if ismember(s(1).subs,properties(obj))
                        obj.(s.subs) = b;
                    else
                        error(('''%s'' is not a public property of the ''%s'' class.'),s(1).subs,class(obj));
                    end
            end
        end
        
        
        function toFile(obj,filePath,varargin)
            writetable(obj.t,filePath, ...
                'WriteRowNames',true,'WriteVariableNames',true,varargin{:});
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
        function indexValidation(obj,value)
            assert(length(value) == size(obj.data,1), ...
                'index does not have the same size as data')
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
    
    
    methods(Static)
        function df = fromFile(filePath, varargin)
            tb = readtable(filePath,...
                'TreatAsEmpty',{'N/A','NA'}, ...
                'ReadRowNames',true,'ReadVariableNames',true, ...
                varargin{:});
            df = frames.DataFrame.fromTable(tb);
        end
        function df = fromTable(t,nameValue)
            arguments
                t {mustBeA(t,'table')}
                nameValue.keepCellstr (1,1) logical = false
            end
            cols = t.Properties.VariableNames;
            if ~nameValue.keepCellstr, cols = string(cols); end
            df = frames.DataFrame(t.Variables,t.Properties.RowNames,cols);
            df.index_.name = t.Properties.DimensionNames{1};
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

function varargout = getData_(varargin)
for ii = 1:nargout
    v = varargin{ii};
    if isa(v,'frames.DataFrame'), v=v.data_; end
    varargout{ii} = v; %#ok<AGROW>
end
end


%--------------------------------------------------------------------------
function [idx_,col_,df] = matrixOpHandler(df1,df2)
df = df1;
if isa(df2,'frames.DataFrame')
    if isa(df1,'frames.DataFrame')
        assert(isequal(df1.columns_.value_,df2.index_.value_), ...
                'Frames are not aligned!')
        idx_ = df1.index_;
        col_ = df2.columns_;
    else
        idx_ = frames.UniqueIndex(1:size(df1,1));
        col_ = df2.columns_;
        df = df2;
    end
else
    idx_ = df1.index_;
    col_ = frames.Index(1:size(df2,2));
end
end

%--------------------------------------------------------------------------
function [idx_,col_,df] = elementWiseHandler(df1,df2)
df = df1;
if isa(df2,'frames.DataFrame')
    if isa(df1,'frames.DataFrame')
        if size(df1,1)>1 && size(df2,1)>1
            assert(isequal(df1.index_.value_,df2.index_.value_), ...
                'Frames have different indices!')
        end
        if size(df1,2)>1 && size(df2,2)>1
            assert(isequal(df1.columns_.value_,df2.columns_.value_), ...
                'Frames have different columns!')
        end
        idx_ = df1.index_;
        if size(df2,1)>size(df1,1), idx_ = df2.index_; end
        col_ = df1.columns_;
        if size(df2,1)>size(df1,1), col_ = df2.columns_; end
    else
        idx_ = df2.index_;
        col_ = df2.columns_;
        df = df2;
    end
else
    idx_ = df1.index_;
    col_ = df1.columns_;
end
end

%--------------------------------------------------------------------------
function other = operator(fun,handler,df1,df2)
[idx_,col_,other] = handler(df1,df2);
[v1,v2]=getData_(df1,df2);
d = fun(v1,v2);
other.data_ = d; other.index_ = idx_; other.columns_ = col_;
other.description = "";
end
