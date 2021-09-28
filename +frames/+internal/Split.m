classdef Split < dynamicprops
 % SPLIT split a Frame into column-based groups to apply a function separately
 % Use: split = frames.Split(df,splitter[,namesOfGroups])
 % The properties of split are the elements in namesOfGroups, or the 
 % fields of the splitter if namesOfGroups is not provided.
 %
 % ----------------
 % Parameters:
 %     * df: (Frame)
 %     * splitter: (cell array,struct,frames.Group) 
 %          Contain the list of elements in each group. Can be of different
 %          types:
 %          - cell array: cell array of lists of elements in groups
 %              In this case, namesOfGroups is required
 %              e.g. splitter={list1,list2}; namesOfGroups=["name1","name2"]
 %          - struct: structure whose fields are group names and values are
 %              elements in each group. If namesOfGroups is not specified, 
 %              the split use all fields of the structure as namesOfGroups.
 %          - frames.Group: Group whose property names are group names and
 %              property values are elements in each group. If namesOfGroups
 %              is not specified, the split use all properties of the 
 %              Group as namesOfGroups.
 %          - frames.DataFrame: If groups change along the rows, one can
 %              use a DataFrame that specifies to which group each element
 %              belongs to. namesOfGroups is not used.
 %     * namesOfGroups: (string array) 
 %          group names into which we want to split the Frame
 %
 % SPLIT method:
 %  apply   - apply a function to each sub-Frame, and returns a single Frame
 %
 % Copyright 2021 Benjamin Gaudin
 % Contact: frames.matlab@gmail.com
 %
 % See also: frames.Groups
    properties(Access=private)
        nameOfProperties_
        
        isFrameSplitter = false;
        groupDF
        dataDF
    end
    
    methods (Access=?frames.DataFrame)
        function obj = Split(df,splitter,namesOfGroups)
            % Split(df,splitter[,namesOfGroups])
            if frames.internal.isFrame(splitter)
                obj.isFrameSplitter = true;
                if splitter.rowseries
                    constr = str2func(class(df));
                    splitter = constr(splitter.data,df.getRows_(),splitter.getColumns_());
                end
                assert(isequaln(df.rows,splitter.rows) && isequaln(df.columns,splitter.columns), ...
                    'frames:split:groupMisaligned', 'the group frame must be aligned with the data frame')
                obj.groupDF = splitter;
                obj.dataDF = df;
                return
            end
            if isa(splitter, 'frames.Groups') || isa(splitter,'struct')
                if nargin < 3
                    namesOfGroups = string(fieldnames(splitter));
                else
                    assert(all(ismember(namesOfGroups,fieldnames(splitter))), ...
                        'The names of the properties must be found in the splitter');
                end
                splitter_ = {};  % turn it into a cell
                for ii=1:length(namesOfGroups)
                    splitter_{ii} = splitter.(string(namesOfGroups(ii))); %#ok<AGROW>
                end
                splitter = splitter_;
            else
                if nargin < 3
                    namesOfGroups = "Group" + (1:length(splitter));
                end
            end
            assert(length(namesOfGroups) == length(splitter), ...
                'The names of the properties are not of the same length as the splitter')
            obj.nameOfProperties_ = namesOfGroups;
            for ii = 1:length(splitter)  % groups df into properties
                cols = splitter{ii};
                propName = obj.nameOfProperties_{ii};
                propValue = df(:,cols);
                propValue.name = propName;
                obj.addprop(propName);
                obj.(propName) = propValue;
            end
            
            splitterData = [splitter{:}];
            if ~frames.internal.isunique(splitterData)
                warning('frames:SplitOverlap','There are overlaps in Split')
            end
            if any(~ismember(df.columns,splitterData))
                warning('frames:SplitNonexhaustive','Split is not exhaustive')
            end
        end
    end
    
    methods

        function res = apply(obj,fun,varargin)
            % APPLY apply a function to each sub-Frame, and returns a single Frame
            if obj.isFrameSplitter
                res = local_applyGroupDF(obj.dataDF,obj.groupDF,fun,varargin{:});
                return
            end
            props = obj.nameOfProperties_;
            isVectorOutput = true;  % if the output of fun returns a vector
            for ii = 1:length(props)
                res_ = fun(obj.(props{ii}),varargin{:});
                if ii == 1
                    res = res_;
                else
                    warning('off','frames:Index:notUnique')
                    res = [res,res_]; %#ok<AGROW>
                end
                if (frames.internal.isFrame(res_) && ~res_.colseries) ...
                        || (~frames.internal.isFrame(res_) && size(res_,2)>1)
                    isVectorOutput = false;
                end
            end
            if ~frames.internal.isFrame(res)
                constructor = str2func(class(obj.(props{1})));
                if isVectorOutput
                    cols = props;
                else
                    cols = obj.(props{1}).getColumns_();
                    for ii = 2:length(props)
                        cols = [cols; obj.(props{ii}).getColumns_()]; %#ok<AGROW>
                    end
                end
                res = constructor(res,obj.(props{1}).rows_,cols);
            else
                if isVectorOutput
                    res.columns_.singleton_ = false;
                    res.columns = props;
                end
            end
            res = res.resetUserProperties();
            warning('on','frames:Index:notUnique')
        end
    end
    
end

function resDF = local_applyGroupDF(dataDF,groupsDF,fun,varargin)
f = str2func(class(dataDF.data));
res = repmat(f(missing),size(dataDF.data));
groups = groupsDF.data;
idxSameGroups = local_idxSameData(groups);
for ii = 1:size(idxSameGroups,2)
    idx = idxSameGroups(:,ii);
    idx_ = idx(1):idx(2);
    df_ = dataDF.iloc_(idx_,:);
    groups_ = groups(idx(1),:);
    groups_unique = unique(groups_);
    groups_unique = groups_unique(~ismissing(groups_unique));
    for g = groups_unique
        g_ = groups(idx(1),:) == g;
        res_ = fun(df_.iloc_(:,g_),varargin{:});
        res_ = local_getData(res_);
        res_ = repmat(res_, length(idx_)./size(res_,1), sum(g_)./size(res_,2));
        res(idx_,g_) = local_getData(res_);
    end
end
resDF = dataDF;
resDF.data = res;
end

function idxOut = local_idxSameData(data)
idxStart = local_linesOfChange(data);
idxEnd = [idxStart(2:end)-1, size(data,1)];
idxOut = [idxStart; idxEnd];
end

function idx = local_linesOfChange(data)
idx_ = 1;
idx = idx_;
for ii = 2:size(data,1)
    if ~isequaln(data(idx_,:), data(ii,:))
        idx_ = ii;
        idx = [idx, idx_];
    end
end
end

function data = local_getData(data)
if frames.internal.isFrame(data), data = data.data; end
end