function cp = nancumprod(x)  
cp = cumprod(x,'omitnan');
cp(isnan(x)) = NaN;
end