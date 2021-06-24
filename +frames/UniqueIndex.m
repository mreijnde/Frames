classdef UniqueIndex < frames.Index
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    methods
        function pos = positionOf(obj,selector)
            selector = obj.getValue_from(selector);
            assertFoundIn(selector,obj.value_)
            [~,~,pos] = intersect(selector,obj.value_,'stable');
        end
        function pos = positionIn(obj,target)
            target = obj.getValue_from(target);
            assertFoundIn(obj.value_,target)
            [~,~,pos] = intersect(obj.value_,target,'stable');
        end
        
        function bool = isunique(~)
            bool = true;
        end
    end
    
    methods(Access=protected)
        function value = valueChecker(~,value)
            if ~isunique(value)
                error('frames:UniqueIndex:valueCheckFail','index is not unique')
            end
        end

        function u = unionData(~,v1,v2)
            u = union(v1,v2,'stable');
        end
    end
end

