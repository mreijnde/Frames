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
    end
end

