classdef UniqueIndex < frames.Index
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    methods
%         function obj = UniqueIndex(value)
%             %UNTITLED4 Construct an instance of this class
%             %   Detailed explanation goes here
%             arguments
%                 value {mustBeUnique} = []
%             end
%             obj = obj@frames.Index(value);
%         end
        function pos = positionOf(obj,selector)
            selector = obj.getValue_from(selector);
            assertFoundIn(selector,obj.value_)
            [~,~,pos] = intersect(selector,obj.value_,'stable');
        end
        function pos = positionIn(obj,target)
            target = obj.getValue_from(target);
            assertFoundIn(obj.value_,target)
            pos = ismember(target,obj.value_);
        end
        
        function bool = isunique(~)
            bool = true;
        end
    end
    
    methods(Access=protected)
        function value = valueChecker(~,value)
            if ~isunique(value)
                error('index is not unique')
            end
        end

        function u = unionData(~,v1,v2)
            u = union(v1,v2,'stable');
        end
    end
end

