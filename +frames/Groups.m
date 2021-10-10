classdef Groups
 % GROUPS split a list by assigning its elements to predefined groups.
 % Use: groups = frames.Groups(groups[,listToSplit])
 %
 % Use a Groups in df.split(groups) to split df into groups, column-wise.
 %
 % ----------------
 % Parameters:
 %     * listOfElements: (string)
 %          List of elements we want to split into groups
 %     * groupStructure: (structure) 
 %          Structure a the groups. Fields are group names, values are the
 %          elements belonging to each group: s.groupName = listOfelementsInGroup.
 %          One can derive a class from Groups to directly specify the
 %          groupStructure by overriding the method 'defineGroups'. In such
 %          a case, 'groupStructure' is not required.
 %
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
            % Groups(groups,dimensionFlag)
            if nargin == 2
                assert(ismember(dimensionFlag, ["columnGroups","rowGroups"]), 'frames:Groups:flag', ...
                    'The dimension flag must be in ["columnGroups","rowGroups"]')
                if flagDimension == "rowGroups"
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
                [obj.keys, obj.values] = local_groupToKeyVal(groups);
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
        
        function obj = assignElements(obj, elementsToGroup)
            %returns a Group wiht only the keys and values contained in the list elementsToGroup
            areValid = ismember(elementsToGroup,obj.getAllElements());  % check if all inputs are found somewhere in the groups
            if ~all(areValid)
                error("[%s] are not valid.", elementsToGroup(~areValid));
            end
            toKeep = [];
            for ii = 1:length(obj.keys)
                elementsToKeep = local_foundIn(elementsToGroup, obj.values{ii});
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

function li = local_foundIn(listOfElements,group)
belongsTo = ismember(listOfElements,group);
li = listOfElements(belongsTo);
end

function [keys, values] = local_groupToKeyVal(g,isColumnGroups)
switch class(g)
    case 'struct'
        keys = fieldnames(g)';
        values = struct2cell(g)';
    case 'cell'
        keys = "Group" + (1:length(g));
        values = g;
    case 'containers.Map'
        keys = keys(g); %#ok<NODEF>
        values = values(g); %#ok<NODEF>
    case 'frames.DataFrame'
        [keys,~,ikeys] = unique(g.data,'stable');
        keys(ismissing(keys)) = [];
        values = cell(1,length(keys));
        if isColumnGroups, vals = g.columns; else, vals = g.rows; end
        for ii = 1:length(keys)
            values{ii} = vals(ikeys==ii);
        end
end
end

function gps = local_findgroups(varargin)
for ii = 1:nargin, varargin{ii}.data = string(varargin{ii}.data); end
[dfs{1:nargin}] = frames.align(varargin{:});
dfsdata = cell(1,nargin);
for ii = 1:nargin, dfsdata{ii} = dfs{ii}.data(:); end
gps = findgroups(dfsdata{:});
gps = reshape(gps,size(dfs{1}));
gps = dfs{1}.constructor(gps,dfs{1}.getRowsObj(),dfs{1}.getColumnsObj());
end
