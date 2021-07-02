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
        function pos = positionIn(obj,target,varargin)
            target = obj.getValue_andCheck(target,varargin{:});
            assertFoundIn(obj.value_,target)
            pos = ismember(target,obj.value_);
        end
        function bool = issorted(~)
            bool = true;
        end
    end
    methods(Access=protected)
        function valueChecker(obj,value)
            if ~issorted(value)
                error('frames:SortedIndex:valueCheckFail','Index is not sorted.')
            end
            valueChecker@frames.UniqueIndex(obj,value);
            
        end
        function u = unionData(~,v1,v2)
            u = union(v1,v2,'sorted');  % sorts by default
        end
        
    end
end