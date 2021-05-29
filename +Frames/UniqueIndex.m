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
        function pos = positionOf(obj, selector)
            assertFoundIn(selector, obj.value)
            [~,~,pos] = intersect(selector, obj.value, 'stable');
        end
        function pos = positionIn(obj, target)
            pos = ismember(obj.value, target);
        end
    end
    methods(Static, Access=protected)
        function value = valueChecker(value)
            if ~isunique(value)
                error('index is not unique')
            end
        end
    end
end

