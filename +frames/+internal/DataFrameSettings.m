classdef (HandleCompatible) DataFrameSettings
    % class defines the DataFrame settings that specifies it behavior
    properties
        allowDimExpansion logical = true
        alignMethod (1,1) string {mustBeMember(alignMethod,["strict", "subset", "keep","full"])} = "strict"
    end
    
    methods
         function obj = DataFrameSettings(settings)             
             % constructor to initialize properties from other DataFrameSettings object (if supplied)
             if nargin>0 && isa(settings, "frames.internal.DataFrameSettings")                     
                 % loop over all defined properties
                 props = properties(settings);
                 for i= 1:length(props)
                     prop = props{i};
                     obj.(prop) = settings.(prop);
                 end                 
             end                 
         end
    end
end