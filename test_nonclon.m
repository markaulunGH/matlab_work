
load_water      =[0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1];


nonlcon(x,work_no_load,full_load)

%设置非线性约束
function [c,ceq] = nonlcon(x,work_no_load,full_load)
%     c = []; % no inequality constraints
%     ceq = [max(0, x(1) - 5), max(0, -x(1) + 10)]; % equality constraints to bound x1 in [0,5] and [10,15]

if full_load 
    c=[];
else
    c=zeros(1,length(x));
    for i=1:length(x)
        if work_no_load(i)==1
            %c(i) =x(i)-177;
            %c(i)=0;
        else
            c(i) =[177-x(i)];
            %c(i)=0;
        end
    end
end
%c=[];
ceq=[];
end