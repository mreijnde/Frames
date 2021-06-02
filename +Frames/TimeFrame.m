classdef TimeFrame < frames.DataFrame
    %UNTITLED6 Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function obj = setIndexType(obj,type)
            obj.index_.format = type;
        end
    end
    
    methods(Access=protected)
        function indexValidation(obj,value)
            if isa(value,'frames.Index') && ~isa(value,'frames.TimeIndex')
                error('TimeFrame can only accept a TimeIndex as index.')
            end
            indexValidation@frames.DataFrame(obj,value);
        end
        function idx = getIndexObject(~,index)
            idx = frames.TimeIndex(index);
        end
    end
end

