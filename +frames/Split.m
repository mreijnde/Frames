classdef Split
 % SPLIT split a Frame into groups to apply a function separately group by group
 % Use: df.split(groups[,flags]).<apply,aggregate>(func[,args,flag])
 %      Split(df,groups[,flags]).<apply,aggregate>(func[,args,flag])
 %      Split(cellOfDFs,groups[,flags]).<apply,aggregate>(func[,args,flag])
 %
 % ----------------
 % Parameters:
 %     * df (Frame, cell of Frames)
 %          A single DataFrame or a cell of DataFrames with equal
 %          rows/columns, on which the function 'func' is applied.
 %     * groups (frames.Groups)
 %          Object that contains keys and values describing
 %          groups. Please refer to the documentation of
 %          frames.Groups for more details.
 %     * flags: 'allowOverlaps', 'allowNonExhaustive'
 %          Split throws an error if there are overlaps in the
 %          group values, and if they do not span the whole set
 %          of the Index values. Allow these cases by respectively
 %          adding the flags 'allowOverlaps' and 'allowNonExhaustive'
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
        
        dfIsCell = false
    end
    
    methods
        function obj = Split(df, groups, varargin)
            % SPLIT Split(df,groups[,flags])
            if iscell(df)
                assert(all(isFrame(df{:})),'df must be a cell of frames.DataFrame')
                assert(isaligned(df{:}),'dfs must be aligned')
                obj.dfIsCell = true;
            else
                assert(isa(df,'frames.DataFrame'),'df must be a frames.DataFrame')
            end
            assert(isa(groups,'frames.Groups'),'group must be a frames.Group')
            obj.df = df;
            obj.groups = groups;
            
            if groups.constantGroups
                allowOverlaps = parseFlag('allowOverlaps',varargin);
                allowNonExhaustive = parseFlag('allowNonExhaustive',varargin);
                allElements = [groups.values{:}];
                if ~allowOverlaps && ~isunique(allElements)
                    error('frames:SplitOverlap','There are overlaps in Split')
                end
                if ~allowNonExhaustive 
                    if groups.isColumnGroups 
                        toSplit = obj.applyToPotentialCell(df, @(x) x.columns(:,1), true); 
                    else
                        toSplit = obj.applyToPotentialCell(df, @(x) x.rows(:,1), true); 
                    end
                    allElements = [allElements,groups.groupless];
                    if any(~ismember(toSplit,allElements))
                        error('frames:SplitNonexhaustive','Split is not exhaustive')
                    end
                end
            else
                rows = obj.applyToPotentialCell(df, @(x) x.getRowsObj(), true); 
                cols = obj.applyToPotentialCell(df, @(x) x.getColumnsObj(), true); 
                assert(isequaln(groups.frame.rows,rows),'Groups:rowsMisaligned','group rows must be aligned with the Frame')
                assert(isequaln(groups.frame.columns,cols),'Groups:columnsMisaligned','groupc olumns must be aligned with the Frame')
            end
        end
    end
    
    methods
        function other = apply(obj,fun,varargin)
            % APPLY apply a function to each sub-Frame, and returns a single Frame. Maintains the structure of the original Frame.
            %  * fun: function to apply. If Split is on a cell of N Frames,
            %  then the function is of the form f({x1,..,xN},..) 
            %  * flag enum('applyToFrame','applyToData'), 'applyToData' (default):
            %       allows to use DataFrame methods, but may be slower than
            %       applying a function directly to the data with 'applyToData'
            %  * flag 'applyByLine':
            %       allows to pass a function that will be applied line by
            %       line instead of on a matrix (by default)
            % e.g. .apply(@(x) sum(x,2),'applyToData') vs .apply(@(x) x.sum(2),'applyToFrame')
            out = obj.computeFunction(fun,false,varargin{:});
            rows = obj.applyToPotentialCell(obj.df, @(x) x.getRowsObj(), true); 
            cols = obj.applyToPotentialCell(obj.df, @(x) x.getColumnsObj(), true); 
            other = obj.getFirstDataFrame().initCopy(out, rows, cols);   
        end
        function other = aggregate(obj,fun,varargin)
            % AGGREGATE apply a function to each sub-Frame, and returns a single Frame. Returns a single vector for each group.
            %  * fun: function to apply. If Split is on a cell of N Frames,
            %  then the function is of the form f({x1,..,xN},..) 
            %  * flag enum('applyToFrame','applyToData'), 'applyToData' (default):
            %       allows to use DataFrame methods, but may be slower than
            %       applying a function directly to the data with 'applyToData'
            %  * flag 'applyByLine':
            %       allows to pass a function that will be applied line by
            %       line instead that on a matrix (by default)
            % e.g. .aggregate(@(x) sum(x,2),'applyToData') vs .aggregate(@(x) x.sum(2),'applyToFrame')
            out = obj.computeFunction(fun,true,varargin{:});            
            if obj.groups.isColumnGroups
                rows = obj.applyToPotentialCell(obj.df, @(x) x.getRowsObj(), true); 
                other = obj.getFirstDataFrame().initCopy(out, rows, obj.groups.keys);               
            else
                cols = obj.applyToPotentialCell(obj.df, @(x) x.getColumnsObj(), true); 
                other = frames.DataFrame(out, obj.groups.keys, cols);  % init default DataFrame class as groups are an ordinary Index
            end
        end
    end
    methods(Access=protected)
        
        function df = getFirstDataFrame(obj)
            % return first dataframe stored
            if ~iscell(obj.df)
                df = obj.df;
            else
                df = obj.df{1};
            end
        end
        
        function out = computeFunction(obj,fun,reduceDim,varargin)           
            [applyToFrameFlag,varargin] = parseFlag('applyToFrame',varargin);
            [applyToDataFlag,varargin] = parseFlag('applyToData',varargin);

            condFlags = [applyToFrameFlag,applyToDataFlag];
            if all(condFlags)
                error('frames:splitapply:flag','Choose one flag only.')
            elseif condFlags(1)
                applyToFrame = true;
            else
                applyToFrame = false;
            end
            [applyByLine,varargin] = parseFlag('applyByLine',varargin);
            
            dfdata = obj.applyToPotentialCell(obj.df, @(x) x.data, false); 
            sz = obj.applyToPotentialCell(dfdata, @(x) size(x), true); 
            if applyByLine
                if obj.groups.isColumnGroups
                    indexLoop = 1:sz(1);
                else
                    indexLoop = 1:sz(2);
                end
            elseif obj.groups.constantGroups
                indexLoop = ':';
            end
            
            if applyToFrame
                keyiscell = iscell(obj.groups.keys);
            end
            
            firstIteration = true;
            for ii = 1:length(obj.groups.values)
                gVal = obj.groups.values{ii};
                if obj.groups.constantGroups
                    if obj.groups.isColumnGroups
                        colID = obj.applyToPotentialCell(obj.df, @(x) x.getColumnsObj().positionOf(gVal), true); 
                    else
                        rowID = obj.applyToPotentialCell(obj.df, @(x) x.getRowsObj().positionOf(gVal), true); 
                    end
                elseif ~applyByLine
                    gVal = full(gVal);  % for performance reasons, better to work with non sparse matrices
                    if obj.groups.isColumnGroups
                        [uniqueGroups,sameVals,indexLoop] = local_idxSameData(gVal);
                    else
                        [uniqueGroups,sameVals,indexLoop] = local_idxSameData(gVal');
                    end
                end
                if applyToFrame
                    if keyiscell, description = obj.groups.keys{ii}; 
                    else, description = obj.groups.keys(ii); end
                    s.type = '.'; s.subs = 'description';
                    obj.df = obj.applyToPotentialCell(obj.df, @(x) x.subsasgn(s,description), false); 
                end
                for idx = indexLoop
                    if obj.groups.constantGroups
                        if obj.groups.isColumnGroups
                            rowID = idx;
                        else
                            colID = idx;
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
                        val = obj.applyToPotentialCell(obj.df, @(x) x.iloc_(rowID,colID), false); 
                        res = fun(val,varargin{:});
                        res = local_getData(res);
                    else
                        val =  obj.applyToPotentialCell(dfdata, @(x) x(rowID,colID), false); 
                        res = fun(val,varargin{:});
                    end
                    if firstIteration
                        dataType = str2func(class(res));
                        if reduceDim
                            if obj.groups.isColumnGroups
                                out = repmat(dataType(missing),sz(1),length(obj.groups.keys));
                            else
                                out = repmat(dataType(missing),length(obj.groups.keys),sz(2));
                            end
                        else
                            out = repmat(dataType(missing),sz);
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
                        [lenIdx,lenCol] = obj.applyToPotentialCell(val,@size,true);
                        out(rowID,colID) = repmat(res,1+lenIdx-size(res,1),1+lenCol-size(res,2));
                    end
                end
            end
        end
        
        function varargout = applyToPotentialCell(obj,data,func,onlyFirst)
            if ~obj.dfIsCell
                [varargout{1:nargout}] = func(data);
            elseif onlyFirst
                [varargout{1:nargout}] = func(data{1});
            else
                varargout{1} = cellfun(func,data,UniformOutput=false);
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
if isFrame(data), data = data.data; end
end

