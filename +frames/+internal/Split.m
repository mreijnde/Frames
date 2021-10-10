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
        groups  % frames.Groups
        df  % frames.DataFrame
    end
    
    methods
        function obj = Split(df, groups)
            obj.df = df;
            obj.groups = groups;
            if groups.constantGroups
                allElements = [groups.values{:}];
                if ~frames.internal.isunique(allElements)
                    warning('frames:SplitOverlap','There are overlaps in Split')
                end
                if groups.isColumnGroups, toSplit=df.columns; else, toSplit=df.rows; end
                if any(~ismember(toSplit,allElements))
                    warning('frames:SplitNonexhaustive','Split is not exhaustive')
                end
            else
                assert(isequaln(groups.frame.rows,df.getRowsObj())) % ToDo message
                assert(isequaln(groups.frame.columns,df.getColumnsObj))
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
            if obj.groups.isColumnGroups
                other = constructor(out, obj.df.getRowsObj(), obj.groups.keys);
            else
                other = constructor(out, obj.groups.keys, obj.df.getColumnsObj());
            end
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
            if applyToFrame
                keyiscell = iscell(obj.groups.keys);
            end
            
            if obj.groups.constantGroups
                indexLoop = ':';
            else
                if obj.groups.isColumnGroups
                    indexLoop = 1:size(dfdata,1);  % kk, 2
                else
                    indexLoop = 1:size(dfdata,2);  % kk, 2
                end
            end
            firstIteration = true;
            for ii = 1:length(obj.groups.values)
                gVal = obj.groups.values{ii};
                if applyToFrame
                    if keyiscell, df_.description = obj.groups.keys{ii}; 
                    else, df_.description = obj.groups.keys(ii); end
                end
                for idx = indexLoop
                    if obj.groups.isColumnGroups, rowID=idx; else, colID=idx; end
                    if obj.groups.constantGroups
                        if obj.groups.isColumnGroups
                            colID = obj.df.getColumnsObj().positionOf(gVal);  % kk Rows
                        else
                            rowID = obj.df.getRowsObj().positionOf(gVal);  % kk Rows
                        end
                    else
                        if obj.groups.isColumnGroups
                            colID = gVal(idx,:);  % kk (:,col)
                            if ~any(colID), continue; end
                        else
                            rowID = gVal(:,idx);  % kk (:,col)
                            if ~any(rowID), continue; end
                        end
                    end
                    
                    if applyToFrame
                        val = df_.iloc_(rowID,colID);  % todo iterate faster
                        res = fun(val,varargin{:});
                        res = local_getData(res);
                    else
                        val = dfdata(rowID,colID);
                        res = fun(val,varargin{:});
                    end
                    if firstIteration
                        dataType = str2func(class(res));
                        if reduceDim
                            if obj.groups.isColumnGroups
                                out = repmat(dataType(missing),size(dfdata,1),length(obj.groups.keys));  % kk len, ,2
                            else
                                out = repmat(dataType(missing),length(obj.groups.keys),size(dfdata,2));  % kk len, ,2
                            end
                        else
                            out = repmat(dataType(missing),size(dfdata));
                        end
                        firstIteration = false;
                    end
                    if reduceDim
                        if obj.groups.isColumnGroups
                            out(idx,ii) = res;  % ii,idx
                        else
                            out(ii,idx) = res;  % ii,idx
                        end
                    else
                        [lenIdx,lenCol] = size(val);
                        out(rowID,colID) = repmat(res,1+lenIdx-size(res,1),1+lenCol-size(res,2));
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
if frames.internal.isFrame(data), data = data.data; end
end