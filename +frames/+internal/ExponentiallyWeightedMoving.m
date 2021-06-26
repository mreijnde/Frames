classdef ExponentiallyWeightedMoving
    
    properties(SetAccess=protected)
        df
        alpha
    end
    
    methods
        function obj = ExponentiallyWeightedMoving(df,typeVal)
            arguments
                df
                typeVal.Alpha, typeVal.Com, typeVal.Window, typeVal.Span, typeVal.Halflife
            end
            args = namedargs2cell(typeVal);
            obj.alpha = exponentialWeight(args{:});
            obj.df = df;
        end
        
        function df = mean(obj)
            df = obj.df;
            df.data = frames.internal.ewma(obj.df.data,obj.alpha);
        end
        function df = std(obj)
            df = obj.df;
            df.data = sqrt(frames.internal.emvar(obj.df.data,obj.alpha));
        end
        function df = var(obj)
            df = obj.df;
            df.data = frames.internal.emvar(obj.df.data,obj.alpha);
        end

    end
end

function alpha = exponentialWeight(type,value)
% Similar naming as in pandas
    switch type
        case 'Alpha'
            alpha = value;
        case 'Com'  % center of mass
            alpha = 1./(value+1);
        case 'Window'  % similar to the SMA window, see https://en.m.wikipedia.org/wiki/Moving_average#Relationship_between_SMA_and_EMA
            alpha = 2./(value+1);
        case 'Span'
            alpha = 2./(value+1);
        case 'Halflife'
            alpha = 1-exp(log(0.5)./value);
        otherwise
            error('Type is unknown!')
    end
end
