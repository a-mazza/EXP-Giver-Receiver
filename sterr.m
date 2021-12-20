function y = sterr(x)
s = std(x);
n = length(x);
se = s/sqrt(n);
y = se;
return