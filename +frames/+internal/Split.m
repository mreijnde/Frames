classdef Split
 % SPLIT split a Frame into groups to apply a function separately group by group
 % Use: dfsplit = df.split(frames.Groups[,flags]).<apply,aggregate>(func[,args,flag])
 %
 % ----------------
 % Parameters:
 %     * df (Frame)
 %     * groups (frames.Groups)
 %          Object that contains keys and values describing
 %          groups. Please refer to the documentation of
 %          frames.Groups for more details.
 %
 % Methods:
 %     * apply      
 %           apply a function to each sub-Frame, and returns a single Frame. Maintains the structure of the original Frame.
 %     * aggregate  
 %           apply a function to each sub-Frame, and returns a single Frame. Returns a single vector for each group.
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
        function obj = Split(df, groups, varargin)
            % SPLIT Split(df,groups)
            assert(isa(groups,'frames.Groups'),'group must be a frames.Group')
            obj.df = df;
            obj.groups = groups;
            if groups.constantGroups
                isflag = find(strcmp(varargin,'allowOverlaps'),1);
                allowOverlaps = ~isempty(isflag);
                isflag = find(strcmp(varargin,'isNonExhaustive'),1);
                isNonExhaustive = ~isempty(isflag);
                allElements = [groups.values{:}];
                if ~allowOverlaps && ~frames.internal.isunique(allElements)
                    error('frames:SplitOverlap','There are overlaps in Split')
                end
                if groups.isColumnGroups, toSplit=df.columns; else, toSplit=df.rows; end
                if ~isNonExhaustive && any(~ismember(toSplit,allElements))
                    error('frames:SplitNonexhaustive','Split is not exhaustive')
                end
            else
                assert(isequaln(groups.frame.rows,df.getRowsObj())) % ToDo message
                assert(isequaln(groups.frame.columns,df.getColumnsObj))
            end
        end
    end
    
    methods
        function other = apply(obj,fun,varargin)
            % APPLY apply a function to each sub-Frame, and returns a single Frame. Maintains the structure of the original Frame.
            %  * fun: function to apply, must be applicable to a matrix
            %  * flag enum('applyToFrame','applyToData'), 'applyToData' (default):
            %       allows to use DataFrame methods, but may be slower than
            %       applying a function directly to the data with 'applyToData'
            %  * flag 'applyByLine':
            %       allows to pass a function that will be applied line by
            %       line instead that on a matrix
            % e.g. .apply(@(x) sum(x,2),'applyToData') vs .apply(@(x) x.sum(2),'applyToFrame')
            out = obj.computeFunction(fun,false,varargin{:});
            other = obj.df.constructor(out, obj.df.getRowsObj(), obj.df.getColumnsObj());
        end
        function other = aggregate(obj,fun,varargin)
            % AGGREGATE apply a function to each sub-Frame, and returns a single Frame. Returns a single vector for each group.
            %  * fun: function to apply, must be applicable to a matrix
            %  * flag enum('applyToFrame','applyToData'), 'applyToData' (default):
            %       allows to use DataFrame methods, but may be slower than
            %       applying a function directly to the data with 'applyToData'
            % e.g. .aggregate(@(x) sum(x,2),'applyToData') vs .aggregate(@(x) x.sum(2),'applyToFrame')
            out = obj.computeFunction(fun,true,varargin{:});
            if obj.groups.isColumnGroups
                other = obj.df.constructor(out, obj.df.getRowsObj(), obj.groups.keys);
            else
                other = frames.DataFrame(out, obj.groups.keys, obj.df.getColumnsObj());  % not constructor as groups are an ordinary Index
            end
        end
    end
    methods(Access=protected)
        function out = computeFunction(obj,fun,reduceDim,varargin)
            
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
            isflag = find(strcmp(varargin,'applyByLine'),1);
            applyByLine = ~isempty(isflag);
            varargin(isflag) = [];
            
            dfdata = obj.df.data;
            df_ = obj.df;
            if applyToFrame
                keyiscell = iscell(obj.groups.keys);
            end
            
            if obj.groups.constantGroups
                indexLoop = ':';
            end
            firstIteration = true;
            for ii = 1:length(obj.groups.values)
                gVal = obj.groups.values{ii};
                if applyByLine
                    if obj.groups.isColumnGroups
                        indexLoop = 1:size(dfdata,1);
                    else
                        indexLoop = 1:size(dfdata,2);
                    end
                elseif ~obj.groups.constantGroups
                    gVal = full(gVal);  % for performance reasons, better to work with non sparse matrices
                    if obj.groups.isColumnGroups
                        [uniqueGroups,sameVals,indexLoop] = local_idxSameData(gVal);
                    else
                        [uniqueGroups,sameVals,indexLoop] = local_idxSameData(gVal');
                    end
                end
                if applyToFrame
                    if keyiscell, df_.description = obj.groups.keys{ii}; 
                    else, df_.description = obj.groups.keys(ii); end
                end
                for idx = indexLoop
                    if obj.groups.constantGroups
                        if obj.groups.isColumnGroups
                            rowID = idx;
                            colID = obj.df.getColumnsObj().positionOf(gVal);
                        else
                            colID = idx;
                            rowID = obj.df.getRowsObj().positionOf(gVal);
                        end
                    else
                        if applyByLine
                            if obj.groups.isColumnGroups
                                rowID = idx;
                                colID = gVal(idx,:);
                            else
                                colID = idx;
                                rowID = gVal(:,idx);
                            end
                        elseif obj.groups.isColumnGroups
                            rowID = sameVals==idx;
                            colID = uniqueGroups(idx,:);
                            if ~any(colID), continue; end
                        else
                            colID = sameVals==idx;
                            rowID = uniqueGroups(idx,:);
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


function [uniqueGroups,sameVals,idxOut] = local_idxSameData(data)
[uniqueGroups,~,sameVals] = unique(data,'rows','stable');
sameVals = sameVals(:)';
idxOut = unique(sameVals,'stable');
end


function data = local_getData(data)
if frames.internal.isFrame(data), data = data.data; end
end
