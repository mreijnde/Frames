classdef SortedIndex < frames.UniqueIndex
% SORTEDINDEX belongs to the objects that support index and columns in a DataFrame.
% It contains operations of selection and merging, and constrains.
%
% A SORTEDINDEX has unique sorted values.
% Index allows duplicates, but throw a warning.
% UniqueIndex only allows unique entries.
% TimeIndex only allows unique chronological time entries.
%
% Copyright 2021 Benjamin Gaudin
%
% See also: UNIQUEINDEX, INDEX, TIMEINDEX
    methods
        function obj = SortedIndex(value,nameValue)
            % INDEX Index(value[,Name=name,Singleton=logical])
            arguments
                value {mustBeDFcolumns} = []
                nameValue.Name = ""
                nameValue.Unique (1,1) {mustBeA(nameValue.Unique,'logical')} = true
                nameValue.UniqueSorted (1,1) {mustBeA(nameValue.UniqueSorted,'logical')} = true
                nameValue.Singleton (1,1) {mustBeA(nameValue.Singleton,'logical')} = false
            end
            obj = obj@frames.UniqueIndex(value,Name=nameValue.Name,UniqueSorted=nameValue.UniqueSorted);
        end
    end
end