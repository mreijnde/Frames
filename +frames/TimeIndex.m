classdef TimeIndex < frames.Index
% TIMEINDEX belongs to the objects that support rows property in a TimeFrame.
% It is stored in the rows_ property of TimeFrame.
% It contains operations of selection and merging, and constrains.
%
% A TIMEINDEX has unique chronological values by default.
%
% This property can be defined explicitly in the constructor of TIMEINDEX,
% or changed with the methods .setRowsType and .setColumnsType of
% TimeFrame.
% An TIMEINDEX can 1) accept duplicate values, 2) require unique value, or 3)
% require unique and sorted values.
%
% If the length of value is equal to 1, the TIMEINDEX can be a
% 'singleton', ie it represents the rows of a series, which will allow
% operations between Frames with different indices (see TimeFrame.series)
%
% Use:
%  TIMEINDEX(value[,Unique=logical,UniqueSorted=logical,Singleton=logical,Name=name,Format=format])
%
% The value can be a datenum, a datetime, or a string, in which case one
% needs to specify its format in the Format key-value argument.
% It can also be modified with the .setRowsFormat method of TimeFrame.
%
% Copyright 2021 Benjamin Gaudin
% Contact: frames.matlab@gmail.com
%
% See also: INDEX
    properties
        format {mustBeTextScalar} = string(missing)  % datetime format
    end
    methods
        function obj = TimeIndex(value,nameValue)
            % TIMEINDEX TimeIndex(value[,Name=name,Format=format])
            arguments
                value
                nameValue.Name = "Time"
                nameValue.Format = string(missing)
                nameValue.Unique = true
                nameValue.UniqueSorted = true
                nameValue.Singleton = false
                nameValue.warningNonUnique (1,1) {mustBeA(nameValue.warningNonUnique,'logical')} = true
            end
            if ismissing(nameValue.Format)
                if isdatetime(value)
                    nameValue.Format = string(value.Format);
                elseif isduration(value)
                    nameValue.Format = "duration";
                else
                    nameValue.Format = "dd-MMM-yyyy";
                end
            end
            if ~nameValue.Unique, nameValue.UniqueSorted = false; end
            
            value = getValue_from_local(value,nameValue.Format);
            obj = obj@frames.Index(value,Name=nameValue.Name,Unique=nameValue.Unique, ...
                                         UniqueSorted=nameValue.UniqueSorted, ...
                                         Singleton=nameValue.Singleton,warningNonUnique=nameValue.warningNonUnique);
            obj.format = nameValue.Format;
        end
        
        function obj=set.format(obj,format)
            arguments
                obj, format {mustBeNonempty,mustBeNonmissing}
            end
            obj.format = format;
        end
        
        
    end
    
    
    methods(Access={?frames.TimeIndex,?frames.DataFrame,?frames.MultiIndex,?frames.Index})
        
        function pos = getSelector_(obj,selector,varargin)
            % find position of 'selector' in the Index
            % On can use a timerange to specify which values to select
            % .getSelector(timerange)
            % .getSelector("dateStart:dateEnd:dateFormat")
            if isTextScalar(selector) && ~iscolon(selector) && contains(selector,':')
                selector = obj.getTimerange(selector);
            end
            if iscell(selector) && length(selector)==2
                selector = timerange(selector{1},selector{2},'closed');
            end
            if isa(selector,'timerange')
                tt = timetable(obj.value);
                [~,whichRows] = overlapsrange(tt,selector);
                ids = (1:length(obj.value_))';
                pos = ids(whichRows);
                return
            end
            if isa(selector,'withtol')
                tt = timetable(obj.value);
                tts = tt(selector,:);
                whichRows = ismember(tt,tts);
                ids = (1:length(obj.value_))';
                pos = ids(whichRows);
                return
            end
            pos = getSelector_@frames.Index(obj,selector,varargin{:});
        end        
        
        function value = valueChecker(obj,value,varargin)
            value_ = obj.getValue_from(value);
            valueChecker@frames.Index(obj,value_,varargin{:});
        end
        
        function value = getValue(obj)
            if isduration(obj.value_)
                value = obj.value_;
            else
                value = datetime(obj.value_,ConvertFrom='datenum',Format=obj.format);
            end
        end
        function value = getValue_from(obj,value)
            % the internal value_ is stored as a datenum for performance
            % reasons
            value = getValue_from@frames.Index(obj,value);
            value = getValue_from_local(value,obj.format);
        end
        function selector = getTimerange(obj,selector)
            splitted = split(selector,':');
            if length(splitted)==3
                format_ = splitted{3};
                splitted = splitted(1:2);
            elseif length(splitted)==2
                format_ = obj.format;
            else
                error('timerange selection from string must be of type "dateStart:dateEnd[:format]"')
            end
            selector = timerangeFromString(splitted,format_);
        end
    end
    
end

function value = getValue_from_local(value,format)
switch class(value)
    case 'datetime'
        value = datenum(value);
    case 'string'
        value = datenum(datetime(value,Format=format));
    case {'double','duration','logical'}
        return
    case {'cell','char'}
        error('TimeIndex:cellstrnotsupported',"Convert the value to a 'datetime', 'string', 'double', or 'duration'.")
    otherwise
        error('type of time index not recognized')
end
end
