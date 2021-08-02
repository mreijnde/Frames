function bool = quickissorted(s,idnew)
tf=false(length(s)+2,3);
tf(idnew,1)=true;
tf(idnew+1,2)=true;
tf(idnew+2,3)=true;
tf=any(tf(2:length(s)+1,:),2);
bool=issorted(s(tf));

end