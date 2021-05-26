classdef DataFrame
    %DATAFRAME Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Dependent)
        % Provide the interface.
        
        data
        index
        columns
        name
        t
    end
    properties
        description
    end
    properties (Hidden, Access=protected)
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
            obj.data_ = data;
            obj.index_ = index;
            obj.columns_ = columns;
            obj.name_ = name;
        end
                
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = testPrivate();
        end
        function outputArg = method2(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = frames.testPublic();
        end
        
        %------------------------------------------------------------------
        % Setters Getters
        
        function obj = set.index(obj, value)
            % ToDo: turn it into an Index unique
            % ToDo: test size
            obj.index_ = value;
        end
        function obj = set.columns(obj, value)
            % ToDo: turn it into an Index warning unique
            % ToDo: test size
            obj.columns_ = value;
        end
        function obj = set.data(obj, value)
            assert(all(size(value)==size(this.data_)), ...
                'data is not of the correct size' )
            obj.data_ = value;
        end
        function obj = set.name(obj, value)
            obj.name_ = value;
        end
        
        function index = get.index(obj)
            % ToDo obj.index_.value
            index = obj.index_;
        end
        function columns = get.columns(obj)
            % ToDo obj.index_.value
            columns = obj.columns_;
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
        
        function obj = iloc(obj, idxPosition, colPosition)
        end
        function obj = loc(obj, idxName, colName)
        end
        
        
        
    end
    
    methods(Access=protected)
        function tb = getTable(obj)
            idx = indexForTable(obj.index);
            col = columnsForTable(obj.columns);
            tb = cell2table(num2cell(obj.data),'RowNames',idx,'VariableNames',col);
        end
    end
    
    methods(Hidden)
        function disp(obj)
            maxRow = 100;
            maxCols = 50;
            if all(size(obj) < [maxRow, maxCols])
                disp(obj.t);
            else
                details(this);
            end
        end
            
    end
end

