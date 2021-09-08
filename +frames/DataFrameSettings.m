%DATAFRAMESETTINGS is a class that contains the persistant
%static properties for the DataFrame class 

classdef DataFrameSettings < handle
    properties
        % access/assign columns by dot notation df.<column name>
        ColumnDotNotation = true;        
    end    
end