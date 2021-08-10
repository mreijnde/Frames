function s = publicProps2struct(obj,nameArg)
arguments
    obj, nameArg.Skip
end
for f = fields(obj)'
    f_ = f{1};
    if any(strcmp(f_,nameArg.Skip))
        continue
    end
    s.(f_) = obj.(f_);
end
end