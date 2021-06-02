classdef TimeFrame < frames.DataFrame
    %UNTITLED6 Summary of this class goes here
    %   Detailed explanation goes here
    
    methods

    end
    
    methods(Access=protected)
        function idx = getIndexObject(~,index)
            idx = frames.TimeIndex(index);
        end
    end
end

