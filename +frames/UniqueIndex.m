classdef UniqueIndex < frames.Index
% UNIQUEINDEX is the object that supports index and columns in a DataFrame.
% It contains operations of selection and merging, and constrains.
%
% A UNIQUEINDEX has unique values.
% Index allows duplicates, but throw a warning.
% SortedIndex only allows unique sorted entries.
% TimeIndex only allows unique chronological time entries.
% See also: SORTEDINDEX, INDEX, TIMEINDEX
    methods
        function pos = positionOf(obj,selector,varargin)
            selector = obj.getValue_andCheck(selector,varargin{:});
            assertFoundIn(selector,obj.value_)
            [~,~,pos] = intersect(selector,obj.value_,'stable');
        end
        function pos = positionIn(obj,target,varargin)
            target = obj.getValue_andCheck(target,varargin{:});
            assertFoundIn(obj.value_,target)
            [~,~,pos] = intersect(obj.value_,target,'stable');
        end
        
        function bool = isunique(~)
            bool = true;
        end
    end
    
    methods(Access=protected)
        function valueChecker(~,value)
            if ~isvector(value)
                error('frames:Index:notVector','index must be a vector')
            end
            if ~isunique(value)
                error('frames:UniqueIndex:valueCheckFail','index is not unique')
            end
        end

        function u = unionData(~,v1,v2)
            u = union(v1,v2,'stable');
        end
    end
end

