function tr = timerangeFromString(dates,format)
dates = string(dates);
if dates(1) == "", dates(1) = "-inf"; end
if dates(2) == "", dates(2) = "inf"; end
dates = datetime(dates,'InputFormat',format);
tr = timerange(dates(1),dates(2),'closed');
end