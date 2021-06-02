classdef TimeFrame < frames.DataFrame
    %UNTITLED6 Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function obj = setIndexType(obj,type)
            obj.index_.format = type;
        end
        function varargout = plot(obj,varargin)
            duration = obj.index(end)-obj.index(1);
            obj = obj.extendIndex(obj.index(end) + 0.02*duration); % add 2% of width at the end of the plot to be able to see the end well
            [varargout{1:nargout}] = plot@frames.DataFrame(obj,'WholeIndex',true,varargin{:});
        end
    end
    
    methods(Static)
        function tf = empty(), tf = frames.TimeFrame(); end
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

