% 定义目标函数和约束条件
obj_func = @(x) [x(1)^2 + x(2)^2, -x(1)*x(2)];
constr = @(x) [x(1) + x(2) - 2; -x(1) - x(2) + 2; x(1) - 0.5; x(2) - 0.5];

% 定义优化参数
nvars = 2;              % 变量个数
lb = [-10, -10];        % 变量下限
ub = [10, 10];          % 变量上限
options = optimoptions('gamultiobj', 'PopulationSize', 100, 'MaxGenerations', 50, ...
    'FunctionTolerance', 1e-4, 'ConstraintTolerance', 1e-4);

% 使用NSGA-II算法求解多目标优化问题
[x, fval] = gamultiobj(obj_func, nvars, [], [], [], [], lb, ub, constr, options);

% 绘制Pareto前沿
scatter(fval(:,1), fval(:,2));
xlabel('Objective 1');
ylabel('Objective 2');
title('Pareto Front');
