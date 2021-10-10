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
                other = frames.DataFrame(out, obj.groups.keys, obj.df.getColumnsObj());  % not constructor as groups are an ordinary Index
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
                error('frames:splitapply:flag','Choose one flag only.')
            elseif condFlags(1)
                applyToFrame = true;
            else
                applyToFrame = false;
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
                    indexLoop = 1:size(dfdata,1);
                else
                    indexLoop = 1:size(dfdata,2);
                end
            end
            firstIteration = true;
            for ii = 1:length(obj.groups.values)
                gVal = obj.groups.values{ii};
                if ~obj.groups.constantGroups
                    gVal = full(gVal);  % for performance reasons, better to work with non sparse matrices
                    if obj.groups.isColumnGroups
                        indexLoop = local_idxSameData(gVal);  % faster when groups are constant by blocks
                    else
                        indexLoop = local_idxSameData(gVal');
                    end
                end
                if applyToFrame
                    if keyiscell, df_.description = obj.groups.keys{ii}; 
                    else, df_.description = obj.groups.keys(ii); end
                end
                for idx = indexLoop
                    if obj.groups.isColumnGroups, rowID=idx(1):idx(end); else, colID=idx(1):idx(end); end
                    if obj.groups.constantGroups
                        if obj.groups.isColumnGroups
                            colID = obj.df.getColumnsObj().positionOf(gVal);
                        else
                            rowID = obj.df.getRowsObj().positionOf(gVal);
                        end
                    else
                        if obj.groups.isColumnGroups
                            colID = gVal(idx(1),:);
                            if ~any(colID), continue; end
                        else
                            rowID = gVal(:,idx(1));
                            if ~any(rowID), continue; end
                        end
                    end
                    
                    if applyToFrame
                        % ToDo: unecessary selection of rows and columns
                        % slow down the computation
                        val = df_.iloc_(rowID,colID);
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
                                out = repmat(dataType(missing),size(dfdata,1),length(obj.groups.keys));
                            else
                                out = repmat(dataType(missing),length(obj.groups.keys),size(dfdata,2));
                            end
                        else
                            out = repmat(dataType(missing),size(dfdata));
                        end
                        firstIteration = false;
                    end
                    if reduceDim
                        if obj.groups.isColumnGroups
                            out(rowID,ii) = res;
                        else
                            out(ii,colID) = res;
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