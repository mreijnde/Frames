classdef DataFrameSettingsDefault < frames.DataFrameSettings & handle
    % default DataFrame settings that are persistent
    
    % (properties, and the defaults inherited from DataFrameSettings)
    
    methods
        function reset(obj)
            % resets stored properties to default 'out-of-the-box' values
            defaultsettings = frames.DataFrameSettings();
            % loop over all defined properties
            props = properties(defaultsettings);
            for i= 1:length(props)
                prop = props{i};
                obj.(prop) = defaultsettings.(prop);
            end
        end
    end
    
    
end