classdef Groups
 % GROUPS provide a uniform object for key-value groups.
 % Use: groups = frames.Groups(groups[,dimensionFlag])
 %
 % Use a Groups in df.split(groups) to split a DataFrame into groups, to then apply
 % a function group by group.
 %
 % ----------------
 % Properties:
 %     * keys: List of the names of the groups
 %     * values (cell): Elements in each group, with the same order as
 %     their corresponding key.
 %     * isColumnGroups (logical): whether groups represent columns or rows
 %     * constantGroups (logical): whether groups are constant
 %
 % Parameters:
 %     * groups: enum(struct,containers.Map,cell,frames.DataFrame)
 %          Used to assign Groups keys and values properties.
 %          - struct: keys and values are resp. fields and values of the struct
 %          - containers.Map: keys and values are resp. keys and values of the containers.Map
 %          - cell: keys are generic ["Group1","Group2",...] and values are the elements in the cell
 %          - frames.DataFrame (series): keys are unique data values, values are lists of index elements related to the same key
 %          - frames.DataFrame:  keys are unique data values, values are sparse logical matrices of the position of the related key
 %
 %     * dimensionFlag: enum("columnGroups","rowGroups") specify whether groups represent columns or rows
 %
 % Methods:
 %     * select
 %           select a subset of Groups from keys
 %     * get 
 %           get the values associated with the key
 %     * shrink 
            % return a shrunk Groups with only a subset of values and their associated keys
 
 % Copyright 2021 Benjamin Gaudin
 % Contact: frames.matlab@gmail.com
 %
 % See also: frames.internal.Split
    properties(SetAccess=protected)
        keys
        values = {}
        isColumnGroups = true
        constantGroups = true
        frame
    end

    methods
        function obj = Groups(groups, dimensionFlag)
            % GROUPS Groups(groups[,dimensionFlag])
            if nargin == 2
                assert(ismember(dimensionFlag, ["columnGroups","rowGroups"]), 'frames:Groups:dimensionFlag', ...
                    'The dimension flag must be in ["columnGroups","rowGroups"]')
                if dimensionFlag == "rowGroups"
                    obj.isColumnGroups = false;
                end
            end
            if iscell(groups) && isFrame(groups{1})
                groups = local_findgroups(groups{:});
            end
            if isFrame(groups) && ~groups.rowseries && ~groups.colseries
                obj.constantGroups = false;
                obj = obj.setFrameSplit(groups);
            else
                [obj.keys, obj.values] = local_groupToKeyVal(groups,obj.isColumnGroups);
            end
            
        end
        
        function obj = select(obj, keys)
            %SELECT select a subset of Groups
            % returns a Groups
            toKeep = findPositionIn(keys,obj.keys);
            obj.keys = obj.keys(toKeep);
            obj.values = obj.values(toKeep);
        end
        function values = get(obj, key)
            %GET get the values associated with the key
            values = obj.values(find(string(key)==string(obj.keys),1));
        end
        
        function obj = shrink(obj, valueSubset)
            % return a shrunk Groups with only the subset of values contained in the list 'valueSubset' and their associated keys
            areValid = ismember(valueSubset,obj.getAllElements());  % check if all inputs are found somewhere in the groups
            if ~all(areValid)
                error("[%s] are not valid.", valueSubset(~areValid));
            end
            valueSubset = valueSubset(:)';
            toKeep = [];
            for ii = 1:length(obj.keys)
                elementsToKeep = intersect(valueSubset, obj.values{ii}, 'stable');
                if ~isempty(elementsToKeep)
                    toKeep = [toKeep, ii]; %#ok<AGROW>
                    obj.values{ii} = elementsToKeep;
                end
            end
            obj.keys = obj.keys(toKeep);
            obj.values = obj.values(toKeep);
        end
        
    end
    
    methods(Access=protected)
        function allElements = getAllElements(obj)
            allElements = unique([obj.values{:}], 'stable');
        end
        
        function obj = setFrameSplit(obj, groups)
            % If groups change along both axis, the values are sparse
            % logical matrices. The index and columns of the original frame
            % are saved as properties.
            gdata = groups.data;
            grps = unique(gdata);
            grps(ismissing(grps)) = [];
            grps = grps(:)';
            obj.keys = grps;
            if iscell(grps)
                grps = string(grps);
                gdata = string(gdata);
            end
            for ii = 1:length(grps)
                obj.values{ii} = sparse(gdata == grps(ii));
            end
            obj.frame.rows = groups.getRowsObj();
            obj.frame.columns = groups.getColumnsObj();
        end
        
    end

end


function [keys, values] = local_groupToKeyVal(g,isColumnGroups)
if isFrame(g)
    data = g.data(:)';
    missingData = ismissing(data);
    [keys,~,ikeys] = unique(data(~missingData),'stable');
    values = cell(1,length(keys));
    if isColumnGroups, vals = g.columns; else, vals = g.rows(:)'; end
    vals = vals(~missingData);
    for ii = 1:length(keys)
        values{ii} = vals(ikeys==ii);
    end
else
    switch class(g)
        case 'struct'
            keys = fieldnames(g)';
            values = struct2cell(g)';
        case 'cell'
            keys = "Group" + (1:length(g));
            values = g;
        case 'containers.Map'
            keys = g.keys;
            values = g.values;  
        otherwise
            error('frames:Groups:setKeyVal', 'format must be struct, cell, containers.Map, or DataFrame')
    end 
end
end

function gps = local_findgroups(varargin)
for ii = 1:nargin, varargin{ii}.data = string(varargin{ii}.data); end
[dfs{1:nargin}] = frames.align(varargin{:});
dfsdata = cell(1,nargin);
for ii = 1:nargin, dfsdata{ii} = dfs{ii}.data(:); end
gpsNumber = findgroups(dfsdata{:});
gps = repmat(string(missing),size(gpsNumber));
nbGrps = max(gpsNumber);
if ~ismissing(nbGrps)
    for ii = 1:nbGrps
        xx = find(gpsNumber==ii);
        gpName = "";
        for jj = 1:numel(dfsdata)
            gpName = gpName + " " + dfsdata{jj}(xx(1));
        end
        gps(xx) = extractAfter(gpName,1);
    end
end
gps = reshape(gps,size(dfs{1}));
gps = dfs{1}.constructor(gps,dfs{1}.getRowsObj(),dfs{1}.getColumnsObj());
end
