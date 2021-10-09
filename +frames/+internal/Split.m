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
        group  % frames.Groups
        df  % frames.DataFrame
    end
    
    methods
        function obj = Split(df, groups)
            obj.df = df;
            obj.groups = groups;
            if groups.constantGroups
                allCols = [groups.values{:}];
                if frames.internal.isunique(allCols)
                    warning('frames:SplitOverlap','There are overlaps in Split')
                end
                if any(~ismember(df.columns,allCols))
                    warning('frames:SplitNonexhaustive','Split is not exhaustive')
                end
            else
                assert(isequaln(groups.rows,df.rows)) % ToDo message
                assert(isequaln(groups.columns,df.columns))
            end
        end
    end
    
    methods
        function other = apply(obj,fun,varargin)
            out = obj.computeFunction(fun,false,varargin{:});
            constructor = str2func(class(obj.df));
            other = constructor(out, obj.df.getRowsObj(), obj.df.getColumnsObj());
        end
        function other = aggregate(obj,fun,varargin)
            out = obj.computeFunction(fun,true,varargin{:});
            constructor = str2func(class(obj.df));
            other = constructor(out, obj.df.getRowsObj(), obj.groups.keys);
        end
        function out = computeFunction(obj,fun,reduceDim,varargin)
            % APPLY apply a function to each sub-Frame, and returns a single Frame
            % flag, enum('applyToFrame','applyToData'): 'applyToFrame' (default)
            % allows to use DataFrame methods, but may be slower than
            % applying a function directly to the data with 'applyToData'
            % e.g. .apply(@(x) sum(x,2),'applyToData') vs .apply(@(x) x.sum(2),'applyToFrame')
            isflag = find(strcmp(varargin,'applyToFrame'),1);
            applyToFrameFlag = ~isempty(isflag);
            varargin(isflag) = [];
            isflag = find(strcmp(varargin,'applyToData'),1);
            applyToDataFlag = ~isempty(isflag);
            varargin(isflag) = [];
            condFlags = [applyToFrameFlag,applyToDataFlag];
            if all(condFlags)
                error('frames:splitapply:flag','Chose one flag only.')
            elseif all(condFlags == [false true])
                applyToFrame = false;
            else
                applyToFrame = true;
            end
            
            dfdata = obj.df.data;
            df_ = obj.df;
            
            if obj.groups.constantGroups
                indexLoop = ':';
            else
                indexLoop = 1:size(dfdata,1);
            end
            firstIteration = true;
            for ii = 1:length(obj.groups.values)
                gVal = obj.groups.values{ii};
                if applyToFrame
                    df_.name = obj.groups.keys(ii);
                end
                for idx = indexLoop
                    if obj.groups.constantGroups
                        colID = obj.df.getColumnsObj().positionOf(gVal);
                    else
                        colID = gVal(idx,:);
                        if ~any(colID)
                            continue
                        end
                    end
                    
                    if applyToFrame
                        val = df_.iloc_(idx,colID);
                        res_ = fun(val,varargin{:});
                        res_ = local_getData(res_);
                    else
                        val = dfdata(idx,colID);
                        res_ = fun(val,varargin{:});
                    end
                    if firstIteration
                        dataType = str2func(class(res_));
                        if reduceDim
                            out = repmat(dataType(missing),size(dfdata,1),length(obj.groups.keys));
                        else
                            out = repmat(dataType(missing),size(dfdata));
                        end
                        firstIteration = false;
                    end
                    if reduceDim
                        out(idx,colID) = res_;
                    else
                        [lenIdx,lenCol] = size(val);
                        out(idx,colID) = repmat(res_,1+lenIdx-size(res_,1),1+lenCol-size(res_,2));
                    end
                end
            end
        end
    end
    
end

function resDF = local_applyGroupDF(dataDF,groupsDF,fun,applyToFrame,varargin)
data = dataDF.data;
dataType = str2func(class(data));
res = repmat(dataType(missing),size(data));
groups = groupsDF.data;
if groupsDF.rowseries
    idxSameGroups = [1;size(data,1)];
else
    idxSameGroups = local_idxSameData(groups);
end
for ii = 1:size(idxSameGroups,2)
    idx = idxSameGroups(:,ii);
    idx_ = idx(1):idx(2);
    if applyToFrame
        df_ = dataDF.iloc_(idx_,:);
    else
        df_ = data(idx_,:);
    end
    groups_ = groups(idx(1),:);
    groups_unique = unique(groups_);
    groups_unique = groups_unique(~ismissing(groups_unique));
    for g = groups_unique
        g_ = groups(idx(1),:) == g;
        if applyToFrame
            res_ = fun(df_.iloc_(:,g_),varargin{:});
            if ii==1 && g==groups_unique(1), isframe = frames.internal.isFrame(res_); end
            if isframe, res_ = res_.data; end
        else
            res_ = fun(df_(:,g_),varargin{:});
        end
        res_ = repmat(res_, length(idx_)./size(res_,1), sum(g_)./size(res_,2));
        res(idx_,g_) = res_;
    end
end
resDF = dataDF;
resDF.data_ = res;
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
        idx = [idx, idx_]; %#ok<AGROW>
    end
end
end

function data = local_getData(data)
if isframe(data), data = data.data; end
end