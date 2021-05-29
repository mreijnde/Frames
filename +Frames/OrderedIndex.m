classdef OrderedIndex < frames.UniqueIndex
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    methods
        function bool = issorted(~)
            bool = true;
        end
    end
    methods(Access=protected)
        function value = valueChecker(~, value)
            if ~isunique(value) || ~issorted(value)
                error('index is not unique and sorted')
            end
        end
    end
    methods(Access=protected)
        function u = unionData(~,v1, v2)
            u = union(v1,v2,'sorted');  % sorts by default
        end
        
    end
end