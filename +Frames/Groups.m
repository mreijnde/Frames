classdef Groups < dynamicprops
    
    properties(Access=protected)
        protectedStructure_
    end
    methods(Access=protected, Static)
        function s = defineGroups(varargin)
            % group structure can be defined in a subclass
            s = varargin{:};
        end
    end
    methods
        function obj=Groups(listOfElements,varargin)
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