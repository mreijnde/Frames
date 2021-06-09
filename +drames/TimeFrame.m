classdef TimeFrame < frames.DataFrame
    %UNTITLED6 Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function obj = setIndexType(obj,type)
            obj.index_.format = type;
        end
        function varargout = plot(obj,varargin)
            durationExtension = obj.index(end)-obj.index(1);
            % add 2% of width at the end of the plot to be able to see the end well
            obj = obj.extendIndex(obj.index(end) + 0.02*durationExtension); 
            [varargout{1:nargout}] = plot@frames.DataFrame(obj,'WholeIndex',true,varargin{:});
        end
        function toFile(obj,filePath,varargin)
            writetimetable(obj.t,filePath, ...
                'WriteVariableNames',true,varargin{:});
        end

    end
    
    methods(Static)
        function tf = empty(), tf = frames.TimeFrame(); end
                
        function tf = fromFile(filePath,varargin)
            p = inputParser;
            p.KeepUnmatched = true;
            addOptional(p,'TimeFormat','')
            parse(p,varargin{:});
            namedArgs = p.Results;
            unmatched = namedargs2cell(p.Unmatched);
            if isempty(namedArgs.TimeFormat)
                tb = readtimetable(filePath,...
                    'TreatAsEmpty',{'N/A','NA'}, ...
                    'ReadVariableNames',true, ...
                    unmatched{:});
                tf = frames.TimeFrame.fromTable(tb);
            else
                df = fromFile@frames.DataFrame(filePath,unmatched{:});
                ti = frames.TimeIndex(df.index_,Format=namedArgs.TimeFormat);
                tf = frames.TimeFrame(df.data,ti,df.columns,df.name);
            end
        end
        function df = fromTable(t,nameValue)
            arguments
                t {mustBeA(t,'timetable')}
                nameValue.keepCellstr (1,1) logical = false
            end
            cols = t.Properties.VariableNames;
            if ~nameValue.keepCellstr, cols = string(cols); end
            df = frames.DataFrame(t.Variables,t.Properties.RowTimes,cols);
            df.index_.name = t.Properties.DimensionNames{1};
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
        function tb = getTable(obj)
            col = columnsForTable(obj.columns);
            tb = array2timetable(obj.data,RowTimes=obj.index,VariableNames=col);
        end
    end
end

