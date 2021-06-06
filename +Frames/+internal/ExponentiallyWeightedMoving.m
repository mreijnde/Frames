classdef ExponentiallyWeightedMoving
    
    properties(Access=protected)
        df
        alpha
    end
    
    methods
        function obj = ExponentiallyWeightedMoving(df,type,val)
            obj.alpha = exponentialWeight(type,val);
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
        case 'Window'
            alpha = 2./(value+1);
        case 'Span'
            alpha = 2./(value+1);
        case 'Halflife'
            alpha = 1-exp(log(0.5)./value);
        case 'Com'
            alpha = 1./(value+1);
        otherwise
            error('Type is unknown!')
    end
end
