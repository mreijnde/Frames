classdef (HandleCompatible) DataFrameSettings
    % class defines the DataFrame settings that specifies it behavior
    properties
        allowDimExpansion logical = true
        alignMethod (1,1) string {mustBeMember(alignMethod,["strict", "inner", "left", "full","strictunique"])} = "strict"
                             % defines how indices are aligned in math operation between DataFrames:
                             % -  "strict":  both need to have same indices (else error thrown)
                             % -  "inner":   remove index values that are not common in both
                             % -  "left":    keep indices as in left DataFrame in operation (default)            
                             % -  "full":    keep all indices values (allow missing values in indices in both)
                       
        duplicateOption (1,1) string ...
                        {mustBeMember(duplicateOption,["none", "unique", "duplicates","duplicatesstrict"])} ...
                        = "duplicatesstrict"
                             % defines how duplicate values in indices are handled in math operation on DataFrames:                             
                             %  - "none":             no operations with duplicates allowed
                             %  - "unique":           removes duplicates, only use first occurrence of duplicate value
                             %  - "duplicatestrict":  only allow duplicates in case of equal indices
                             %  - "duplicates":       align duplicates in order of occurrence between indices
                             %                        (first occurrence duplicate value in one index is matched to 
                             %                         1st occurence in other, 2nd occurence to 2nd etc)                              
        
        forceMultiIndex logical = false
                             % automatically convert DataFrame indices to MultiIndex
                             % in DataFrame constructor. With this option the extra {} are not needed
                             % rows and column input to create MultiIndex indices.                                          
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