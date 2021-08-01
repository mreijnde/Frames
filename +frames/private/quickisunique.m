function bool = quickisunique(u,idnew)
v=u(idnew);
u(idnew)=[];
bool=isunique(v)&~any(ismember(v,u));
end