classdef UniqueIndex < frames.Index
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    methods
    function obj = UniqueIndex(value)
            %UNTITLED4 Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                value {mustBeUnique} = []
            end
            obj = obj@frames.Index(value);
        end
    end
end

