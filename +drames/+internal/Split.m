classdef Split < dynamicprops

    properties(Access=private)
        nameOfProperties_
    end
    
    methods (Access=?frames.DataFrame)
        function obj = Split(df,splitter,nameOfProperties)
            if isa(splitter, 'frames.Groups') || isa(splitter,'struct')
                if nargin < 3
                    nameOfProperties = fieldnames(splitter);
                else
                    assert(all(ismember(nameOfProperties,fieldnames(splitter))), ...
                        'The names of the properties must be found in the splitter');
                end
                splitter_ = {};  % turn it into a cell
                for ii=1:length(nameOfProperties)
                    splitter_{ii} = splitter.(string(nameOfProperties(ii))); %#ok<AGROW>
                end
                splitter = splitter_;
            end
            assert(length(nameOfProperties) == length(splitter), ...
                'The names of the properties are not of the same length as the splitter')
            obj.nameOfProperties_ = nameOfProperties;
            for ii = 1:length(splitter)  % groups df into properties
                cols = splitter{ii};
                propName = obj.nameOfProperties_{ii};
                propValue = df(:,cols);
                propValue.name = propName;
                obj.addprop(propName);
                obj.(propName) = propValue;
            end
            
            splitterData = [splitter{:}];
            if ~frames.internal.isunique(splitterData)
                warning('frames:SplitOverlap','There are overlaps in Split')
            end
            if any(~ismember(df.columns,splitterData))
                warning('frames:SplitNonexhaustive','Split is not exhaustive')
            end
        end

        function res = apply(obj,fun,varargin)
            props = obj.nameOfProperties_;
            isVectorOutput = true;  % if the output of fun returns a vector
            for ii = 1:length(props)
                res_ = fun(obj.(props{ii}),varargin{:});
                if ii == 1
                    res = res_;
                else
                    warning('off','frames:Index:notUnique')
                    res = [res,res_]; %#ok<AGROW>
                end
                if length(res_.columns) > 1
                    isVectorOutput = false;
                end
            end
            if isVectorOutput, res.columns = props; end
            res.name = "";
            warning('on','frames:Index:notUnique')
        end
    end
    
end