classdef TimeFrame < frames.DataFrame
%TIMEFRAME handles common operations on homogeneous data matrices referenced by column and chronological time identifiers.
%   It is a convenient way to perform operations on time series (more intuitive than Matlab's timetable).
%
%   Constructor:
%   df = frames.TimeFrame([data,index,columns,name])
%   If an argument is not specified, it will take a default value, so it
%   is possible to only define some of the arguments:
%   df = frames.TimeFrame(data)  
%   df = frames.TimeFrame(data,[],columns)
%
%   TIMEFRAME properties:
%     data                   - Data      TxN  (homogeneous data)
%     index                  - Sorted Time Index     Tx1
%     columns                - Columns   1xN
%     t                      - Timetable built on the properties above.
%     name                   - Name of the frame
%     description            - Description of the frame
%
%
%   Short overwiew of methods available:
%
%   - Selection and modification based on index/column names with () or the loc method:
%     tf(indexNames,columnsNames)
%     tf.loc(indexNames,columnsNames)
%     tf(indexNames,columnsNames) = newData
%     tf.loc(indexNames,columnsNames) = newData
%   - One can also use a timerange in lieu of specific index names:
%     tf(timerange,columnNames)
%     tf("dateStart:dateEnd:dateFormat",columnNames)
%
%   - Selection and modification based on position with {} or the iloc method:
%     tf{indexPosition,columnsPosition}
%     tf.iloc(indexPosition,columnsPosition)
%     tf{indexPosition,columnsPosition} = newData
%     tf.iloc(indexPosition,columnsPosition) = newData
%
%   - Operations between frames while checking that the two frames
%     are aligned (to be sure to compare apples to apples):
%     tf1 + tf2
%     1 + tf
%     tf1' * tf2, etc.
%
%   - Chaining of methods:
%     tf.relChange().std(),  computes the standard deviation of the
%     relative change of tf
%     tf{5:end,:}.log().diff(),  computes the difference of the log of tf
%     from lines 5 to end
%
%   - Visualisation methods:
%     tf.plot(), tf.heatmap()
%
%   - Setting properties is checked to insure the coherence of the frame.
%     tf.index = newIndex,  will give an error if length(newIndex) ~=
%     size(tf.data,1), or if newIndex is not sorted
%
%   - Concatenation of frames:
%     newTF = [tf1,tf2] concatenates two frames horizontally, and will
%     expand (unify) their index if they are not equal, inserting missing
%     values in the expansion
%
%   - Split a frame into groups based on its columns, and apply a function:
%     tf.split(groups).apply(@(x) x.sum(2))  sums the data on the dimension
%     2, group by group, so the result is a Txlength(group) frame
%
%   - Rolling window methods:
%     tf.rolling(30).mean() computes the rolling mean with a 30 step
%     lookback period
%     tf.ewm(Halflife=30).std() computes the exponentially weighted moving
%     standard deviation with a halflife of 30
%
%
% For more details, see the list of available methods below.
%
% Copyright 2021 Benjamin Gaudin
%
% See also: frames.DataFrame
    
    methods
        function obj = setIndexType(obj,type)
            % set the time format of the TimeIndex
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
        % construct an emtpy TimeFrame
                
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
        function tf = fromTable(t,nameValue)
            arguments
                t {mustBeA(t,'timetable')}
                nameValue.keepCellstr (1,1) logical = false
            end
            cols = t.Properties.VariableNames;
            if ~nameValue.keepCellstr, cols = string(cols); end
            idx = t.Properties.RowTimes;
            idx.Format = string(idx.Format).replace('u','y');
            tf = frames.TimeFrame(t.Variables,idx,cols);
            tf.index_.name = string(t.Properties.DimensionNames{1});
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
            if ~isempty(obj.index_.name)
                tb.Properties.DimensionNames{1} = char(obj.index_.name);
            end
        end
    end
end

