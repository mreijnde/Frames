classdef ExponentiallyWeightedMoving
    % Provide exponential weighted functions.
    %
    % ExponentiallyWeightedMoving methods:
    %   mean    - exponentially weighted moving mean
    %   std     - exponentially weighted moving standard deviation
    %   var     - exponentially weighted moving variance
    %
    % Constructor:
    % ExponentiallyWeightedMoving(df,<DecayType>=value)
    %
    % The decay type is to be specified using one of the following:
    % Alpha: specify the smoothing factor directy
    % Com: specify the center of mass, alpha=1./(com+1)
    % Window: specify the window related to a SMA, alpha=2./(window+1)
    % Span: specify decay in terms of span, alpha=2./(span+1)
    % Halflife: specify decay in terms of half-life, alpha=1-exp(-log(0.5)./halflife);
    
    properties(SetAccess=protected)
        df
        alpha
    end
    
    methods
        function obj = ExponentiallyWeightedMoving(df,typeVal)
            % ExponentiallyWeightedMoving(df,DecayType=value)
            arguments
                df
                typeVal.Alpha, typeVal.Com, typeVal.Window, typeVal.Span, typeVal.Halflife
            end
            args = namedargs2cell(typeVal);
            obj.alpha = exponentialWeight(args{:});
            obj.df = df;
        end
        
        function df = mean(obj)
            % exponentially weighted moving mean
            df = obj.df;
            df.data = frames.internal.ewma(obj.df.data,obj.alpha);
        end
        function df = std(obj)
            % exponentially weighted moving standard deviation
            df = obj.df;
            df.data = sqrt(frames.internal.emvar(obj.df.data,obj.alpha));
        end
        function df = var(obj)
            % exponentially weighted moving variance
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
            alpha = 1-exp(-log(0.5)./value);
        otherwise
            error('Type is unknown!')
    end
end
