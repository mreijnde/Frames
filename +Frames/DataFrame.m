classdef DataFrame
    %DATAFRAME Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Dependent)
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
    properties (Hidden, Access=protected)
        % Encapsulation. Internal use, there are no tests in the getters
        % and setters.
        
        data_
        index_
        columns_
        name_
    end
    properties (Hidden, Dependent)
        constructor
    end
    
    methods
        function obj = DataFrame(data, index, columns, name)
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
                data = obj.defaultData(length(index), length(columns), class(data));
            end
            if iscolumn(data)
                data = repmat(data, 1, length(columns));
            end
            if isrow(data)
                data = repmat(data, length( index ), 1);
            end
                
            obj.data_ = data;
            obj.index = index;
            obj.columns = columns;
            obj.name_ = name;
            
        end
        
        %------------------------------------------------------------------
        % Setters and Getters
        
        function obj = set.index(obj, value)
            % ToDo: turn it into an Index unique
            % ToDo: test size
            arguments
                obj, value {mustBeDFindex}
            end
            assert(length(value) == size(obj.data,1), ...
                'columns do not have the same size as data')
            value = obj.getIndexObject(value);
            obj.index_ = value;
        end
        function obj = set.columns(obj, value)
            % ToDo: turn it into an Index warning unique
            % ToDo: test size
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
            % ToDo obj.index_.value
            index = obj.index_.value;
        end
        function columns = get.columns(obj)
            % ToDo obj.index_.value
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
        
        function obj = iloc(obj, idxPosition, colPosition)
            arguments
                obj
                idxPosition {mustBeDFindex}
                colPosition {mustBeDFcolumns} = ':'
            end
            obj.data_ = obj.data_(idxPosition, colPosition);
            obj.index_.value_ = obj.index_.value_(idxPosition);
            obj.columns_.value_ = obj.columns_.value_(colPosition);
        end
        function obj = loc(obj, idxName, colName)
            arguments
                obj
                idxName {mustBeDFindex}
                colName {mustBeDFcolumns} = ':'
            end
            if ~iscolon(idxName)
                assertFoundInIndex(idxName, obj.index_.value);
                [~,~,idxID] = intersect(idxName, obj.index_.value, 'stable');
                obj.index_.value_ = obj.index_.value_(idxID);
            else
                idxID = idxName;
            end
            if ~iscolon(colName)
                assertFoundInColumns(colName, obj.columns_.value);
                colID = findPositionInFirstList(obj.columns_.value, colName);
                obj.columns_.value_ = obj.columns_.value_(colID);
            else
                colID = colName;
            end
            obj.data_ =  obj.data_(idxID, colID);
        end
        
        % ToDo subsref subsasgn
        % ToDo Index for cols and index
        % ToDo operations: plus, minus, returns, replace
        % ToDo add drop columns, index, missing
        % ToDO missingData value, size
        % ToDo [] cat
        % ToDo resample, shift, oneify, bool
        % ToDo plot, heatmap
        % ToDo cov corr rolling ewm
        % ToDo ffill bfill
        % ToDo start and end valid, fill
        % ToDo constructors zeros
        % ToDo max min std sum
        % ToDO sortby
        % ToDo split apply
        % toDo read write
        
        
        
        
        
    end
    
    methods (Access=protected)
        function tb = getTable(obj)
            idx = indexForTable(obj.index);
            col = columnsForTable(obj.columns);
            tb = cell2table(num2cell(obj.data), RowNames=idx, VariableNames=col);
        end
        function d = defaultData(obj, lengthIndex, lengthColumns, type)
            if nargin < 3
                type = class(obj.data);
            end
            d = repmat(missingData(type), lengthIndex, lengthColumns);
        end
        function idx = getIndexObject(~, index)
            idx = frames.UniqueIndex(index);
        end
        function col = getColumnsObject(~, columns)
            col = frames.Index(columns);
        end
        function other=modify(obj, data, index, columns, fromPosition)
        end
    end
    
    methods (Hidden)
        function disp(obj)
            maxRows = 100;
            maxCols = 50;  % Matlab is struggles to show many columns
            if all(size(obj) < [maxRows, maxCols])
                disp(obj.t);
            else
                details(this);
            end
        end
            
    end
    
    methods (Hidden, Static, Access=protected)
        function idx = defaultIndex(len)
            idx = (1:len)';
        end
        function col = defaultColumns(len)
            col = "Var" + (1:len);
        end
        
    end
end


