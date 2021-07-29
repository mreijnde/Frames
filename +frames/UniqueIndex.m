classdef UniqueIndex < frames.Index
% UNIQUEINDEX belongs to the objects that support index and columns in a DataFrame.
% It contains operations of selection and merging, and constrains.
%
% A UNIQUEINDEX has unique values.
% Index allows duplicates, but throw a warning.
% SortedIndex only allows unique sorted entries.
% TimeIndex only allows unique chronological time entries.
%
% Copyright 2021 Benjamin Gaudin
%
% See also: SORTEDINDEX, INDEX, TIMEINDEX
    methods
        function obj = UniqueIndex(value,nameValue)
            % INDEX Index(value[,Name=name,Singleton=logical])
            arguments
                value {mustBeDFcolumns} = []
                nameValue.Name = ""
                nameValue.Unique (1,1) {mustBeA(nameValue.Unique,'logical')} = true
                nameValue.UniqueSorted (1,1) {mustBeA(nameValue.UniqueSorted,'logical')} = false
                nameValue.Singleton (1,1) {mustBeA(nameValue.Singleton,'logical')} = false
            end
            obj = obj@frames.Index(value,Name=nameValue.Name,Unique=nameValue.Unique,UniqueSorted=nameValue.UniqueSorted);
        end
    end
    
end

