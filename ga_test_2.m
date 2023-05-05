% 目标函数，使用两个目标函数
obj = @(x) [x(1)^2+x(2)^2, (x(1)-1)^2+x(2)^2];

% 约束条件，使用四个约束条件
constr = @(x) [x(1)^2 + x(2)^2 - 1, (x(1)-1)^2 + x(2)^2 - 1, x(1) + x(2) - 1, -x(1) - x(2) + 1];

% 定义问题的变量范围和约束条件
lb = [-1, -1];
ub = [2, 2];
options = optimoptions('gamultiobj', 'PlotFcn', @gaplotpareto);

% 运行多目标遗传算法
[x, fval] = gamultiobj(obj, 2, [], [], [], [], lb, ub, constr, options);

% 绘制Pareto前沿图
scatter(fval(:,1), fval(:,2), 'filled');
xlabel('f_1');
ylabel('f_2');
title('Pareto Front');
