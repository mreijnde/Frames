classdef TimeIndex < frames.OrderedIndex
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    methods(Access=protected)
        function value = valueChecker(value)
            if ~isunique(value) || ~issorted(value)
                error('index is not unique and sorted')
            end
            value = datetime(value, 'ConvertFrom', 'datenum');
        end
    end
    
end