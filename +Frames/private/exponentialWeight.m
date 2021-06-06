function [alpha,windowSize] = exponentialWeight(type,value)
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
    windowSize =2./alpha-1;
end