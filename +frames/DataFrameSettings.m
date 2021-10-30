classdef (HandleCompatible) DataFrameSettings
    % class defines the DataFrame settings that specifies it behavior
    properties
        option1 logical = true
        option2 logical = true
        option3 (1,1) string {mustBeMember(option3,["High","Medium","Low"])} = "Low"
    end
    
    methods
         function obj = DataFrameSettings(settings)             
             % constructor to initialize properties from other DataFrameSettings object (if supplied)
             if nargin>0 && isa(settings, "frames.DataFrameSettings")                     
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