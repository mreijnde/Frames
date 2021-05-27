classdef OrderedIndex < frames.UniqueIndex
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    methods
%     function obj = OrderedIndex(value)
%             %UNTITLED4 Construct an instance of this class
%             %   Detailed explanation goes here
%             arguments
%                 value {mustBeSorted} = []
%             end
%             obj = obj@frames.UniqueIndex(value);
%         end
    end
    methods(Static, Access=protected)
        function value = valueChecker(value)
            if ~isunique(value) || ~issorted(value)
                error('index is not unique and sorted')
            end
        end
    end
end