classdef DataFrame
%DATAFRAME is a class to store and do operations on data matrices that are referenced by column and row identifiers.
%   It is a convenient way to perform operations on labeled matrices.
%   Its aim is to have properties of a matrix and a table at the same time.
%
%   Constructor:
%   df = frames.DataFrame([data,rows,columns,Name=name,RowSeries=logical,ColSeries=logical])
%   If an argument is not specified, it will take a default value, so it
%   is possible to only define some of the arguments:
%   df = frames.DataFrame(data)  
%   df = frames.DataFrame(data,[],columns)
%
%   NameValueArgs possible keys are
%   Name: (textScalar) the name of the Frame
%   RowSeries: (logical) whether the Frame is treated like a row series (see below)
%   ColSeries: (logical) whether the Frame is treated like a column series (see below)
%
%   DATAFRAME properties:
%     data                   - Data matrix  TxN
%     rows                   - Rows         Tx1
%     columns                - Columns      1xN
%     t                      - Table built on the properties above.
%     name                   - Name of the frame
%     description            - Description of the frame
%     rowseries              - logical, whether the Frame is treated as a
%                              row series (ie not considering the value of
%                              the 1-dimension row for operations)
%     colseries              - logical, whether the Frame is treated as a
%                              column series (ie not considering the value of
%                              the 1-dimension column for operations)
%     identifierProperties   - structure of rows and columns properties,
%                              namely whether they accept duplicates, 
%                              require unique elements, or require unique 
%                              and sorted elements
%
%
%   Short overview of methods available:
%
%   - Selection and modification based on row/column names with () or the loc method:
%     df(rowsNames,columnsNames)
%     df.loc(rowsNames,columnsNames)
%     df(rowsNames,columnsNames) = newData
%     df.loc(rowsNames,columnsNames) = newData
%
%   - Selection and modification based on position with {} or the iloc method:
%     df{rowsPosition,columnsPosition}
%     df.iloc(rowsPosition,columnsPosition)
%     df{rowsPosition,columnsPosition} = newData
%     df.iloc(rowsPosition,columnsPosition) = newData
%
%   - Operations between frames while checking that the two frames
%     are aligned (to be sure to compare apples to apples):
%     df1 + df2
%     1 + df
%     df1' * df2, etc.
%
%   - Chaining of methods:
%     df.relChg().std(),  computes the standard deviation of the
%     relative change of df
%     df{5:end,:}.log().diff(),  computes the difference of the log of df
%     from lines 5 to end
%
%   - Visualisation methods:
%     df.plot(), df.heatmap()
%
%   - Setting properties is checked to insure the coherence of the frame.
%     df.rows = newRows,  will give an error if length(newRows) ~= size(df.data,1)
%
%   - Concatenation of frames:
%     newDF = [df1,df2] concatenates two frames horizontally, and will
%     expand (unify) their rows if they are not equal, inserting missing
%     values in the expansion
%
%   - Split a frame into groups based on its columns, and apply a function:
%     df.split(groups).aggregate(@(x) x.sum(2))  sums the data on the dimension
%     2, group by group, so the result is a T x numberOfGroups frame
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
% Contact: frames.matlab@gmail.com
%
% See also: frames.TimeFrame
    
    properties(Dependent)
        % Provide the interface. Include tests in the getters and setters.
        
        data  % TxN matrix of homogeneous data
        rows  % Tx1 vector
        columns  % 1xN vector
        name  % textscalar, name of the frame 
        t  % table, dependent and built on data, rows, columns
        rowseries  % logical, whether the Frame is to be considered as a row series
        colseries  % logical, whether the Frame is to be considered as a column series
        identifierProperties  % structure of the properties of the Index objects underlying .rows and .columns
    end
    properties(Dependent, Hidden)
        index
        constructor
    end
    properties (Constant)      
      settingsDefault = frames.DataFrameSettingsDefault;      
    end
    properties
        settings frames.DataFrameSettings = frames.DataFrameSettings;
        description = ""  % text description of the object
    end
    properties(Hidden, Access=protected)
        % Encapsulation. Internal use, there are no tests in the getters
        % and setters.
        
        data_  % TxN matrix of homogeneous data
        rows_  % Tx1 frames.Index with requireUnique=true
        columns_  % Nx1 frames.Index
        name_  % textscalar, name of the frame
    end
    
    methods
        function obj = DataFrame(data,rows,columns,NameValueArgs)
            %DATAFRAME frames.DataFrame([data,rows,columns,Name=name,RowSeries=logical,ColSeries=logical])
            %
            %remark: if row/columns are specific MultiIndex input, create MultiIndex objects
            % 
            arguments
                data (:,:) = []
                rows = []
                columns = []
                NameValueArgs.Name = ""
                NameValueArgs.RowSeries {mustBeA(NameValueArgs.RowSeries,'logical')} = false
                NameValueArgs.ColSeries {mustBeA(NameValueArgs.ColSeries,'logical')} = false
            end
            % get DataFrameSettings
            obj.settings = frames.DataFrameSettings(obj.settingsDefault);
                                                          
            % get row index 
            useMultiIndexRows = checkMultiIndexinput(rows);
            if checkIsEmpty(rows)                    
                if NameValueArgs.RowSeries                
                    rows = missingData('double');
                else                
                    rows = obj.defaultRows(size(data,1));                                
                end
            end            
            if ~isIndex(rows) || (isIndex(rows) && numel(rows)>1)
                if ~useMultiIndexRows
                   rows = obj.getRowsObject(rows,Singleton=NameValueArgs.RowSeries);
                else
                   rows = frames.MultiIndex(rows,Singleton=NameValueArgs.RowSeries,Unique=true);
                end
            else
                assert(~NameValueArgs.RowSeries || (rows.singleton_ && numel(rows)==1), ...
                   'frames:constructor:rowsSingletonFail', 'RowSeries needs to have a singleton Index object in rows.');
            end
            
            % get column index
            useMultiIndexColumns = checkMultiIndexinput(columns);
            if checkIsEmpty(columns)
                if NameValueArgs.ColSeries                                               
                    columns = missingData('string');                 
                else            
                    columns = obj.defaultColumns(size(data,2));                                  
                end
            end
            if ~isIndex(columns) || (isIndex(columns) && numel(columns)>1)               
                if ~useMultiIndexColumns
                   columns = obj.getColumnsObject(columns,Singleton=NameValueArgs.ColSeries);
                else
                   columns = frames.MultiIndex(columns,Singleton=NameValueArgs.ColSeries);
                end
            else
                assert(~NameValueArgs.ColSeries || columns.singleton_,'frames:constructor:columnsSingletonFail', ...
                    'ColumnSeries needs to have a singleton Index object in columns.')
            end
                       
            if isempty(data)
                data = obj.defaultData(length(rows),length(columns),class(data));
            end
            if iscolumn(data)
                data = repmat(data,1,length(columns));
            end
            if isrow(data)
                data = repmat(data,length(rows),1);
            end
            
            obj.data_ = data;
            obj.rows = rows;
            obj.columns = columns;
            obj.name_ = NameValueArgs.Name;                       
            
            
            function bool = checkMultiIndexinput(value)
                % check if input is specific for MultiIndex
                % (all cell arrays (except char cell array), 2d arrays, and arrays of multiple Index objects)                  
                if (isempty(value) && iscell(value)) || ...          % empty cell array
                   (~isempty(value) && ...
                     ( ...     
                        (iscell(value) && ~ischar(value{1})) || ...  % cell array (except char cell array)
                        ~isvector(value) ||  ...                     % 2d array
                        (~isscalar(value) && isIndex(value(1)) ) ... % 1d array with more than 1 Index object
                     ) ...
                   )
                   bool = true; 
                else
                   bool = false; % 1d array or char cell array
                end
            end
            
            function bool = checkIsEmpty(value)
                % check if input to create empty index
                bool = isequal(value,[]) || ...
                         (iscell(value) && ...
                               (isempty(value) || ...
                                iscell(value{1}) && ~isempty(value{1}) && ismissing(value{1}{1})) ...
                               ) || ...                         
                         isequal(value,{[]});
            end
            
        end
        
        %------------------------------------------------------------------
        
        function obj = initCopy(obj, data, rows, columns)
            % initalize a new DataFrame with new data, row and column values,
            % while keeping settings and same class types of row and column object.
            %
            % input:
            %   - data:     2d matrix with values
            %   - rows:     input supported by setvalue() of rows index class
            %   - columns:  input supported by setvalue() of columns index class
            % 
            % output:
            %   dataframe with new values
            %
            obj.data_ = data;
            obj.rows_.value = rows;
            obj.columns_.value = columns;
            % validate rows and column size match datasize            
            assert(obj.rows_.length() == size(data,1),  'frames:initCopy:mismatchrows', ...
                  "Number of rows not matching data size.");
            assert(obj.columns_.length() == size(data,2), 'frames:initCopy:mismatchcolumns', ...
                  "Number of columns not matching data size.");
        end
            
        
        
        %------------------------------------------------------------------
        % Setters and Getters
        function obj = set.rows(obj, value)
            obj.rowsValidation(value)
            if isa(value,'frames.Index')
                obj.rows_ = value;
            else
                obj.rows_.value = value;
            end
        end
        function obj = set.index(obj, value)
            warning('index is being deprecated. Use rows instead.')
            obj.rows = value;
        end
        function obj = set.columns(obj,value)
            obj.columnsValidation(value);
            if isa(value,'frames.Index')
                obj.columns_ = value;
            else
                obj.columns_.value = value;
            end
        end
        function obj = set.data(obj,value)
            assert(all(size(value)==size(obj.data_)), 'frames:dataValidation:wrongSize', ...
                'data is not of the correct size')
            obj.data_ = value;
        end
        function obj = set.name(obj,value)
            arguments
                obj, value {mustBeTextScalar}
            end
            obj.name_ = value;
        end
        function obj = set.rowseries(obj,bool)
            obj.rows_.singleton = bool;
        end
        function obj = set.colseries(obj,bool)
            obj.columns_.singleton = bool;
        end
        function obj = asColSeries(obj,bool)
            % sets .colseries to true if the Frame can be a column series
            if nargin<2, bool=true; end
            if obj.columns_.singleton ~= bool
               obj.columns_.singleton = bool;
            end
        end
        function obj = asRowSeries(obj,bool)
            % sets .rowseries to true if the Frame can be a row series
            if nargin<2, bool=true; end
            if obj.rows_.singleton ~= bool
               obj.rows_.singleton = bool;
            end
        end
        function obj = asFrame(obj)
            % sets .rowseries and .colseries to false
            obj = obj.asColSeries(false).asRowSeries(false);
        end
        function series = col(obj,colName)
            % returns a colseries of the column name given
            series = obj.loc(':',colName).asColSeries();
        end
        function series = row(obj,rowName)
            % returns a rowseries of the row name given
            series = obj.loc(rowName,':').asRowSeries();
        end
        
        function rows = get.rows(obj)
            rows = obj.rows_.value;
        end
        function index = get.index(obj)
            warning('index is being deprecated. Use rows instead.')
            index = obj.rows;
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
        function bool = get.rowseries(obj)
            bool = obj.rows_.singleton_;
        end
        function bool = get.colseries(obj)
            bool = obj.columns_.singleton_;
        end
        function t = get.t(obj)
            t = obj.getTable();
        end
        function s = get.identifierProperties(obj)
            s.columns = publicProps2struct(obj.columns_,Skip="value");
            s.columns.class = class(obj.columns_);
            s.rows = publicProps2struct(obj.rows_,Skip="value");
            s.rows.class = class(obj.rows_);
        end
        function c = get.constructor(obj)
            c = str2func(class(obj));
        end
        
        function row = getRowsObj(obj)
            % get the Index object underlying rows
            row = obj.rows_;
        end
        function col = getColumnsObj(obj)
            % get the Index object underlying columns
            col = obj.columns_;
        end
        function obj = setRowsType(obj,type)
            % type can be "unique", "sorted", or "duplicate"
            obj.rows_ = transformIndex(obj.rows_,type);
        end
        function obj = setColumnsType(obj,type)
            % type can be "unique", "sorted", or "duplicate"
            obj.columns_ = transformIndex(obj.columns_,type);
        end
        function obj = setRowsName(obj,name)
            % the rows name will appear as the first of the DimensionNames in the table .t
            obj.rows_.name = name;
        end
        function obj = setColumnsName(obj,name)
            obj.columns_.name = name;
        end
        
        function obj = setRows(obj,colName, options)
            % set the rows value from the value of a column
            % (multiple columns allowed in case of row MultiIndex)
            %            
            arguments
                obj
                colName
                options.keep = false; % keep columns
            end            
            colselect = obj.columns_.positionOf(colName);
            if ~isMultiIndex(obj.rows_)
               % Index                
               assert(length(colselect)==1, 'frames.DataFrame.setRows.MultiIndexRequired', ...
                     "Multiple columns selected, but row is not of type MultiIndex");          
               obj.rows = obj.data(:,colselect);  
            else
               % MultiIndex (number of dimension can change & update dim names from col names)
               colnames = obj.columns_.getValueForTable();
               colnames = string(colnames(colselect));
               obj.rows_ = obj.rows_.setIndex(obj.data(:,colselect), colnames(:));
            end
            if ~options.keep
                % remove selected columns
               obj = obj.dropColumns(colName);
            end
        end
        
        function obj = resetUserProperties(obj)
            obj.name_ = "";
            obj.description = "";
        end
                
        function obj = alignMethod(obj, alignMethod)
            % change alignMethod setting
            obj.settings.alignMethod=alignMethod;
        end
        function obj = autoAlign(obj)
            % change alignMethod setting to 'full'
            obj.settings.alignMethod="full";
        end
        
        
        function t = head(obj, varargin); t = head(obj.t,varargin{:}); end
        % returns the first rows of the table
        function t = tail(obj, varargin); t = tail(obj.t,varargin{:}); end
        % returns the last rows of the table
        
        %------------------------------------------------------------------
        % Selection
        function obj = iloc(obj,rowPosition,colPosition)
            % selection based on position: df.iloc(rowsPosition[,columnsPosition])
            % df.iloc([5 9], [1 4]) returns the 5th and 9th rows of the 1st and 4th columns
            % df.iloc(:,4) returns the 4th column
            % df.iloc(2,:) or df.iloc(2) returns the 2nd row
            if nargin<3, colPosition=':'; end
            obj = obj.loc_(rowPosition,colPosition,true,true);
        end
        function obj = loc(obj,rowName,colName)
            % selection based on names: df.loc(rowsNames[,columnsNames])
            % df.loc([2 4], ["a" "b"]) returns the rows named 2 and 4 of the columns named "a" and "b"
            % df.loc(:,"a") returns the column named "a"
            % df.loc(2,:) or df.loc(2) returns the row named 2
            if nargin<3, colName=':'; end
            obj = obj.loc_(rowName,colName,true,false);
        end
        function obj = filt(obj,rowName,colName)
            % selection based on names, interpret as filter criteria of original dataframe
            % (keep original order independent of order in selector, ignore duplicates in selector and
            %  allow not matching selectors)
            if nargin<3, colName=':'; end
            obj = obj.loc_(rowName,colName,true,false,true);
        end
        
        
        function obj = replace(obj,valToReplace,valNew)
            % REPLACE replace the a value in the data with another one
            if ismissing(valToReplace)
                row = ismissing(obj.data_);
            else
                row = obj.data_==valToReplace;
            end
            obj.data_(row) = valNew;
        end
        
        function df = dropMissing(obj,nameValue)
            % remove rows or columns with missing data
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
                df = obj.iloc_(~drop,':');
            else
                df = obj.iloc_(':',~drop);
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
        
        function other = extendRows(obj,rows)
            % extend the rows with the new values
            if iscell(rows) && ~iscell(rows{1}) %handle multiIndex syntax
                rows = {rows};
            end
            valuesToAdd = rows(~obj.rows_.ismember(rows));            
            newRows = obj.rows_.union(valuesToAdd);
            newData = obj.defaultData(length(newRows),length(obj.columns_));
            
            if obj.rows_.requireUniqueSorted_
                row = obj.rows_.positionIn(newRows.value,false);
            else
                row = 1:length(obj.rows_);
            end
            newData(row,:) = obj.data_;
            
            other = obj;
            other.data_ = newData;
            other.rows_ = newRows;
        end
        function other = dropRows(obj,rows)
            % drop the specified rows values
            rowToRemove = obj.rows_.positionOf(rows);
            rowToKeep = setdiff(1:length(obj.rows_),rowToRemove);
            other = obj.iloc_(rowToKeep,':');
        end
        function other = extendColumns(obj,columns)
            % extend the columns with the new values
            if iscell(columns) && ~iscell(columns{1}) %handle multiIndex syntax
                columns = {columns};
            end
            valuesToAdd = columns(~obj.columns_.ismember(columns));
            newColumns = obj.columns_.union(valuesToAdd);
            newData = obj.defaultData(length(obj.rows_),length(newColumns));
            
            if obj.columns_.requireUniqueSorted_
                col = obj.columns_.positionIn(newColumns.value,false);
            else
                col = 1:length(obj.columns_);
            end
            newData(:,col) = obj.data_;
            
            other = obj;
            other.data_ = newData;
            other.columns_ = newColumns;
        end
        function other = dropColumns(obj,columns)
            % drop the specified column values
            colToRemove = obj.columns_.positionOf(columns);
            colToKeep = setdiff(1:length(obj.columns_),colToRemove);
            other = obj.iloc_(':',colToKeep);
        end
        function other = resample(obj,rows,nameValue)
            % RESAMPLE resample the frame with the new rows and propagates the data if there are missing values
            % It propagates the last valid data between two consecutive
            % rows values. If all data are missing, it propagates the
            % missing value. Only works with sorted rows.
            % ----------------
            % Parameters:
            % * rows                : target rows
            % * FirstValueFilling   : ["noFfill","ffillLastAvailable","ffillFromInterval"], default "noFfill"
            %           specifies how the data for the first rows value is propagated.
            %           - "noFill" takes the value of the original frame
            %           - "ffillLastAvailable" takes the last available value
            %           - "ffillFromInterval" takes the last available value in a specified interval
            %             By default, the interval is rows(2)-rows(1) but
            %             can be specified with FirstValueFilling={"ffillFromInterval",specificInterval}
            %
            % Example (see also UnitTests):
            % sortedframe = frames.DataFrame([4 1 NaN 3; 2 NaN 4 NaN]',[1 4 10 20]).setRowsType("sorted");
            % ffi = sortedframe.resample([2 5],FirstValueFilling='ffillFromInterval');
            arguments
                obj, rows
                nameValue.FirstValueFilling = "noFfill"
            end
            if ~obj.rows_.requireUniqueSorted
                error('Only use resample with a sorted Index (set obj.setRowsType("sorted"))')
            end
            assert(obj.rows_.Ndim==1,'frames.DataFrame:resample:multipleRowDimsNotSupported', ...
                "Multiple row dimensions not supported");
            if isrow(rows), rows=rows'; end %MultiIndex requires column vector
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
                        interval = rows(2)-rows(1);
                    end
                    if isrow(rows), rows=rows'; end
                    rows = [rows(1)-interval;rows];
                catch me
                    error('The interval is not valid. It must be substractable from the rows.')
                end
            end
            other = obj.extendRows(rows);
            posSelector = other.rows_.positionOf(rows);
            noFfill = strcmp(FirstValueFilling{1},"noFfill") && ~isempty(posSelector);
            if noFfill
                dataStart=other.data_(posSelector(1),:);
            end
            hasEntry = intervalHasEntry(other.data,posSelector);
            other = other.ffill().loc_(rows,':');
            other.data_(~hasEntry)=missingData(class(other.data_));
            
            if noFfill, other.data_(1,:) = dataStart; end
            if strcmp(FirstValueFilling{1}, "ffillFromInterval")
                other = other.iloc_(2:length(other.rows_),':');
            end
            
            % subfunction
            function hasEntry = intervalHasEntry(data,selector)
                hasEntry = true(length(selector),size(data,2));

                isValid = ~ismissing(data);
                for ii = 2:length(selector)
                    hasEntry(ii,:) = any(isValid(selector(ii-1)+1:selector(ii),:),1);
                end
            end
        end
        
        
        
        function dfnew = combine(obj, df, options)
            % function to concatenate one or multiple dataframes
            %
            % The requireUnique and requireUniqueSorted settings of obj will be used in the new combined dataframe.
            % The method to combine the row and column indices can be specified with 'alignMethodRows' and 
            % 'alignMethodCols'.
            % 
            % alignMethodRows and alignMethodCols options are:
            %  - 'unique':           only keep unique values in combined index.
            %                        (only option that is allowed for indexes that requireUnique)
            %
            %  - 'keepDuplicates:    only keep unique values in combined index, but if already indices have
            %                        duplicate values, keep them in. If multiple dataframes indices have the
            %                        same duplicate values, align them in the same order as they occur in the index.            
            %
            %  - 'none':             append all values of indices together, even if that creates new duplicates.                        
            %
            % If multiple dataframes in the conctenation define the same value in the combined dataframe, the 'order'
            % option specifies which data to keep:
            %    - "keepLast":  last occurance is used
            %    - "keepFirst": first occurance is used
            %            
            % usage: 
            %   df.combine( df1,df2,df3, alignMethodRows="unique", alignMethodCols="unique", order="keepLast")
            %        
            % output:
            %    concatenated dataframe
            %
            arguments
                obj
            end
            arguments (Repeating)
                df {mustBeA(df, 'frames.DataFrame')}
            end
            arguments
                options.alignMethodRows {mustBeMember(options.alignMethodRows, ...
                                        ["unique","keepDuplicates","none"])} = "unique"
                options.alignMethodCols {mustBeMember(options.alignMethodCols, ...
                                        ["unique","keepDuplicates","none"])} = "unique"
                options.order           {mustBeMember(options.order, ["keepFirst","keepLast"])} = "keepLast"           
            end
            % skip, if nothing to do            
            if isempty(df)
                dfnew = obj;
                return
            end
            % check methods and required uniqueness of indices
            if obj.rows_.requireUnique               
                assert(options.alignMethodRows=="unique", ...
                    'frames:DataFrame:combine:invalidRowsMethod', ...
                    "Invalid alignMethodRows option. Row index has requireUnique enabled, only 'unique' allowed.");
                rows_requireUnique = cellfun(@(x) x.rows_.isunique() || length(x.rows_)==0, df);
                assert(all(rows_requireUnique), 'frames:DataFrame:combine:notAllRowsUnique', ...
                    "Obj rows has requireUnique enabled and not all other df rows are unique.");
            end
            if obj.columns_.requireUnique
                assert(options.alignMethodCols=="unique", ...
                    'frames:DataFrame:combine:invalidColsMethod', ...
                    "Invalid alignMethodCols option. Column index has requireUnique enabled, only 'unique' allowed.");
                columns_requireUnique = cellfun(@(x) x.columns_.isunique() || length(x.columns_)==0, df);
                assert(all(columns_requireUnique), 'frames:DataFrame:combine:notAllColumnsUnique', ...
                    "Obj columns has requireUnique enabled and not all other df columns are unique.");                 
            end            
            
            % get index objects            
            rowsobj = cellfun(@(x) {x.rows_}, df);
            colsobj = cellfun(@(x) {x.columns_}, df);            
            % get new combined index objects and position index          
            [rowsnew, rowsnew_ind] = obj.rows_.union_(rowsobj, options.alignMethodRows);
            [colsnew, colsnew_ind] = obj.columns_.union_(colsobj, options.alignMethodCols);            
            % get empty dataframe (with same settings)
            dfnew = obj;
            dfnew.rows_ = rowsnew;
            dfnew.columns_ = colsnew;
            dfnew.data_ = obj.defaultData(rowsnew.length(), colsnew.length());
            dfnew = resetUserProperties(dfnew);
            type = class(dfnew.data_);
            % add object itself to the list
            df = [{obj} df];            
            % define order
            dforder = 1:length(df);
            if options.order == "keepFirst"
                dforder = flip(dforder);
            end
            % assign data from each dataframe in the list
            elements_assigned = false(size(dfnew));            
            for i=dforder
                % get position indices                
                rowind = rowsnew_ind{i};
                colind = colsnew_ind{i};
                % checks
                assert(isa(df{i}.data_,type),'frames:concat:differentDatatype', ...
                     'frames do not have the same data type')
                if any(elements_assigned(rowind,colind),'all')
                    if options.order=="keepFirst", ordername="first"; else, ordername="last"; end 
                    warning('frames:concat:overlap', ...
                      "Overlapping values (with same row and column index) between different dataframes detected. " + ...
                      "Value of " + ordername + " dataframe will be used.");                   
                end
                elements_assigned(rowind,colind)= true;
                % assign values
                dfnew.data_(rowind,colind) = df{i}.data_;
            end            
        end
               
        function other = horzcat(obj,varargin)
            % horizontal concatenation (inner join) of frames: [df1,df2,df3,...]
            alignMethodRows="keepDuplicates";
            alignMethodCols="none";
            if obj.rows_.requireUnique, alignMethodRows="unique"; end        
            if obj.columns_.requireUnique, alignMethodCols="unique"; end
            other = obj.combine(varargin{:}, alignMethodRows=alignMethodRows, ...
                                             alignMethodCols=alignMethodCols, order="keepLast");
        end
        
        function other = vertcat(obj,varargin)
            % vertical concatenation (outer join) of frames: [df1;df2;df3;...]                                    
            alignMethodRows="none";
            alignMethodCols="keepDuplicates";            
            if obj.rows_.requireUnique, alignMethodRows="unique"; end        
            if obj.columns_.requireUnique, alignMethodCols="unique"; end            
            other = obj.combine(varargin{:}, alignMethodRows=alignMethodRows, ...
                                             alignMethodCols=alignMethodCols, order="keepLast");
        end
        
        
        %==================================================================
        % table related functions
        function varargout = join(obj,df2,varargin)
            % cf table join
            [varargout{1:nargout}] = obj.tableFunctions(@join,[],df2.t,varargin{:});
        end
        function varargout = innerjoin(obj,df2,varargin)
            % cf table innerjoin
            [varargout{1:nargout}] = obj.tableFunctions(@innerjoin,[],df2.t,varargin{:});
        end
        function varargout = outerjoin(obj,df2,varargin)
            % cf table outerjoin
            [varargout{1:nargout}] = obj.tableFunctions(@outerjoin,[],df2.t,varargin{:});
        end
        function varargout = union(obj,df2,varargin)
            % cf table union
            [varargout{1:nargout}] = obj.tableFunctions(@union,[],df2.t,varargin{:});
        end
        function varargout = intersect(obj,df2,varargin)
            % cf table intersect
            [varargout{1:nargout}] = obj.tableFunctions(@intersect,[],df2.t,varargin{:});
        end
        function varargout = ismember(obj,df2,varargin)
            % cf table ismember
            [varargout{1:nargout}] = obj.tableFunctions(@ismember,NaN,df2.t,varargin{:});
        end
        function varargout = setdiff(obj,df2,varargin)
            % cf table setdiff
            [varargout{1:nargout}] = obj.tableFunctions(@setdiff,[],df2.t,varargin{:});
        end
        function varargout = setxor(obj,df2,varargin)
            % cf table setxor
            [varargout{1:nargout}] = obj.tableFunctions(@setxor,[],df2.t,varargin{:});
        end
        function varargout = groupfilter(obj,varargin)
            % cf table groupfilter
            [varargout{1:nargout}] = obj.tableFunctions(@groupfilter,[],varargin{:});
        end
        function varargout = grouptransform(obj,varargin)
            % cf table grouptransform
            [varargout{1:nargout}] = obj.tableFunctions(@grouptransform,[],varargin{:});
        end
        function varargout = groupsummary(obj,varargin)
            % cf table groupsummary
            [varargout{1:nargout}] = obj.tableFunctions(@groupsummary,'DataFrame',varargin{:});
        end
        function varargout = groupcounts(obj,varargin)
            % cf table groupcounts
            [varargout{1:nargout}] = obj.tableFunctions(@groupcounts,'DataFrame',varargin{:});
        end
        function varargout = findgroups(obj,varargin)
            % cf table findgroups
            [varargout{1:nargout}] = obj.tableFunctions(@findgroups,missing,varargin{:});
            if nargout == 2
                varargout{2} = frames.DataFrame.fromTable(varargout{2});
            end
        end
        function varargout = splitapply(obj,fun,groups)
            % cf table splitapply
            [varargout{1:nargout}] = splitapply(fun,obj.t,groups);
        end
        
        function [obj,row] = sortrows(obj,varargin)
            % cf table sortrows
            [tb,row] = sortrows(obj.t,varargin{:});
            obj.data = tb.Variables;
            obj.rows_.requireUniqueSorted = false;
            obj.rows_.value_ = obj.rows_.value_(row);
        end
        function bool = issortedrows(obj,varargin)
            % cf table issortedrows
            bool = issortedrows(obj.t,varargin{:});
        end
        %==================================================================
        
        function [other,sortedID] = sortBy(obj,columnName)
            % sort frame from a column
            col = obj.loc_(':',columnName);
            [~,sortedID] = sort(col.data);
            obj.rows_.requireUniqueSorted = false;
            other = obj.iloc_(sortedID,':');
        end
        function [obj,sortedID] = sortRows(obj)
            % sort frame from the rows
            [obj.rows_, sortedID] = obj.rows_.sort();            
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
                obj.data_ = [NaN(length(obj.rows_.value_),1),d];
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
            % * WholeRows : logical, default false
            %       if true, plot the whole rows, even when data is missing
            %       otherwise, plot only when data is valid
            % ----------------
            % Output            [f,p]
            % f             : figure
            % p             : plot
            arguments
                obj
                params.Title {mustBeTextScalar} = obj.name
                params.Legend (1,1) logical = true
                params.Log (1,1) logical = false
                params.WholeRows (1,1) logical = false
            end
            
            if issorted(obj.rows_)
                obj.data_ = interpMissing(obj.data_);
            end
            
            useRows = obj.rows_.issorted() && ...
                (isnumeric(obj.rows) || isdatetime(obj.rows));  % any type that can be shown on the x axis
            f = figure();
            if useRows
                args = {obj.rows,obj.data};
            else
                args = {obj.data};
            end
            if params.Log
                p = semilogy(args{:});
            else
                p = plot(args{:});
            end
            if ~useRows, xtick([]); end
            grid on
            title(params.Title)
            if params.Legend && ~any(ismissing(obj.columns_.value_))
                cols = string(obj.columns);
                legend(cols,Location='Best');
            end
            if params.WholeRows
                xlim([obj.rows(1),obj.rows(end)])
            end
            if nargout >= 1, varargout{1} = f; end
            if nargout >= 2, varargout{2} = p; end
        end
        function varargout = heatmap(obj,varargin)
            % plot a heatmap of the frame
            figure()
            p = heatmap(obj.columns,obj.rows,obj.data,varargin{:});
            title(obj.name);
            if nargout == 1, varargout{1} = p; end
        end
        
        function s = split(obj,group,varargin)
            % SPLIT split a Frame into groups to apply a function separately group by group
            % Use: dfsplit = df.split(frames.Groups[,flags]).<apply,aggregate>(func[,args,flag])
            %
            % ----------------
            % Parameters:
            %     * groups: frames.Groups
            %          Object that contains keys and values describing
            %          groups. Please refer to the documentation of
            %          frames.Groups for more details.
            %     * flags: 'allowOverlaps', 'allowNonExhaustive'
            %          Split throws an error if there are overlaps in the
            %          group values, and if they do not span the whole set
            %          of the Index values. Allow these cases by respectively
            %          adding the flags 'allowOverlaps' and 'allowNonExhaustive'
            %
            % Methods:
            %     * apply      
            %           apply a function to each sub-Frame, and returns a single Frame. Maintains the structure of the original Frame.
            %     * aggregate  
            %           apply a function to each sub-Frame, and returns a single Frame. Returns a single vector for each group.
            %
            % Method parameters:
            %     * fun: function to apply, must be applicable to a matrix
            %     * flag enum('applyToFrame','applyToData'), 'applyToData' (default):
            %           allows to use DataFrame methods, but may be slower than
            %           applying a function directly to the data with 'applyToData'
            %           e.g. .apply(@(x) sum(x,2),'applyToData') vs .apply(@(x) x.sum(2),'applyToFrame')
            %     * flag 'applyByLine':
            %             allows to pass a function that will be applied line by
            %       line instead of on a matrix (by default)
            %    To use the group key for a frame, use x.description e.g.
            %    to link a structure field to a specific group: .apply(@(x) x.*myStruct.(x.description),'applyToFrame')
            % 
            % See also: frames.Groups, frames.internal.Split
            s = frames.Split(obj,group,varargin{:});
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
            [obj.data_,row] = relativeChange(obj.data_,varargin{:});
            obj.rows_= obj.rows_.getSubIndex(row);
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
            % replaceStartBy Replace all consecutive identical values at the beginning of the columns by 'valueNew',
            % if the values equal 'valueToReplace' (optional,
            % if not given, it consider the first values of each column)
            obj.data_ = replaceStartBy(obj.data_,varargin{:});
        end
        function obj = emptyStart(obj,window)
            % replace the first 'window' valid data by a missing value
            obj.data_ = emptyStart(obj.data_,window);
        end
        function [row, ix] = firstCommonRow(obj)
            % returns the first row where data are "all" not missing
            % Output:
            %   - row: the row name
            %   - ix: the row position
            ix = find(all(~ismissing(obj.data_),2),1);
            row = obj.rows(ix);
        end
        function [row, ix] = firstValidRow(obj)
            % returns the first row where data are not "all missing"
            % Output:
            %   - row: the row name
            %   - ix: the row position
            ix = find(any(~ismissing(obj.data_),2),1);
            row = obj.rows(ix);
        end
        
        function varargout = size(obj,varargin)
            [varargout{1:nargout}] = size(obj.data_,varargin{:});
        end
        function h = height(obj)
            h = length(obj.rows_.value_);
        end
        function w = width(obj)
            w = length(obj.columns_.value_);
        end
        
        function bool = isempty(obj), bool = isempty(obj.data_); end
        function obj = cumsum(obj), obj.data_ = nancumsum(obj.data_); end
        % cumulative sum, takes care of missing values
        function obj = cumprod(obj), obj.data_ = nancumprod(obj.data_); end
        % cumulative product, takes care of missing values
        
        function bool = equals(df1,df2,tol)
            % .equals(df1,df2,tolerance) returns true if the rows_ and columns_
            % are the same, and if the data are equal in the tolerance range
            if nargin<3, tol=eps; end
            try
                assert(isequal(class(df1),class(df2)))
                assert(isequal(df1.rows_,df2.rows_)&&isequal(df1.columns_,df2.columns_))
                iseq = abs(df1.data-df2.data) <= tol;
                bool = all(iseq(:));
            catch
                bool = false;
            end
        end
        
        function bool = isaligned(obj,varargin)
            % ISALIGNED(df1,df2,...[,flags]) returns true if all Frames are aligned. 
            % Add the flag 'rows' or 'columns' to check alignment in only one direction. 
            [checkRows,varargin] = parseFlag('rows',varargin);
            [checkCols,varargin] = parseFlag('columns',varargin);
            if ~any([checkCols,checkRows])
                checkCols = true; checkRows = true;
            end
            bool = true;
            if checkRows
                row = obj.rows;
                for v = varargin
                    bool = isequaln(row,v{1}.rows);
                    if ~bool; return; end
                end
            end
            if checkCols
                col = obj.columns;
                for v = varargin
                    bool = isequaln(col,v{1}.columns);
                    if ~bool; return; end
                end
            end
        end
        
        % these function overloads are to make chaining possible
        % e.g. df.abs().sqrt()   [or without chaining, e.g. sqrt(abs(df)) ]
        
        % exponents and logarithms
        function obj = exp(obj), obj.data_ = exp(obj.data_); end
        function obj = expm1(obj), obj.data_ = expm1(obj.data_); end       
        function obj = log(obj), obj.data_ = log(obj.data_); end
        function obj = log10(obj), obj.data_ = log10(obj.data_); end
        function obj = log1p(obj), obj.data_ = log1p(obj.data_); end
        function obj = log2(obj), obj.data_ = log2(obj.data_); end
        function obj = nextpow2(obj), obj.data_ = nextpow2(obj.data_); end
        function obj = pow2(obj), obj.data_ = pow2(obj.data_); end
        function obj = reallog(obj), obj.data_ = reallog(obj.data_); end
        function obj = realsqrt(obj), obj.data_ = realsqrt(obj.data_); end
        function obj = sqrt(obj), obj.data_ = sqrt(obj.data_); end
        
        % trigonometric functions
        function obj = sin(obj), obj.data_ = sin(obj.data_); end
        function obj = sind(obj), obj.data_ = sind(obj.data_); end
        function obj = sinpi(obj), obj.data_ = sinpi(obj.data_); end
        function obj = asin(obj), obj.data_ = asin(obj.data_); end
        function obj = asind(obj), obj.data_ = asind(obj.data_); end
        function obj = sinh(obj), obj.data_ = sinh(obj.data_); end
        function obj = asinh(obj), obj.data_ = asinh(obj.data_); end
        
        function obj = cos(obj), obj.data_ = cos(obj.data_); end
        function obj = cosd(obj), obj.data_ = cosd(obj.data_); end
        function obj = cospi(obj), obj.data_ = cospi(obj.data_); end
        function obj = acos(obj), obj.data_ = acos(obj.data_); end
        function obj = acosd(obj), obj.data_ = acosd(obj.data_); end
        function obj = cosh(obj), obj.data_ = cosh(obj.data_); end
        function obj = acosh(obj), obj.data_ = acosh(obj.data_); end
        
        function obj = tan(obj), obj.data_ = tan(obj.data_); end
        function obj = tand(obj), obj.data_ = tand(obj.data_); end
        function obj = atan(obj), obj.data_ = atan(obj.data_); end
        function obj = atand(obj), obj.data_ = atand(obj.data_); end        
        function obj = tanh(obj), obj.data_ = tanh(obj.data_); end
        function obj = atanh(obj), obj.data_ = atanh(obj.data_); end
        
        function obj = csc(obj), obj.data_ = csc(obj.data_); end
        function obj = cscd(obj), obj.data_ = cscd(obj.data_); end
        function obj = acsc(obj), obj.data_ = acsc(obj.data_); end
        function obj = acscd(obj), obj.data_ = acscd(obj.data_); end        
        function obj = csch(obj), obj.data_ = csch(obj.data_); end
        function obj = acsch(obj), obj.data_ = acsch(obj.data_); end
                 
        % complex number functions
        function obj = abs(obj), obj.data_ = abs(obj.data_); end
        function obj = angle(obj), obj.data_ = angle(obj.data_); end
        function obj = conj(obj), obj.data_ = conj(obj.data_); end
        function obj = imag(obj), obj.data_ = imag(obj.data_); end        
        function obj = real(obj), obj.data_ = real(obj.data_); end
        function obj = sign(obj), obj.data_ = sign(obj.data_); end
        function obj = unwrap(obj), obj.data_ = unwrap(obj.data_); end
        
        % error functions
        function obj = erf(obj), obj.data_ = erf(obj.data_); end
        function obj = erfc(obj), obj.data_ = erfc(obj.data_); end
        function obj = erfcinv(obj), obj.data_ = erfcinv(obj.data_); end
        function obj = erfcx(obj), obj.data_ = erfcx(obj.data_); end
        function obj = erfinv(obj), obj.data_ = erfinv(obj.data_); end
        
        % test functions
        function obj = isinf(obj), obj.data_ = isinf(obj.data_); end
        function obj = isfinite(obj), obj.data_ = isfinite(obj.data_); end
        function obj = isnan(obj), obj.data_ = isnan(obj.data_); end
        function obj = ismissing(obj,varargin), obj.data_ = ismissing(obj.data_,varargin{:}); end
        
        % rounding
        function obj = floor(obj), obj.data_ = floor(obj.data_); end
        function obj = ceil(obj), obj.data_ = ceil(obj.data_); end
        function obj = fix(obj), obj.data_ = fix(obj.data_); end
        function obj = round(obj), obj.data_ = round(obj.data_); end
        
        % other functions        
        function obj = oneify(obj)
        % replace non missing values by a default value (1 for double, "" for strings)
            switch class(obj.data_)
                case 'double'
                    v = 1;
                case 'string'
                    v = "";
                otherwise
                    error('Default value not implemented for %s.', class(obj.data_))
            end
            obj.data_(~ismissing(obj.data_)) = v;
        end
        
        function other = sum(obj,varargin), other=obj.aggregateMatrix(@sum,true,1,false,varargin{:}); end
        % SUM sum through the desired dimension, returns a series
        function other = mean(obj,varargin), other=obj.aggregateMatrix(@mean,true,1,false,varargin{:}); end
        % MEAN mean through the desired dimension, returns a series
        function other = median(obj,varargin), other=obj.aggregateMatrix(@median,false,1,false,varargin{:}); end
        % MEDIAN median through the desired dimension, returns a series
        function other = std(obj,varargin), other=obj.aggregateMatrix(@std,true,2,true,varargin{:}); end
        % STD standard deviation through the desired dimension, returns a series
        function other = var(obj,varargin), other=obj.aggregateMatrix(@var,true,2,true,varargin{:}); end
        % VAR variance through the desired dimension, returns a series
        function other = any(obj,varargin), other=obj.aggregateMatrix(@any,false,1,true,varargin{:}); end
        % ANY 'any' function through the desired dimension, returns a series
        function other = all(obj,varargin), other=obj.aggregateMatrix(@all,false,1,true,varargin{:}); end
        % ALL 'all' function through the desired dimension, returns a series                      
        function varargout = max(obj,varargin), [varargout{1:nargout}]=obj.aggregateMatrixMaxMin(@max,true,2,true, varargin{:}); end
        % MAX maximum through the desired dimension, returns a series        
        function varargout = min(obj,varargin), [varargout{1:nargout}]=obj.aggregateMatrixMaxMin(@min,true,2,true, varargin{:}); end        
        % MIN minimum through the desired dimension, returns a series
        function other = maxOf(df1,df2), other=operatorElementWise(@max,df1,df2); end
        % maximum of the elements of the two input arguments
        % maxOf(df1,df2), where df2 can be a frame or a matrix
        function other = minOf(df1,df2), other=operatorElementWise(@min,df1,df2); end
        % minimum of the elements of the two input arguments
        % minOf(df1,df2), where df2 can be a frame or a matrix
        
        function other = corr(obj), other=corrcov(obj,@corrcoef,Rows='pairwise'); end
        % correlation matrix (pairwise)
        function other = cov(obj), other= corrcov(obj,@cov,'partialRows'); end
        % covariance matrix (pairwise)
        
        function obj = nansum(obj,varargin)
            %NANSUM (df1,df2,df3,...) sums DataFrames. NaNs are treated as zeros or NaNs: a+NaN=a, NaN+NaN=NaN 
            d = cell(1,length(varargin));
            i = 0;
            for v_ = varargin
                v = v_{1};
                i = i+1;
                if isFrame(v)
                    assert(isequal(obj.rows,v.rows)&&isequal(obj.columns,v.columns), ...
                        'frames:nansum:notAligned','Frames must be aligned.')
                    d{i} = v.data;
                else
                    assert(isequal(size(obj),size(v)), ...
                        'frames:nansum:differentSize','Data must be of the same size.')
                    d{i} = v;
                end                
            end
            d = cat(3,obj.data,d{:});
            s = sum(d,3,'omitnan');
            isn = all(isnan(d),3);
            s(isn) = NaN;
            obj.data_ = s;
        end
                               
        function obj = groupDuplicate(obj, func, indexType, funcAggrDim, apply2single, convGroupInd) 
            % combine duplicate index values by aggregation function
            %
            %  input: 
            %    indexType:     select index: "rows", 1,  "columns", 2, "both", 3
            %    func:          function handler (default @mean)
            %    funcAggrDim:   aggregation dimensions of func: 1 (default, rows), 2 (columns)
            %    apply2single:  logical, apply function to groups with only single value (default false)
            %    convGroupInd:  convert output of func which is local group position index to absolute pos index
            %
            %  output:
            %     dataframe/series with duplicate index values aggregated
            %            
            if nargin<2, func=@mean; end            
            if nargin<3, indexType="rows"; end
            if nargin<4, funcAggrDim=1; end
            if nargin<5, apply2single=false; end  
            if nargin<6, convGroupInd=false; end
            if isnumeric(indexType) && ismember(indexType,[1,2,3]), dim=indexType;
            elseif indexType=="rows", dim=1;
            elseif indexType=="columns", dim=2;
            elseif indexType=="both", dim=3;
            else
                error("Invalid indexType parameter. Allowed 'rows', 1,'columns', 2, or 'both',3."); 
            end                    
            % aggregate rows
            if dim==1 || dim==3
                groupid = obj.rows_.value_uniqind;
                [datnew, ~, ~, groupInd] = groupsummaryMatrixFast(obj.data_, groupid, func, dim, ...
                                                                  funcAggrDim, apply2single, true, convGroupInd);                
                indexnew = obj.rows_.getSubIndex(groupInd);
                obj.data_ = datnew;
                obj.rows_ = indexnew;
            end            
            % aggregate columns
            if dim==2 || dim==3
                groupid = obj.columns_.value_uniqind;
                [datnew, ~, ~, groupInd] = groupsummaryMatrixFast(obj.data_, groupid, func, dim, ...
                                                                  funcAggrDim, apply2single, true, convGroupInd);                
                indexnew = obj.columns_.getSubIndex(groupInd);
                obj.data_ = datnew;
                obj.columns_ = indexnew;            
            end
        end
        
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
            %   - Halflife: specify decay in terms of half-life, alpha=1-exp(log(0.5)./halflife);
            %
            % See also frames.internal.ExponentiallyWeightedMoving
            obj=frames.internal.ExponentiallyWeightedMoving(obj,type,value);
        end        
        
        % ToDo rewrite subsref and subsasgn using the new tools when Matlab
        % release them
        function varargout = subsref(obj,s)
            if length(s)>1  % when there are several subsref
                if strcmp(s(1).type,'.')
                     field = string(s(1).subs);                                        
                     if ismember(field, ["rows","columns"])
                        % allow custom data access of index values as implemented in Index class subsref                        
                        s(1).subs = "value"; % field to access in Index object is called 'value'
                        [varargout{1:nargout}] = subsref(obj.(field+"_"), s);                        
                        if field=="columns"
                            % transpose output in case of columns                            
                            varargout{1} = varargout{1}';
                        end
                     else                       
                        [varargout{1:nargout}] = builtin('subsref',obj,s);
                     end    

                else  % to handle the () and {} cases (Matlab struggles otherwise).
                    other = subsref(obj,s(1));
                    [varargout{1:nargout}] = subsref(other,s(2:end));
                end
                return
            end
            
            nargoutchk(0,1)
            switch s.type
                case '()'
                    [row,col] = getSelectorsFromSubs(s.subs);
                    varargout{1} = obj.loc(row,col);
                case '{}'
                    [row,col] = getSelectorsFromSubs(s.subs);
                    varargout{1} = obj.iloc(row,col);
                case '.'
                    varargout{1} = obj.(s.subs);
            end
        end

        
        function obj = subsasgn(obj,s,b)
            % assign values to dataframe by indexing: (),{},loc,iloc,col,row operations            
            switch s(1).type
                case {'()','{}'}
                    if length(s)>1
                        error("Nested assign in combination with %s indexing operator not supported", s(1).type)
                    end
                    positionRows = (s(1).type=="{}");
                    obj = assignDataToSelection(obj, s(1).subs, positionRows, b);
                case '.'
                    field = string(s(1).subs);
                    
                    if ismember(field, ["rows","columns"])
                        % assign rows/ column (with/without) indexing
                        if length(s)>2
                            error("Nested assign of .%s in combination with () indexing not supported", field)
                        end
                        assert(~isempty(b), 'frames:rowsValidation:mustBeNonempty', ...
                            "assignment of %s not allowed to be empty", field);                        
                        if length(s)==1
                            obj.(field) = b;
                        else                            
                            obj.(field+"_").value(s(2).subs{:}) = b;
                        end
                        
                    elseif isprop(obj,field)
                        % assign to object property
                        obj = builtin('subsasgn',obj,s,b);
                        
                    elseif ismember(field, ["loc","iloc"])                        
                         % assign to iloc() or loc() indexing
                         if length(s)==1
                             error("No arguments given for .%s()", field);
                         elseif length(s)>2
                             error("Nested assign in combination with .%s() indexing not supported", field);
                         end
                         positionRows = (field=="iloc");
                         obj = assignDataToSelection(obj, s(2).subs, positionRows, b);
                         
                    elseif ismember(field, ["row","col"])
                        % assign to row/col series
                        selector = s(2).subs{1};
                        if strcmp(field, "row")                            
                            if ~obj.rows_.ismember(selector)
                                obj = obj.extendRows(selector);
                            end
                            assert(length(obj.rows_.positionOf(selector))==1, ...
                                'frames:subsasgn:rowMultiple', ...
                                'assignment with .row requires to change only a single unique row.');
                            obj = obj.modify(b,selector,':',false);                            
                        else
                            if ~obj.columns_.ismember(selector)
                                obj = obj.extendColumns(selector);
                            end
                            assert(length(obj.columns_.positionOf(selector))==1, ...
                                'frames:subsasgn:colMultiple', ...
                                'assignment with .col requires to change only a single unique column.');
                            obj = obj.modify(b,':',selector,false);
                        end
                        
                    else                       
                        error(('''%s'' is not a public property of the ''%s'' class.'),s(1).subs,class(obj));
                    end
            end
            
            function obj = assignDataToSelection(obj, subs, positionIndex, data)
                % assign data to DataFrame values selection based on subs selectors
                if isLogicalSelector2D(subs{1})
                    % special case: combined logical indexing of rows and columns (2d logical selector)
                    assert( length(subs)==1, 'frames:subsasgn:OnlySingleIndexAllowed2DBool' , ...
                        'Only single selector allowed in case of 2D logical');
                    obj = obj.modifyFromBool2D(data, subs{1});
                else
                    % normal indexing with seperate rows and cols
                    [row,col] = getSelectorsFromSubs(subs);
                    obj = obj.modify(data, row, col, positionIndex);
                end
            end
            function bool = isLogicalSelector2D(index)
                bool = (isFrame(index) && ~index.colseries && ~index.rowseries) || ...
                       (islogical(index) && ~isvector(index));
            end
        end
                
        function toFile(obj,filePath,varargin)
            % write the frame into a file
            assert(~isMultiIndex(obj.rows_) && ~isMultiIndex(obj.columns_), ...
                'frames:DataFrame:toFile:MultiIndexNotSupported', "DataFrame with MultiIndex (currently) not supported");               
            writetable(obj.t,filePath, ...
                'WriteRowNames',true,'WriteVariableNames',true,varargin{:});
        end   
        
        
        function [dat, dimnames, dimvalues] = dataND(obj)
            % function to convert dataframe data to matlab NDarray
            % based on the (Multi)Index dimensions
            %                   
            % Remark:
            %  - No duplicate index values are allowed in case of more than 1 dimension.
            %  - Missing values will be set to NaN. 
            %
            % output:
            %   dat:       NDarray with dimensions as in dataframe
            %   dimnames:  string array with names of dimensions
            %   dimvalues: cell array with per dimension the unique values allong the axes
            %
            assert(obj.rows_.Ndim==1 || obj.rows_.isunique(), ...
                'frames:DataFrame:dataND:rowsIndexNotUnique', ...      
                "Rows index not unique. Non-unique index only allowed in case of only single dimension.");
            assert(obj.columns_.Ndim==1 || obj.columns_.isunique(), ...
                'frames:DataFrame:dataND:columnsIndexNotUnique', ...      
                "Columns index not unique. Non-unique index only allowed in case of only single dimension.");                        
            % get dim length and position into NDarray for both dataframe indices
            [Ldim_rows, posind_rows] = getNDposind(obj.rows_);
            [Ldim_cols, posind_cols] = getNDposind(obj.columns_);
            % create empty data vector of full length
            Nelem_rows = prod(Ldim_rows);            
            Nelem_cols = prod(Ldim_cols);
            dat = obj.defaultData(Nelem_rows*Nelem_cols,1);
            % get row-major position index (of both row and column index combined)                                                
            posind = posind_rows + (posind_cols'-1) * Nelem_rows; % use implicit expansion
            % assign values to 'NDarray  vector'
            dat(posind) = obj.data_;
            % reshape vector to ND array
            Ndims_rows = length(Ldim_rows);
            Ndims_cols = length(Ldim_cols);            
            Ndims = Ndims_rows + Ndims_cols;
            if Ndims>1                
               dat = reshape(dat, [Ldim_rows, Ldim_cols]);
            end
            % get dimension meta data
            dimnames = [];            
            dimvalues = [];
            if ~obj.rows_.singleton
                dimnames = [dimnames obj.rows_.name];
                dimvalues = [dimvalues obj.rows_.value_uniq];                
            end
            if ~obj.columns_.singleton
                dimnames = [dimnames obj.columns_.name];
                dimvalues = [dimvalues obj.columns_.value_uniq];
            end            
            
            function [Ldim, posind] = getNDposind(index)
                % helper function to get length of each dimension and position index into NDarray
                if index.singleton
                   Ldim = [];
                   posind = 1;
                elseif index.Ndim > 1
                   Ldim = cellfun( @(x) length(x), index.value_uniq);               
                   posind = index.getvalue_uniqind(false); % false=row-major ordering
                else
                   Ldim = length(index);
                   posind = (1:Ldim)';
                end
            end
        end
        
      
        
    end
    
    methods(Hidden)  % Hidden and not protected, so that other classes in the package can use these methods, without the need to explicitly give them access. Not to be used outside.
        
         function obj = loc_(obj,rowSelector,colSelector,userCall,positionIndex,asFilter)            
            if nargin < 4, userCall=false; end
            if nargin < 5, positionIndex=false; end             
            if nargin < 6, asFilter=false; end
            rowID = obj.rows_.getSelector(rowSelector, positionIndex, 'onlyColSeries', userCall, asFilter);
            colID = obj.columns_.getSelector(colSelector, positionIndex, 'onlyRowSeries', userCall, asFilter);              
            if ~iscolon(rowSelector)
                obj.rows_ = obj.rows_.getSubIndex(rowID);
            end
            if ~iscolon(colSelector)                                
                obj.columns_ = obj.columns_.getSubIndex(colID);
            end
            obj.data_ = obj.data_(rowID,colID);
         end
         
         function obj = iloc_(obj,rowPosition,colPosition)
            obj = obj.loc_(rowPosition, colPosition, false, true); 
         end
    end
         
    methods(Hidden, Access=protected)
        
        function tb = getTable(obj)
            row = obj.rows_.getValueForTable();
            col = obj.columns_.getValueForTable();
            tb = array2table(obj.data,RowNames=row,VariableNames=col);
        end
        function d = defaultData(obj,lengthRows,lengthColumns,type)
            if nargin<4; type = class(obj.data); end
            d = repmat(missingData(type),lengthRows,lengthColumns);
        end
        function rowsValidation(obj,value)
            assert(iscell(value) || length(value) == size(obj.data,1), 'frames:rowsValidation:wrongSize', ...
                'rows does not have the same size as data')
        end
        function columnsValidation(obj,value)
            assert(length(value) == size(obj.data,2), 'frames:columnsValidation:wrongSize', ...
                'columns do not have the same size as data')
        end
        function row = getRowsObject(~,rows,varargin)
            row = frames.Index(rows,varargin{:},Unique=true);
            row.name = "Row";  % to be consistent with 'table' in which the default name of the rows is 'Row'
        end
        function col = getColumnsObject(~,columns,varargin)
            col = frames.Index(columns,varargin{:});
        end

        function obj = modify(obj,data,rows,columns,positionIndex)
            % modify data in selected rows and columns to supplied values
            if nargin<5; positionIndex = false; end
            row = obj.rows_.getSelector(rows, positionIndex, 'onlyColSeries', true);
            col = obj.columns_.getSelector(columns, positionIndex, 'onlyRowSeries', true);                     
            % get data from DataFrame
            if isFrame(data)
                rowsColChecker(obj.iloc_(row,col).asFrame(), data);
                data = data.data_;
            end            
            sizeDataBefore = size(obj.data_);
            % update values with data (in case of size mismatch, error will be generated by matlab)
            obj.data_(row,col) = data;
            % check data dimensions after update (to handle too large logical array or out of range position index)
            badIndexing = size(obj.data_) > sizeDataBefore;
            if badIndexing(1)
                error('frames:modify:badIndex','Row index exceeds frame dimensions')
            elseif badIndexing(2)
                error('frames:modify:badColumns','Column index exceeds frame dimensions')
            end
            % handle indexes in case of deletion of data
            if isequal(data,[])
                if iscolon(columns)
                    % matrix(:,:)=[] returns a 0xN matrix, so if both rows
                    % and columns are empty, keep the columns
                    if iscolon(rows)
                         % vector(1:end) returns an 0x1 empty vector of the
                         % same class, while vector(:) returns []
                         row = true(length(obj.rows_),1);
                    end
                    obj.rows_.value(row) = [];
                else
                    obj.columns_.value(col) = [];
                end
            end
        end
                      
        function obj = modifyFromBool2D(obj, data, bool2d)
            % modify selected data by 2D logical (matrix or logical dataframe) to supplied data            
            assert(~isempty(data), 'frames:modifyFromBool2D:mustBeNonempty', ...
                    'Data not allowed to be empty.')                
            if isFrame(bool2d)
                % logical DataFrame selector 
                assert(islogical(bool2d.data_),'frames:modifyFromBool2D:needLogical', ...
                    'The selector must be a logical.')                
                rowsColChecker(obj.asFrame(),bool2d);
                obj.data_(bool2d.data_) = data;
            elseif islogical(bool2d)
                % logical matrix selector
                assert( all(size(bool2d)==size(obj.data_)), 'frames:modifyFromBool2D:WrongSize', ...
                    'Logical matrix used as mask not same size as DataFrame');
                obj.data_(bool2d) = data;
            else
                error('Unsupported first selector type: need logical DataFrame or logical matrix');                             
            end
        end 
        
        function [out, ind] = aggregateMatrixMaxMin(obj, func, addOmitNaNflag, funcDimPos, apply2singleValue, varargin)
            % internal wrapper function around aggregateMatrix() to support min() and max() index outputs            
            if nargout <2
                % only aggregated output, no position index
                out = obj.aggregateMatrix(func, addOmitNaNflag, funcDimPos, apply2singleValue, varargin{:});
            else
                % both aggregated as position index output
                [out, dim, indpos] = obj.aggregateMatrix(func, addOmitNaNflag, funcDimPos, apply2singleValue, varargin{:});               
                if dim == 1
                    dimindex = obj.rows;
                else
                    dimindex = obj.columns;
                end
                if isFrame(indpos)
                   ind = dimindex(indpos.data);
                else
                   ind = dimindex(indpos);
                end                                        
            end                
        end
        
        function varargout = aggregateMatrix(obj, func, addOmitNaNflag, funcDimPos, apply2singleValue, varargin)
            % internal wrapper function to support aggregation by standard matlab function (eg. mean) 
            % using multiple syntax options. 
            % 
            % call syntax (<>=optional): 
            %    funcname( <dim>, <dimname>) or
            %    funcname( dim, <dimname>, <numeric function argument> ) 
            %
            % syntax examples with std():
            %    df.std():             aggregate rows
            %    df.std(1):            aggregate rows
            %    df.std("rows"):       aggregate rows
            %    df.std(2):            aggregate columns
            %    df.std("columns"):    aggregate columns
            %    df.std("x"):          aggregate subdim "x" in rows (default)
            %    df.std(1,"x"):        aggregate subdim "x" in rows
            %    df.std("rows","x"):   aggregate subdim "x" in rows
            %    df.std("rows","x",1): aggregate subdim "x" in rows with extra std() option 1
            %    df.std(2,1):          aggregate columns with extra std() parameter 1
            %
            % input:
            %   func:               function handle to aggregation function
            %   addOmitNaNflag:     boolean to select addtion of 'omitnan' parameter to function
            %   funcDimPos:         position of dimension parameter of function: 1 (eg mean) or 2 (eg std)
            %   apply2singleValue:  boolean to select if function is applied to groups with a single values
            %   varargin:           other additional function parameters (only non string paramters supported)
            %
            % output:
            %    aggregated data:
            %        dataframe with aggregated data and reduced dimensions or
            %        series/scalar (in case aggregation over full index) or            
            %    dim:  
            %         int, dimension of aggregation (1=rows,2=cols)
            %    varargout:
            %         additional outputs from function  func() (eg. pos index in case of min() or max())
            %             
            dimname = [];
            if isempty(varargin), varargin = {1}; end % default dim is rows            
            
            % parse 1st input argument (dim or row dimname)
            p1 = varargin{1};
            if isequal(p1,1) || isequal(p1,"rows")
                dim = 1;
            elseif isequal(p1,2) || isequal(p1,"columns")
                dim = 2;
            elseif isstring(p1) || ischar(p1)
                % interpret it as specific row dimension name
                dim = 1;
                dimname = p1;                
            else
                error('frames:aggregateMatrix:invalidsyntax', "invalid first argument '%s'.", p1);
            end
            % parse 2nd input argument (dimname or extra function param)
            if length(varargin)>=2
                p2 = varargin{2};
                if  istext(p2)
                    % interpret it as row or column dimension name
                    assert(isempty(dimname), 'frames:aggregateMatrix:invalidsyntax', ...
                       "invalid 2nd parameter. First parameter ('%s') already defined row dimname, " + ... 
                       "second string parameter ('%s') not allowed.",p1, p2);
                    dimname = p2;                    
                    varargin(2) = []; %remove item: only keep (optional) function parameters
                end
                if length(varargin)>=3
                    assert( ~any(cellfun(@istext,varargin(3:end))), 'frames:aggregateMatrix:invalidsyntax', ...
                       "error, no string parameters are allowed as function arguments (to avoid ambiguous syntax).");
                end                
            end
            varargin(1) = []; %remove item: only keep (optional) function parameters
            
            % in case of colon operator, do not specify a dimname
            if ~isempty(dimname) && iscolon(dimname)                
                dimname = [];
            end
            
            % get function params (to force selected dimension) + NaNsettings
            if funcDimPos==1
                params = [dim varargin];
            elseif funcDimPos==2
                if ~isempty(varargin)
                    params = { varargin{1} dim varargin{2:end} };
                else
                    params = { [] dim};
                end
            end
            if addOmitNaNflag
                params{end+1} = 'omitnan';
            end
            
            % get function including params
            if isempty(params)
                func_ = func;
            else
                func_ = @(x) func(x, params{:});
            end
            
            % call function to apply aggregation
            nargout_func = max(1,nargout-1); % number of functions output to collect
            if isempty(dimname)                                
                [out{1:nargout_func}] = obj.matrix2series_(dim, func_, dim);                    
            else
                [out{1:nargout_func}] = obj.aggregateIndexDim_(dim, dimname, func_, dim, apply2singleValue);
            end
            
            % collect variable outputs
            varargout{1} = out{1};
            if nargout>1, varargout{2} = dim; end
            if nargout>2, varargout{3:3+nargout_func-2} = out{2:nargout_func}; end
        end
        
        
        function varargout = aggregateIndexDim_(obj, dim, dimname, func, funcAggrDim, apply2singleValue)
            % internal function to aggregate data over given sub-dimension (in case of MultiIndex)            
            %
            % input:
            %    dim:          dimensions to aggregate: 1 (default, rows), 2 (columns)
            %    dimname:      string (or string array) of sub-dimensions to aggregate
            %    func:         function handle to aggregation function      
            %    funcAggrDim:  dimension in which function func aggregates (1:rows default, 2=columns)
            %    apply2single: boolean to select if function is applied to groups with a single values (default true)             
            %
            % output:
            %    - dataframe/series with aggregated data and reduced (MultiIndex) dimensions
            %    - (optional) dataframe/series with index position from 2nd func output (eg func min() or max())
            %                               
            if nargin<5, funcAggrDim=1; end
            if nargin<6, apply2singleValue=true; end
            assert(dim==1 || dim==2,'dimension value must be in [1,2]');
            assert(nargout<3, "only up to 2 function outputs supported.");
            
            % get index and dimension to keep
            indexfields = ["rows_", "columns_"];
            indexobj = obj.(indexfields(dim));
            assert(isMultiIndex(indexobj), "Only MultiIndex supported, selected index is not a MultiIndex.");
            dimind = indexobj.getDimInd(dimname);
            dimind_other = setxor( 1:indexobj.Ndim, dimind);
            
            if ~isempty(dimind_other)
                % df with removed dimension
                indexobj_raw = indexobj.getSubIndex_(:,dimind_other);
                obj.(indexfields(dim)) = indexobj_raw;
                
                % get aggregated df
                varargout{1} = obj.groupDuplicate(func, dim, funcAggrDim, apply2singleValue);
                % extra func outputs not supported by groupDuplicate(), workaround by running multiple times                
                if nargout==2
                    % 2nd output is assumed to be position index
                    varargout{2} = obj.groupDuplicate(@func_out2, dim, funcAggrDim, apply2singleValue, true);                
                end
                
            else
                % no sub-dimensions left, use function that aggregates full dimension
                [varargout{1:nargout}] = obj.matrix2series_(dim, func, funcAggrDim);
            end
            
            function out = func_out2(varargin)
                % get 2nd output argument of function func
                [~, out] = func(varargin{:});
            end            
        end
        
        
        function varargout = matrix2series_(obj, dim, func, funcAggrDim)
            % internal function to handle aggregation over full index
            % (convert dataframe to series, or series to scalar)
            % 
            % input:
            %    dim:         dimensions to aggregate: 1 (default, rows), 2 (columns)
            %    func:        function handle to aggregation function      
            %    funcAggrDim: dimension in which function func aggregates (1:rows default, 2=columns)
            %
            % output:
            %    series (in case of dataframe input) or
            %    scalar (in case of series input)
            %
            if nargin<4, funcAggrDim=1; end
            assert(dim==1 || dim==2,'dimension value must be in [1,2]');               
            
            % aggregate over selected dimension
            if dim==funcAggrDim
               [varargout{1:nargout}] = func(obj.data_);
            else
               [varargout{1:nargout}] = func(obj.data_')';
            end
            
            % prepare output
            if (dim==1 && obj.columns_.singleton_) || (dim==2 && obj.rows_.singleton_)
                % returns a scalar if the operation is done on a series
                %series = res;
            else
                varargout{1} = obj.df2series(varargout{1},dim);
            end
        end
                
        
        function obj = df2series(obj,data,dim)
            if dim == 1
                if obj.colseries
                    obj = data;
                else
                    obj.data_ = data;
                    obj.rows_ = obj.rows_.getSubIndex(1);
                    obj.rows_.singleton = true;
                end
            else
                if obj.rowseries
                    obj = data;
                else
                    obj.data_ = data;                    
                    obj.columns_ = obj.columns_.getSubIndex(1);
                    obj.columns_.singleton = true;
                end
            end
        end
        
        function other = corrcov(obj,fun,varargin)
            d = fun(obj.data_,varargin{:});
            other = frames.DataFrame(d,obj.columns,obj.columns,Name=obj.name_);
        end
        
        function varargout = tableFunctions(obj,fun,outputClass,varargin)
            if isempty(outputClass)
                outputClass = split(class(obj),'.');
                outputClass = outputClass{2};
            end
            [varargout{1:nargout}] = fun(obj.t,varargin{:});
            if ~ismissing(outputClass)
                datetype = varfun(@class,varargout{1},'OutputFormat','cell');
                if all(strcmp(datetype,datetype{1}))
                    varargout{1} = frames.(outputClass).fromTable(varargout{1},Unique=false);
                end
            end
        end
        
        function df = reorder(obj, rowindex, rowind, colindex, colind )
            % internal function to reordered DF based on new index objects and position index
            % (rowind and colind are allowed to have NaN, the corresponding values are set NaN)
            %
            if nargin<3, error("not enough parameters"); end            
            if nargin==4, error("invalid number of parameters"); end                        
            if nargin<5, colindex=[]; colind=[]; end            
            df = obj;            
            % set new indexes
            if ~isempty(rowindex),  df.rows_ = rowindex;  end
            if ~isempty(colindex),  df.columns_ = colindex; end            
            % get selector
            if ~isempty(rowind)
                rowmask = ~isnan(rowind);
                rowind_masked = rowind(rowmask);
            else
                rowmask = ':';
                rowind_masked = ':';
            end                        
            if ~isempty(colind)
                colmask = ~isnan(colind);
                colind_masked = colind(colmask);
            else
                colmask = ':';
                colind_masked = ':';
            end                        
            % get reordered data and store in dataframe
            datsize = [length(rowindex) length(colindex)];
            if isnumeric(obj.data_)
                dat = nan(datsize);
            elseif isstring(obj.data_)
                dat = strings(datsize);
            elseif iscell(obj.data_)
                dat = cell(datsize);
            end
            dat(rowmask,colmask) = obj.data_( rowind_masked, colind_masked);
            df.data_ = dat;
        end
                
        function [dfnew1,dfnew2, rowmask, colmask] = getAlignedDFs(df1,df2, alignMethod, allowDimExpansion, dofillmissing)
            % internal function to get aligned DF for element wise operation
            %
            if nargin<3, alignMethod="strict"; end
            if nargin<4, allowDimExpansion=true; end
            if nargin<5, dofillmissing=true; end
            % convert indices of 1st dataframe to multi index if required
            if ~isMultiIndex(df1.rows_) && isMultiIndex(df2.rows_)
                df1.rows_ = frames.MultiIndex(df1.rows_);
            end
            if ~isMultiIndex(df1.columns_) && isMultiIndex(df2.columns_)
                df1.columns_ = frames.MultiIndex(df1.columns_);
            end            
            % get aligned indices
            [mrow, rowind1, rowind2] = df1.rows_.alignIndex(df2.rows_, alignMethod, allowDimExpansion);
            [mcol, colind1, colind2] = df1.columns_.alignIndex(df2.columns_, alignMethod, allowDimExpansion);
            rowmask = ~isnan(rowind1) & ~isnan(rowind2);
            colmask = ~isnan(colind1) & ~isnan(colind2);                 
            dfnew1 = df1.reorder(mrow, rowind1, mcol, colind1);
            dfnew2 = df2.reorder(mrow, rowind2, mcol, colind2);            
            if dofillmissing
                % fill missing rows by values of other dataframe  
                if any(isnan(rowind1))
                   dfnew1.data_(isnan(rowind1),~isnan(colind2)) = dfnew2.data_(isnan(rowind1),~isnan(colind2));
                end
                if any(isnan(rowind2))
                   dfnew2.data_(isnan(rowind2),~isnan(colind1)) = dfnew1.data_(isnan(rowind2),~isnan(colind1));                
                end
                if any(isnan(colind1))                    
                   dfnew1.data_(~isnan(rowind2),isnan(colind1)) = dfnew2.data_(~isnan(rowind2),isnan(colind1));
                end
                if any(isnan(colind2))
                   dfnew2.data_(~isnan(rowind1),isnan(colind2)) = dfnew1.data_(~isnan(rowind1),isnan(colind2));                
                end
            end
        end
                
       
        
    end
 
    methods(Static)
        function df = empty(type,varargin)
            % constructor for an empty frame, specifying the data type of
            % the rows. 'type' takes a value in ["double","string","datetime"]
            arguments
                type {mustBeTextScalar, mustBeMember(type,["double","string","datetime"])} = 'double'
            end
            arguments(Repeating)
                varargin
            end
            switch type
                case 'double'
                    row = double.empty(0,1);
                case 'string'
                    row = string.empty(0,1);
                case 'datetime'
                    row = datetime.empty(0,1); 
            end
            df = frames.DataFrame([],row,[],varargin{:});
        end
        function df = fromFile(filePath, varargin)
            % construct a frame from reading a table from a file
            tb = readtable(filePath,...
                'TreatAsEmpty',{'N/A','NA'}, ...
                'ReadRowNames',true,'ReadVariableNames',true, ...
                varargin{:});
            df = frames.DataFrame.fromTable(tb);
            df.rows_.name = string(tb.Properties.DimensionNames{1});
        end
        function df = fromTable(t,nameValue)
            % construct a frame from a table
            % by default, row and columns names in Matlab's table are
            % cellstr, while in frames they are strings.
            % keepCellstr=false (default) will turn cellstr into strings
            arguments
                t {mustBeA(t,'table')}
                nameValue.keepCellstr (1,1) logical = false
                nameValue.Unique (1,1) logical = true
                nameValue.UniqueSorted (1,1) logical = false                
            end
            cols = t.Properties.VariableNames;
            row = t.Properties.RowNames;
            if ~nameValue.keepCellstr
                cols = string(cols);
                row = string(row);
            end
            if isempty(row), row = []; end
            df = frames.DataFrame(t.Variables,row,cols);
            df.rows_.requireUniqueSorted = nameValue.UniqueSorted;
            df.rows_.requireUnique = nameValue.Unique;
            df.rows_.name = string(t.Properties.DimensionNames{1});
        end
        
        function setDefaultSetting(name, value)
            % change a default (persistent) class settings
            df = frames.DataFrame();
            df.settingsDefault.(name) = value;
        end
        
        function restoreDefaultSettings(obj)
            % restores default settings to 'standard out of the box'
            % (does not change settings of existing DataFrame objects)
            df = frames.DataFrame();
            df.settingsDefault.reset();            
        end
    end
    
    methods(Static, Hidden)
        function fh = getPrivateFuncHandle(funcname)
            % helper function to access private package functions from unit-tester
            % (not to be used in own code)
            fh = str2func(funcname);
        end
    end
    
    methods(Hidden)
        function disp(obj)
            maxRows = 100;
            maxCols = 50;  % Matlab struggles to show many columns
            if all(size(obj) < [maxRows,maxCols])
                try
                    % show content
                    disp(obj.t);               
                    % show row index dimension names
                    if ~obj.rows_.singleton
                       fprintf("row index name(s): %s\n", join(obj.rows_.name,", ") )
                    end
                    if isMultiIndex(obj.columns_) && ~obj.columns_.singleton
                        fprintf("column index name(s): %s\n\n", join(obj.columns_.name,", ") )
                    end
                    % description line
                    line = class(obj);
                    if obj.colseries
                        line = line + " - ColSeries";
                    elseif obj.rowseries
                        line = line + " - RowSeries";                        
                    end
                    disp(line);                    
                catch
                    warning('Table cannot be displayed')
                    details(obj);
                end
            else
                details(obj);
            end
        end
        
        function n = numArgumentsFromSubscript(varargin), n = 1; end
        function e = end(obj,q,~), e = builtin('end',obj.data_,q,2); end
        
        function other = plus(df1,df2)
            other = operatorElementWise(@plus,df1,df2);
        end
        function other = mtimes(df1,df2)
            other = operatorMatrix(@mtimes,df1,df2);
        end
        function other = times(df1,df2)
            other = operatorElementWise(@times,df1,df2);
        end
        function other = minus(df1,df2)
            other = operatorElementWise(@minus,df1,df2);
        end
        function other = mrdivide(df1,df2)
            other = operatorMatrix(@mrdivide,df1,df2);
        end
        function other = rdivide(df1,df2)
            other = operatorElementWise(@rdivide,df1,df2);
        end
        function other = mldivide(df1,df2)
            other = operatorMatrix(@mldivide,df1,df2);
        end
        function other = ldivide(df1,df2)
            other = operatorElementWise(@ldivide,df1,df2);
        end
        function other = power(df1,df2)
            other = operatorElementWise(@power,df1,df2);
        end
        function other = mpower(df1,df2)
            other = operatorMatrix(@mpower,df1,df2);
        end
        
        function other = lt(df1,df2)
            other = operatorElementWise(@lt,df1,df2);
        end
        function other = gt(df1,df2)
            other = operatorElementWise(@gt,df1,df2);
        end
        function other = le(df1,df2)
            other = operatorElementWise(@le,df1,df2);
        end
        function other = ge(df1,df2)
            other = operatorElementWise(@ge,df1,df2);
        end
        function bool = eq(df1,df2)
            if isFrame(df1) && istext(df1.data)
                df1.data = string(df1.data);
            elseif istext(df1)
                df1 = string(df1);
            end
            bool = operatorElementWise(@eq,df1,df2);
        end
        function bool = ne(df1,df2)
            if isFrame(df1) && istext(df1.data)
                df1.data = string(df1.data);
            elseif istext(df1)
                df1 = string(df1);
            end
            bool = operatorElementWise(@ne,df1,df2);
        end
        function other = and(df1,df2)
            other=operatorElementWise(@and,df1,df2);
        end
        function other = or(df1,df2)
            other=operatorElementWise(@or,df1,df2);
        end
        
        function other = ctranspose(obj)
            other = frames.DataFrame(obj.data_',obj.columns_,obj.rows_,Name=obj.name_);
        end
        function other = transpose(obj)
            other = frames.DataFrame(obj.data_.',obj.columns_,obj.rows_,Name=obj.name_);
        end
        
        function obj = uminus(obj), obj.data_ = uminus(obj.data_); end
        function obj = uplus(obj), obj.data_ = uplus(obj.data_); end
        function obj = not(obj), obj.data_ = not(obj.data_); end
    end
    
    methods(Hidden, Static)
        function obj = loadobj(obj)
            try
                obj.rows;
            catch
                warning('An old version of frames was loaded. The "index" property is replaced by "rows" and will be deprecated.')
                descr = obj.description;
                obj = frames.DataFrame(obj.data_,obj.index_,obj.columns_,Name=obj.name_);
                obj.description = descr;
            end
        end
    end
    
    methods(Hidden, Static, Access=protected)
        function row = defaultRows(len)
            row = defaultValue('double',len)';
        end
        function col = defaultColumns(len)
            col = defaultValue('string',len)';
        end
    end
end

%--------------------------------------------------------------------------
function [row, col] = getSelectorsFromSubs(subs)
len = length(subs);
if ~ismember(len, [1,2]); error('Error in reference for rows and columns.'); end
if len==1; col = ':'; else; col = subs{2}; end
row = subs{1};
end

%--------------------------------------------------------------------------
function varargout = getData_(varargin)
for ii = 1:nargout
    v = varargin{ii};
    if isFrame(v), v=v.data_; end
    varargout{ii} = v; %#ok<AGROW>
end
end

%--------------------------------------------------------------------------
function [row_,col_,df] = matrixOpHandler(df1,df2)
df = df1;
if isFrame(df2)
    if isFrame(df1)
        assert((df1.colseries && df2.rowseries) || isequal(df1.columns_.value,df2.rows_.value), ...
            'frames:matrixOpHandler:notAligned','Frames are not aligned!')
        row_ = df1.rows_;
        col_ = df2.columns_;
    else
        if size(df1,2)>1 && size(df1,2) == length(df2.rows_) ...
                || size(df1,1) > length(df2.rows_) && length(df2.rows_) == 1
            row_ = df2.getRowsObject(df2.defaultRows(size(df1,1)));
        else
            row_ = df2.rows_;
        end
        col_ = df2.columns_;
        df = df2;
    end
else
    row_ = df1.rows_;
    if size(df2,1) == length(df1.columns_) && size(df2,1)>1 ...
            || size(df2,2) > length(df1.columns_) && length(df1.columns_) == 1
        col_ = df1.getColumnsObject(df1.defaultColumns(size(df2,2)));
    else
        col_ = df1.columns_;
    end
end
end

%--------------------------------------------------------------------------
function [row_,col_,df] = elementWiseHandler(df1,df2)
df = df1;
if isFrame(df2)
    if isFrame(df1)
        rowsColChecker(df1,df2);
        
        row_ = df1.rows_;
        if size(df2,1)>size(df1,1), row_ = df2.rows_; end
        col_ = df1.columns_;
        if size(df2,2)>size(df1,2), col_ = df2.columns_; end
    else
        row_ = df2.rows_;
        col_ = df2.columns_;
        df = df2;
    end
else
    row_ = df1.rows_;
    col_ = df1.columns_;
end
end

%--------------------------------------------------------------------------
function rowsColChecker(df1,df2)
if ~df1.rows_.singleton_ && ~df2.rows_.singleton_
    assert(isequal(df1.rows_.value_,df2.rows_.value_), ...
        'frames:elementWiseHandler:differentRows','Frames have different indices!')
end
if ~df1.columns_.singleton_ && ~df2.columns_.singleton_
    assert(isequal(df1.columns_.value_,df2.columns_.value_), ...
        'frames:elementWiseHandler:differentColumns','Frames have different columns!')
end
end

%--------------------------------------------------------------------------

function df = operatorMatrix(fun, df1, df2)
   % internal function to perform matrix operations between on two DataFrames
   [row_,col_,df] = matrixOpHandler(df1,df2);
   [v1,v2] = getData_(df1,df2);
   d = fun(v1,v2);
   df.data_ = d; df.rows_ = row_; df.columns_ = col_;
   df.description = "";
end


 function df = operatorElementWise(func, df1,df2, alignMethod, allowDimExpansion)
    % internal function to perform element wise operations on two DataFrames               
    if isFrame(df1)
        if isFrame(df2)                    
            % get aligned dataframes
            if nargin<4, alignMethod=df1.settings.alignMethod; end
            if nargin<5, allowDimExpansion=df1.settings.allowDimExpansion; end
            [df1_aligned, df2_aligned, rowmask, colmask] = getAlignedDFs(df1, df2, alignMethod, allowDimExpansion);
            % apply element wise function (to aligned subset of data)
            df = df1_aligned;
            if all(rowmask) && all(colmask)
                % assign all data
                df.data_ = func( df1_aligned.data_, df2_aligned.data_);
            else
                % assign sub-selection of data
                data_new = func( df1_aligned.data_(rowmask,colmask), df2_aligned.data_(rowmask,colmask));                
                assert( isa(data_new, class(df.data_)), 'frames:DataFrame:operatorElementWise:unequalTypes', ...
                    "operator output is different type than stored in dataframe. Not allowed to asignment to sub-selection");
                df.data_(rowmask,colmask) = data_new;
            end
        else
            % use obj dataframe and directly apply elementwise function
            df = df1;
            df.data_ = func( df1.data_, df2);
        end
    else
        % use df2 dataframe and directly apply elementwise function
        assert( isFrame(df2), "One of inputs has to be a DataFrame");                
        df = df2;
        df.data_ = func( df1, df2.data_);
    end
    df.description = "";
end


%--------------------------------------------------------------------------
function testUniqueIndex(indexObj)
% test require unique, and ignore empty index
if ~indexObj.requireUnique && length(indexObj.value_)>0
    error('frames:requireUniqueIndex','The function requires an Index of unique values.')
end
end
 