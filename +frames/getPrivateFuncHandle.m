function fh = getPrivateFuncHandle(funcname)
  % helper function to access private package functions for unit-tester
  % (do not use in own code)
  fh = str2func(funcname);
end