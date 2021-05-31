function cp = nancumsum(x)  
cp = cumsum(x,'omitnan');
cp(isnan(x)) = NaN;
end