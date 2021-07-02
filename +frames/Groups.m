classdef Groups < dynamicprops
 % GROUPS split a list by assigning its elements to predefined groups.
 % Use: groups = frames.Groups(listToSplit[,groupStructure])
 % The properties of groups are the fields of the groupStructure.
 %
 % Use a Groups in df.split(groups[,desiredGroups]) to split df into
 % groups, column-wise.
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
 % See also: frames.internal.Split
    properties(Access=protected)
        protectedStructure_
    end
    methods(Access=protected, Static)
        function s = defineGroups(varargin)
            % group structure can be defined in a subclass
            % Must return a struct with group names as fields and a list of
            % the elements in a group as values: : s.groupName = listOfelementsInGroup
            s = varargin{:};
        end
    end
    methods
        function obj=Groups(listOfElements,varargin)
            % Groups(listOfElements[,groupStructure])
            narginchk(1,2)
            obj.protectedStructure_ = obj.getGroupStructure(varargin{:});
            
            areValid = ismember(listOfElements,obj.getAllElements());  % check if all inputs are found somewhere in the groups
            if ~all(areValid)
                error("[%s] are not valid.", listOfElements(~areValid));
            end
            s = obj.protectedStructure_;
            for f = fields(s)'  % put elements of listOfElements into groups (properties)
                f_ = f{1};
                obj.addprop(f_);
                obj.(f_) = obj.isinGroup(listOfElements,s.(f_));
            end
            % ToDo: With Matlab2021a, the order of dynamic properties 
            % (from fieldnames(obj)) seem to be stable, but not alphabetical.
            % Make sure in future versions there is no change.
        end
        function allNames = getAllElements(obj)
            s = obj.protectedStructure_;
            allValues = cellfun(@(f)s.(f),fieldnames(s),'uni',0);
            allNames = unique([allValues{:}]);
        end
    end
    
    methods(Access=private)
        function s = getGroupStructure(obj,varargin)
            s = obj.defineGroups(varargin{:});
            assert(isstruct(s), 'defineGroups must return a struct')
        end
    end
    methods(Access=private, Static)
        function li = isinGroup(listOfElements,group)
            belongsTo = ismember(listOfElements,group);
            li = listOfElements(belongsTo);
        end
    end
end