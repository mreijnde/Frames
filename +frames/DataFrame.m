classdef DataFrame
%DATAFRAME handles common operations on homogeneous data matrices referenced by column and index identifiers.
%   It is a convenient way to perform operations on labeled matrices (more intuitive than Matlab's table).
%
%   Constructor:
%   df = frames.DataFrame([data,index,columns,name])
%   If an argument is not specified, it will take a default value, so it
%   is possible to only define some of the arguments:
%   df = frames.DataFrame(data)  
%   df = frames.DataFrame(data,[],columns)
%
%   DATAFRAME properties:
%     data                   - Data      TxN  (homogeneous data)
%     index                  - Index     Tx1
%     columns                - Columns   1xN
%     t                      - Table built on the properties above.
%     name                   - Name of the frame
%     description            - Description of the frame
%
%
%   Short overwiew of methods available:
%
%   - Selection and modification based on index/column names with () or the loc method:
%     df(indexNames,columnsNames)
%     df.loc(indexNames,columnsNames)
%     df(indexNames,columnsNames) = newData
%     df.loc(indexNames,columnsNames) = newData
%
%   - Selection and modification based on position with {} or the iloc method:
%     df{indexPosition,columnsPosition}
%     df.iloc(indexPosition,columnsPosition)
%     df{indexPosition,columnsPosition} = newData
%     df.iloc(indexPosition,columnsPosition) = newData
%
%   - Operations between frames while checking that the two frames
%     are aligned (to be sure to compare apples to apples):
%     df1 + df2
%     1 + df
%     df1' * df2, etc.
%
%   - Chaining of methods:
%     df.relChange().std(),  computes the standard deviation of the
%     relative change of df
%     df{5:end,:}.log().diff(),  computes the difference of the log of df
%     from lines 5 to end
%
%   - Visualisation methods:
%     df.plot(), df.heatmap()
%
%   - Setting properties is checked to insure the coherence of the frame.
%     df.index = newIndex,  will give an error if length(newIndex) ~= size(df.data,1)
%
%   - Concatenation of frames:
%     newDF = [df1,df2] concatenates two frames horizontally, and will
%     expand (unify) their index if they are not equal, inserting missing
%     values in the expansion
%
%   - Split a frame into groups based on its columns, and apply a function:
%     df.split(groups).apply(@(x) x.sum(2))  sums the data on the dimension
%     2, group by group, so the result is a Txlength(group) frame
%
%   - Rolling window methods:
%     df.rolling(30).mean() computes the rolling mean with a 30 step
%     lookback period
%     df.ewm(Halflife=30).std() computes the exponentially weighted moving
%     standard deviation with a halflife of 30
%
%
% For more details, see the list of available methods below.
%
% Copyright 2021 Benjamin Gaudin
%
% See also: frames.TimeFrame
    
    properties(Dependent)
        % Provide the interface. Include tests in the getters and setters.
        
        data  % TxN matrix of homogeneous data
        index  % Tx1 vector
        columns  % 1xN vector
        name  % textscalar, name of the frame 
        t  % table, dependent and built on data, index, columns
    end
    properties
        description {mustBeText} = ""  % text description of the object
    end
    properties(Hidden, Access=protected)
        % Encapsulation. Internal use, there are no tests in the getters
        % and setters.
        
        data_  % TxN matrix of homogeneous data
        index_  % Tx1 frames.UniqueIndex or its child classes
        columns_  % Nx1 frames.Index or its child classes
        name_  % textscalar, name of the frame
    end
    properties(Hidden, Dependent)
        constructor  % constructor of the class (here a @frames.DataFrame)
    end
    
    methods
        function obj = DataFrame(data,index,columns,name)
            %DATAFRAME frames.DataFrame([data,index,columns,name])
            arguments
                data (:,:) = []
                index {mustBeDFindex} = []
                columns {mustBeDFcolumns} = []
                name {mustBeTextScalar} = ""
            end
            if isequal(index,[])
                index = obj.defaultIndex(size(data,1));
            end
            if isequal(columns,[])
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
                if ~isequal(obj.index_,[])  % ToDo: this is always true unless it is called from a constructor
                    obj.index_.value = value;
                    return
                else
                    value = obj.getIndexObject(value);
                end
            end
            obj.index_ = value;
        end
        function obj = set.columns(obj, value)
            arguments
                obj, value {mustBeDFcolumns}
            end
            obj.columnsValidation(value);
            if ~isa(value,'frames.Index')
                if ~isequal(obj.columns_,[])
                    obj.columns_.value = value;
                    return
                else
                    value = obj.getColumnsObject(value);
                end
            end
            obj.columns_ = value;
        end
        function obj = set.data(obj, value)
            assert(all(size(value)==size(obj.data_)), 'frames:dataValidation:wrongSize', ...
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
            % get the Index object underlying index
            idx = obj.index_;
        end
        function col = getColumns_(obj)
            % get the Index object underlying columns
            col = obj.columns_;
        end
        function obj = setIndexType(obj,type)
            % type can be "unsorted", "sorted", or "time"
            if strcmp(type,"duplicate")
                error('frames:setIndexType:duplicate','index cannot have duplicate values')
            end
            obj.index_ = transformIndex(obj.index_,type);
        end
        function obj = setColumnsType(obj,type)
            % type can be "unsorted", "sorted", "time", or "duplicate"
            obj.columns_ = transformIndex(obj.columns_,type);
        end
        function obj = setIndexName(obj,name)
            % the index name will appear as the the first of the
            % DimensionNames in the table .t
            obj.index_.name = name;
        end
        function obj = setColumnsName(obj,name)
            obj.columns_.name = name;
        end
        function obj = setIndex(obj,colName)
            % set the index value from the value of a column
            obj.index = obj.data(:,findPositionIn(colName,obj.columns));
            obj = obj.dropColumns(colName);
        end
        
        function t = head(obj, varargin); t = head(obj.t,varargin{:}); end
        % returns the first rows of the table
        function t = tail(obj, varargin); t = tail(obj.t,varargin{:}); end
        % returns the last rows of the table
        
        %------------------------------------------------------------------
        % Selection
        function obj = iloc(obj,idxPosition,colPosition)
            % selection based on position: df.iloc(indexPosition[,columnsPosition])
            % df.iloc([5 9], [1 4]) returns the 5th and 9th rows of the 1st and 4th columns
            % df.iloc(:,4) returns the 4th column
            % df.iloc(2,:) or df.iloc(2) returns the 2nd row
            arguments
                obj
                idxPosition {mustBeDFindexSelector}
                colPosition {mustBeDFcolumns} = ':'
            end
            obj.data_ = obj.data_(idxPosition,colPosition);
            obj.index_.value_ = obj.index_.value_(idxPosition);
            obj.columns_.value_ = obj.columns_.value_(colPosition);
        end
        function obj = loc(obj,idxName,colName)
            % selection based on names: df.loc(indexNames[,columnsNames])
            % df.loc([2 4], ["a" "b"]) returns the rows named 2 and 4 of the columns named "a" and "b"
            % df.loc(:,"a") returns the column named "a"
            % df.loc(2,:) or df.loc(2) returns the row named 2
            arguments
                obj
                idxName {mustBeDFindexSelector}
                colName {mustBeDFcolumns} = ':'
            end
            idxID = ':'; colID = ':';
            if ~iscolon(idxName)
                idxID = obj.index_.positionOf(idxName);
                obj.index_.value_ = obj.index_.value_(idxID);
            end
            if ~iscolon(colName)
                colID = obj.columns_.positionOf(colName);
                obj.columns_.value_ = obj.columns_.value_(colID);
            end
            obj.data_ = obj.data_(idxID,colID);
        end
        

        function obj = replace(obj,valToReplace,valNew)
            % REPLACE replace the a value in the data with another one
            if ismissing(valToReplace)
                idx = ismissing(obj.data_);
            else
                idx = obj.data_==valToReplace;
            end
            obj.data_(idx) = valNew;
        end
        
        function df = dropMissing(obj,nameValue)
            % remove index or columns with missing data
            % ----------------
            % Parameters:
            % * How   : ["all", "any"], default "all"
            %           drop the line if "all" or "any" elements are missing
            % * Axis  : [1 2], default 1
            %           the dimension on which we drop (dimension 1 are rows)
            arguments
                obj
                nameValue.How {mustBeTextScalar,mustBeMember(nameValue.How,["any","all"])} = "all";
                nameValue.Axis (1,1) {mustBeMember(nameValue.Axis,[1,2])} = 1;
            end
            
            axis = abs(nameValue.Axis-3);  % if axis=1, we want to drop rows, where we check if they contain missings in the 2. dimension
            if strcmp(nameValue.How,'all')
                drop = all(ismissing(obj.data_),axis);
            else
                drop = any(ismissing(obj.data_),axis);
            end
            if nameValue.Axis==1
                df = obj.iloc(~drop,':');
            else
                df = obj.iloc(':',~drop);
            end
        end
        function obj = ffill(obj)
            % forward fill
            obj.data_ = fillmissing(obj.data_,'previous');
        end
        function obj = bfill(obj)
            % backward fill
            obj.data_ = fillmissing(obj.data_,'next');
        end
        
        function other = extendIndex(obj,index)
            % extend the index with the new values
            newIndex = obj.index_.union(index);
            newData = obj.defaultData(length(newIndex),length(obj.columns_));
            
            idx = obj.index_.positionIn(newIndex.value);
            newData(idx,:) = obj.data_;
            
            other = obj;
            other.data_ = newData;
            other.index_ = newIndex;
        end
        function other = dropIndex(obj,index)
            % drop the specified index values
            idxToRemove = obj.index_.positionOf(index);
            idxToKeep = setdiff(1:length(obj.index_),idxToRemove);
            other = obj.iloc(idxToKeep);
        end
        function other = extendColumns(obj,columns)
            % extend the columns with the new values
            valuesToAdd = columns(~ismember(columns,obj.columns));
            newColumns = obj.columns_.union(valuesToAdd);
            newData = obj.defaultData(length(obj.index_),length(newColumns));
            
            col = obj.columns_.positionIn(newColumns.value);
            if ~islogical(col), col = unique(col); end
            newData(:,col) = obj.data_;
            
            other = obj;
            other.data_ = newData;
            other.columns_ = newColumns;
        end
        function other = dropColumns(obj,columns)
            % drop the specified column values
            colToRemove = obj.columns_.positionOf(columns);
            colToKeep = setdiff(1:length(obj.columns_),colToRemove);
            other = obj.iloc(':',colToKeep);
        end
        function other = resample(obj,index,nameValue)
            % RESAMPLE resample the frame with the new index and propagates the data if there are missing values.
            % It propagates the last valid data between two consecutive
            % index values. If all data are missing, it propagates the
            % missing value. Only works with a sorted index.
            % ----------------
            % Parameters:
            % * index               : target index
            % * FirstValueFilling   : ["noFfill","ffillLastAvailable","ffillFromInterval"], default "noFfill"
            %           specifies how the data for the first index value is propagated.
            %           - "noFill" takes the value of the original frame
            %           - "ffillLastAvailable" takes the last available value
            %           - "ffillFromInterval" takes the last available value in a specified interval
            %             By default, the interval is index(2)-index(1) but
            %             can be specified with FirstValueFilling={"ffillFromInterval",specificInterval}
            %
            % Example (see also UnitTests):
            % sortedframe = frames.DataFrame([4 1 NaN 3; 2 NaN 4 NaN]',[1 4 10 20]).setIndexType("sorted");
            % ffi = sortedframe.resample([2 5],FirstValueFilling='ffillFromInterval');
            arguments
                obj, index
                nameValue.FirstValueFilling = "noFfill"
            end
            if ~isa(obj.index_, 'frames.SortedIndex')
                error('Only use resample with SortedIndex (set obj.setIndexType("sorted"))')
            end
            FirstValueFilling = nameValue.FirstValueFilling;
            if ~iscell(FirstValueFilling)
                FirstValueFilling = {FirstValueFilling};
            end
            acceptedValues = ["noFfill","ffillLastAvailable","ffillFromInterval"];
            assert(ismember(FirstValueFilling{1}, acceptedValues), ...
                sprintf("'FirstValueFilling' must take a value in [%s]",acceptedValues))
            
            if strcmp(FirstValueFilling{1},"ffillFromInterval")
                try
                    if length(FirstValueFilling) == 2
                        interval = FirstValueFilling{2};
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
            noFfill = strcmp(FirstValueFilling{1},"noFfill") && ~isempty(posSelector);
            if noFfill
                dataStart=other.data_(posSelector(1),:);
            end
            hasEntry = intervalHasEntry(other.data,posSelector);
            other = other.ffill().loc(index);
            other.data_(~hasEntry)=missingData(class(other.data_));
            
            if noFfill, other.data_(1,:) = dataStart; end
            if strcmp(FirstValueFilling{1}, "ffillFromInterval")
                other = other.iloc(2:length(other.index_));
            end
        end
        function other = horzcat(obj,varargin)
            % horizontal concatenation (outer join) of frames: [df1,df2,df3,...]
            idx = obj.index_;
            sameIndex = true;  % compute a merged index, only in case they are not the same
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
            % vertical concatenation (outer join) of frames: [df1;df2;df3;...]
            % frames must each have unique columns
            col = obj.columns_.value_;
            sameCols = true;  % compute a merged columns, only in case they are not the same
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
            % sort frame from a column
            series = obj.loc(':',columnName);
            [~,sortedID] = sort(series.data);
            obj.index_ = frames.UniqueIndex(obj.index_);
            other = obj.iloc(sortedID);
        end
        function obj = sortIndex(obj)
            % sort frame from the index
            [obj.index_.value_,sortedID] = sort(obj.index_.value_);
            obj.data_ = obj.data_(sortedID,:);
        end
        
        function obj = shift(obj,varargin)
            % SHIFT shift the data vertically
            % ----------------
            % Parameters:
            % * shift   : (integer), default 1
            %       the number of steps to shift the data
            % Example: .shift(2) shifts the data by 2 steps forwards and adds two
            % rows of missing values at the top
            obj.data_ = shift(obj.data_,varargin{:});
        end
        function obj = diff(obj,dim)
            % compute the difference of two consecutive rows
            % ----------------
            % Parameters:
            % * dim   : [1 2], default 1
            %       the dimension on which to compute the difference
            arguments
                obj, dim {mustBeMember(dim,[1,2])} = 1
            end
            d = diff(obj.data_,1,dim);
            if dim == 1
                obj.data_ = [NaN(1,length(obj.columns_.value_));d];
            else
                obj.data_ = [NaN(length(obj.index_.value_),1),d];
            end
        end
        
        function obj = clip(obj,floorVal,ceilVal)
            % put caps and floors to the data
            % .clip(cap) will make all values greater than 'cap' equal to 'cap'
            % .clip(floor,cap) will also make all values smaller than 'floor' equal to 'floor'
            if nargin < 3
                ceilVal = floorVal;
            else
                obj.data_(obj.data_ < floorVal) = floorVal;
            end
            obj.data_(obj.data_ > ceilVal) = ceilVal;
        end
        
        function varargout = plot(obj,params)
            % PLOT plot the frame
            % ----------------
            % Parameters:
            % * Title      : (textScalar), default obj.name
            %       the plot's title
            % * Legend     : logical, default true
            %       if true, the legend is the column names
            % * Log        : logical, default false
            %       if true, plot the semilogy
            % * WholeIndex : logical, default false
            %       if true, plot the whole index, even when data is missing
            %       otherwise, plot only when data is valid
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
            % plot a heatmap of the frame
            figure()
            p = heatmap(obj.columns,obj.index,obj.data,varargin{:});
            title(obj.name);
            if nargout == 1, varargout{1} = p; end
        end
        
        function s = split(obj,varargin)
            % SPLIT split the frame into column-based groups to apply a function separately
            % Use: .split(groups[,groupNames]).apply(@fun)
            %
            % ----------------
            % Parameters:
            %     * groups: (cell array,struct,frames.Group) 
            %          Contain the list of elements in each group. Can be of different types:
            %          - cell array: cell array of lists of elements in groups
            %              In this case, groupNames is required.
            %              e.g. groups={list1,list2}; groupNames=["name1","name2"]
            %          - struct: structure whose fields are group names and values are
            %              elements in each group. If groupNames is not specified, 
            %              the split use all fields of the structure as groupNames.
            %          - frames.Group: Group whose property names are group names and
            %              property values are elements in each group. If groupNames
            %              is not specified, the split use all properties of the 
            %              Group as groupNames.
            %     * groupNames: (string array) 
            %          group names into which we want to split the Frame
            %
            % ----------------
            % Examples (see also unitTests):
            %   - simple split with cell
            %       df=frames.DataFrame([1 2 3;2 5 3;5 0 1]', [6 2 1], [4 1 3]);
            %       df.split({[4,3],1},["d","e"]).apply(@(x) x);
            %   - apply function using group names
            %       ceiler.d = {2.5,4.5};
            %       ceiler.e = {2.6};
            %       x2 = df.split({[4,3],1},["d","e"]).apply(@(x) x.clip(ceiler.(x.name){:}));
            %   - split with structure
            %       s.d = [4 3]; s.e = 1;
            %       x3 = df.split(s).apply(@(x) x.clip(ceiler.(x.name){:}));
            %   - split with a Group
            %       g = frames.Groups([1 4 3],s);
            %       x4 = df.split(g).apply(@(x) x.clip(ceiler.(x.name){:}));
            % See also: frames.Groups, frames.internal.Split
            s = frames.internal.Split(obj,varargin{:});
        end
                
        function obj = relChg(obj,varargin)
            % compute the relative change
            % ----------------
            % Parameters:
            % * changeType  : ["simple","log"], default "simple"
            %       computes the simple relative change d(i+1)./d(i)-1 or the log change log(d(i+1)./d(i))
            % * lag         : (integer), default 1
            %       the lag to compute the change as in d(i+lag)./d(i)-1
            % * overlapping : (logical), default true
            %       whether to return the frame with all the indices (true) or only the indices at n*lag (false)
            obj.data_ = relativeChange(obj.data_,varargin{:});
        end
        function obj = compoundChange(obj,varargin)
            % compound relative changes
            % relative changes must be non-overlapping changes
            % ----------------
            % Parameters:
            % * changeType  : ["simple","log"], default "simple"
            %       type of the relative change
            % * base        :  1x1 or 1xN array, default 1
            %       starting value from which to compound
            obj.data_ = compoundChange(obj.data_,varargin{:});
        end
        function obj = replaceStartBy(obj,varargin)
            % replace start values by 'valNew', if start values equal 'valToReplace' (optional)
            % .replaceStartBy(valNew,valToReplace)
            obj.data_ = replaceStartBy(obj.data_,varargin{:});
        end
        function obj = emptyStart(obj,window)
            % replace the first 'window' valid data by a missing value
            obj.data_ = emptyStart(obj.data_,window);
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
        function obj = cumsum(obj), obj.data_ = nancumsum(obj.data_); end
        % cumulative sum, takes care of missing values
        function obj = cumprod(obj), obj.data_ = nancumprod(obj.data_); end
        % cumulative product, takes care of missing values
        
        function bool = equals(df1,df2,tol)
            % .equals(df1,df2,tolerance) returns true if the index. columns
            % are the same, and if the data are equal in the tolerance range
            if nargin<3, tol=eps; end
            try
                assert(isequal(df1.index,df2.index)&&isequal(df1.columns,df2.columns))
                diff = df1-df2;
                iseq = diff.abs().data <= tol;
                bool = all(iseq(:));
            catch
                bool = false;
            end
        end
        
        % these function overloads are to make chaining possible
        % e.g. df.abs().sqrt()
        function obj = abs(obj), obj.data_ = abs(obj.data_); end
        function obj = exp(obj), obj.data_ = exp(obj.data_); end
        function obj = log(obj), obj.data_ = log(obj.data_); end
        function obj = tanh(obj), obj.data_ = tanh(obj.data_); end
        function obj = floor(obj), obj.data_ = floor(obj.data_); end
        function obj = ceil(obj), obj.data_ = ceil(obj.data_); end
        function obj = sign(obj), obj.data_ = sign(obj.data_); end
        function obj = sqrt(obj), obj.data_ = sqrt(obj.data_); end
        
        function other = sum(obj,varargin), other=obj.matrix2series(@sum,varargin{:}); end
        % SUM sum through the desired dimension
        function other = mean(obj,varargin), other=obj.matrix2series(@mean,varargin{:}); end
        % MEAN mean through the desired dimension
        function other = median(obj,varargin), other=obj.matrix2series(@median,varargin{:}); end
        % MEDIAN median through the desired dimension
        function other = std(obj,varargin), other=obj.matrix2series(@std,[],varargin{:}); end
        % STD standard deviation through the desired dimension
        function other = var(obj,varargin), other=obj.matrix2series(@var,[],varargin{:}); end
        % VAR variance through the desired dimension
        
        function other = max(obj,varargin), other=obj.maxmin(@max,varargin{:}); end
        % MAX maximum through the desired dimension
        function other = min(obj,varargin), other=obj.maxmin(@min,varargin{:}); end
        % MIN minimum through the desired dimension
        function other = maxOf(df1,df2), other=operator(@max,@elementWiseHandler,df1,df2); end
        % maximum of the elements of the two input arguments
        % maxOf(df1,df2), where df2 can be a frame or a matrix
        function other = minOf(df1,df2), other=operator(@min,@elementWiseHandler,df1,df2); end
        % minimum of the elements of the two input arguments
        % minOf(df1,df2), where df2 can be a frame or a matrix
        
        function other = corr(obj), other=corrcov(obj,@corrcoef,Rows='pairwise'); end
        % correlation matrix (pairwise)
        function other = cov(obj), other= corrcov(obj,@cov,'partialRows'); end
        % covariance matrix (pairwise)
        
        function obj = rolling(obj,window)
            % provide rolling window calculations
            % .rolling(window[,windowNaN]).<method>
            %
            % rolling methods:
            %   mean    - rolling moving mean
            %   std     - rolling standard deviation
            %   var     - rolling variance
            %   sum     - rolling sum
            %   median  - rolling median
            %   max     - rolling max
            %   min     - rolling min
            %   cov     - rolling univariate covariance with a series
            %   corr    - rolling univariate correlation with a series
            %   betaXY  - rolling univariate beta of/with a series
            %
            % Parameters:
            %   window:    (integer, or the string "expanding")
            %       Window on which to compute the rolling method
            %   windowNaN: (integer), default ceil(window/3)
            %       Minimum number of observations at the start required to have a value (otherwise result is NaN).
            %
            % See also frames.internal.Rolling
            obj=frames.internal.Rolling(obj,window);
        end
        function obj = ewm(obj,type,value)
            % provide exponential weighted functions
            % .ewm(<DecayType>=value).<method>
            %
            % ewm methods:
            %   mean    - exponentially weighted moving mean
            %   std     - exponentially weighted moving standard deviation
            %   var     - exponentially weighted moving variance
            %
            % Parameters:
            % The decay type is to be specified using one of the following:
            %   - Alpha: specify the smoothing factor directy
            %   - Com: specify the center of mass, alpha=1./(com+1)
            %   - Window: specify the window related to a SMA, alpha=2./(window+1)
            %   - Span: specify decay in terms of span, alpha=2./(span+1)
            %   - Halflife: specify decay in terms of half-life, alpha=1-exp(-log(0.5)./halflife);
            %
            % See also frames.internal.ExponentiallyWeightedMoving
            obj=frames.internal.ExponentiallyWeightedMoving(obj,type,value);
        end
        
        % ToDo demo mlx, html
        % toDo readme
        % ToDo license
        
        
        % ToDo rewrite subsref and subsasgn using the new tools when Matlab
        % release them
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
                    obj = obj.modify(b,selectors{1},selectors{2},fromPosition);
                    return
                end
            end
            if length(s)>1
                obj = builtin('subsasgn',obj,s,b);
                return
            end
            switch s.type
                case '()'
                    [idx,col] = getSelectorsFromSubs(s.subs);
                    obj = obj.modify(b,idx,col);
                case '{}'
                    [idx,col] = getSelectorsFromSubs(s.subs);
                    obj = obj.modify(b,idx,col,true);
                case '.'
                    if ismember(s(1).subs,properties(obj))
                        obj.(s.subs) = b;
                    else
                        error(('''%s'' is not a public property of the ''%s'' class.'),s(1).subs,class(obj));
                    end
            end
        end
        
        function toFile(obj,filePath,varargin)
            % write the frame into a file
            writetable(obj.t,filePath, ...
                'WriteRowNames',true,'WriteVariableNames',true,varargin{:});
        end
        
    end
    
    methods(Access=protected)
        function tb = getTable(obj)
            idx = indexForTable(obj.index);
            col = columnsForTable(obj.columns);
            tb = array2table(obj.data,RowNames=idx,VariableNames=col);
            if ~isempty(obj.index_.name)
                tb.Properties.DimensionNames{1} = char(obj.index_.name);
            end
        end
        function d = defaultData(obj,lengthIndex,lengthColumns,type)
            if nargin<4; type = class(obj.data); end
            d = repmat(missingData(type),lengthIndex,lengthColumns);
        end
        function indexValidation(obj,value)
            assert(length(value) == size(obj.data,1), 'frames:indexValidation:wrongSize', ...
                'index does not have the same size as data')
        end
        function columnsValidation(obj,value)
            assert(length(value) == size(obj.data,2), 'frames:columnsValidation:wrongSize', ...
                'columns do not have the same size as data')
        end
        function idx = getIndexObject(~,index)
            idx = frames.UniqueIndex(index);
            idx.name = "Row";  % to be consistent with 'table' in which the default name of the index is 'Row'
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
            if isequal(data,[])
                if ~iscolon(index)
                    obj.index_.value_(index) = [];
                end
                if ~iscolon(columns)
                    obj.columns_.value_(columns) = [];
                end
            end
        end
        function [index,columns] = localizeSelectors(obj,index,columns)
            if ~iscolon(index)
                index = obj.index_.positionOf(index);
            end
            if ~iscolon(columns)
                columns = obj.columns_.positionOf(columns);
            end
        end
        
        function series = matrix2series(obj,fun,varargin)
            if ~isempty(varargin) && ~isempty(varargin{end})
                dim = varargin{end};  % end because std takes dimension value as argument after the weighting scheme, cf doc std versus doc sum
            else
                dim = 1;
            end
            assert(ismember(dim,[1,2]),'dimension value must be in [1,2]')
            res = fun(obj.data_,varargin{:},'omitnan');
            res(all(isnan(obj.data_),dim)) = NaN;  % puts NaN instead of zero when all entries are NaNs
            series = obj.df2series(res,dim);
        end
        
        function obj = df2series(obj,data,dim)
            if dim == 1
                indexValue = obj.defaultIndex(1);
                obj = frames.DataFrame(data,indexValue,obj.columns,obj.name);
            else
                obj.data_ = data;
                obj.columns_.value = obj.defaultColumns(1);
            end
        end
        
        function series = maxmin(obj,fun,dim)
            if nargin < 3, dim = 1; end
            d = fun(obj.data_,[],dim);
            series = df2series(obj,d,dim);
            if numel( d ) == 1
                if dim == 1
                    loc = obj.index_.value_(obj.data_ == d);
                    loc = loc(1);
                    series.index_.value_ = loc;
                else
                    loc = obj.columns_.value_(obj.data_ == d);
                    loc = loc(1);
                    series.columns_.value_ = loc;
                end
            end
        end
        
        function other = corrcov(obj,fun,varargin)
            d = fun(obj.data_,varargin{:});
            other = frames.DataFrame(d,obj.columns,obj.columns,obj.name_);
        end
    end
 
    methods(Static)
        function df = empty(type)
            % constructor for an empty frame, specifying the data type of
            % the index. 'type' takes a value in ["double","string","datetime"]
            arguments
                type {mustBeTextScalar, mustBeMember(type,["double","string","datetime"])} = 'double'
            end
            switch type
                case 'double'
                    idx = double.empty(0,1);
                case 'string'
                    idx = string.empty(0,1);
                case 'datetime'
                    idx = datetime.empty(0,1); 
            end
            df = frames.DataFrame([],idx);
        end
        function df = fromFile(filePath, varargin)
            % construct a frame from reading a table from a file
            tb = readtable(filePath,...
                'TreatAsEmpty',{'N/A','NA'}, ...
                'ReadRowNames',true,'ReadVariableNames',true, ...
                varargin{:});
            df = frames.DataFrame.fromTable(tb);
            df.index_.name = string(tb.Properties.DimensionNames{1});
        end
        function df = fromTable(t,nameValue)
            % construct a frame from a table
            % by default, row and columns names in Matlab's table are
            % cellstr, while in frames they are strings.
            % keepCellstr=false (default) will turn cellstr into strings
            arguments
                t {mustBeA(t,'table')}
                nameValue.keepCellstr (1,1) logical = false
            end
            cols = t.Properties.VariableNames;
            idx = t.Properties.RowNames;
            if ~nameValue.keepCellstr
                cols = string(cols);
                idx = string(idx);
            end
            df = frames.DataFrame(t.Variables,idx,cols);
            df.index_.name = string(t.Properties.DimensionNames{1});
        end
    end
    
    methods(Hidden)
        function disp(obj)
            maxRows = 100;
            maxCols = 50;  % Matlab struggles to show many columns
            if all(size(obj) < [maxRows,maxCols])
                disp(obj.t);
            else
                details(this);
            end
        end
        
        function n = numArgumentsFromSubscript(varargin), n = 1; end
        function e = end(obj,q,w), e = builtin('end',obj.data_,q,w); end
        
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
        function other = ldivide(df1,df2)
            other = operator(@ldivide,@elementWiseHandler,df1,df2);
        end
        function other = power(df1,df2)
            other = operator(@power,@elementWiseHandler,df1,df2);
        end
        function other = mpower(df1,df2)
            other = operator(@mpower,@matrixOpHandler,df1,df2);
        end
        
        function other = lt(df1,df2)
            other = operator(@lt,@elementWiseHandler,df1,df2);
        end
        function other = gt(df1,df2)
            other = operator(@gt,@elementWiseHandler,df1,df2);
        end
        function other = le(df1,df2)
            other = operator(@le,@elementWiseHandler,df1,df2);
        end
        function other = ge(df1,df2)
            other = operator(@ge,@elementWiseHandler,df1,df2);
        end
        function bool = eq(df1,df2)
            bool = df1.equals(df2,0);
        end
        function bool = ne(df1,df2)
            bool = ~df1.eq(df2);
        end
        
        function other = ctranspose(obj)
            other = frames.DataFrame(obj.data_',obj.columns,obj.index,obj.name_);
        end
        function other = transpose(obj)
            other = frames.DataFrame(obj.data_.',obj.columns,obj.index,obj.name_);
        end
        
        function obj = uminus(obj), obj.data_ = uminus(obj.data_); end
        function obj = uplus(obj), obj.data_ = uplus(obj.data_); end
        
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

%--------------------------------------------------------------------------
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
            'frames:matrixOpHandler:notAligned','Frames are not aligned!')
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
% ToDo we allow computation with a series without looking at its Index value (how to make it more robust for the cases we do want to check the Index, i.e. when working with two vector Frames? a SingletonIndex, a property in DF or Index?)
function [idx_,col_,df] = elementWiseHandler(df1,df2)
df = df1;
if isa(df2,'frames.DataFrame')
    if isa(df1,'frames.DataFrame')
        if size(df1,1)>1 && size(df2,1)>1
            assert(isequal(df1.index_.value_,df2.index_.value_), ...
                'frames:elementWiseHandler:differentIndex','Frames have different indices!')
        end
        if size(df1,2)>1 && size(df2,2)>1
            assert(isequal(df1.columns_.value_,df2.columns_.value_), ...
                'frames:elementWiseHandler:differentColumns','Frames have different columns!')
        end
        idx_ = df1.index_;
        if size(df2,1)>size(df1,1), idx_ = df2.index_; end
        col_ = df1.columns_;
        if size(df2,2)>size(df1,2), col_ = df2.columns_; end
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
[v1,v2] = getData_(df1,df2);
d = fun(v1,v2);
other.data_ = d; other.index_ = idx_; other.columns_ = col_;
other.description = "";
end

