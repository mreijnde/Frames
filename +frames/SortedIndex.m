classdef SortedIndex < frames.UniqueIndex
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    methods
        function pos = positionIn(obj,target)
            target = obj.getValue_from(target);
            assertFoundIn(obj.value_,target)
            pos = ismember(target,obj.value_);
        end
        function bool = issorted(~)
            bool = true;
        end
    end
    methods(Access=protected)
        function value = valueChecker(~,value)
            if ~isunique(value) || ~issorted(value)
                error('frames:SortedIndex:valueCheckFail','Index is not unique and sorted.')
            end
        end
        function u = unionData(~,v1,v2)
            u = union(v1,v2,'sorted');  % sorts by default
        end
        
    end
end