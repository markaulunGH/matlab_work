%这个是遗传算法计算两个目标
%1.水电站出力最大，这里可以通过取反实现求最小值即可，可以使用最小的情况
%2.系统剩余负荷最小
%约束条件
%1.水位变化，已经算出来
%2.泄量限制，最大下泄是1186.2，丰水最小下泄300，枯水期最小下泄177
%3.库容约束（已经包含在水位里面）
%4.水电站出力限制（包含在泄量约束里面）
%5.流量约束也已经包含在泄量约束里面
%不知道分钟尺度的能不能搞定，会不会太大了
%观察了一下风力出力数据出力特征，将会对风力数据进行出处理，取0.1小时为最小尺度进行计算不过觉得尺度还是大了尝试使用1小时的尺度
%适应度函数就是两个，一个水电站出力，和剩余波动
%电站出力肯定是一天的，总时长是一个定值；入库流量恒定；出库流量是一个变化值，出库流量引起水位变化，因此出库流量是自变量
%剩余负荷波动；负荷的变化算给定的，也不算是变化值；风电场的变化也是给定的，也不算是变化，因此就只有一个流量变化了？
%不等式约束有1.流量的上下限限制（min_flow,max_flow);2.水位限制（不使用水位廊道），需要额外考虑死水位和设计蓄水位；3.日调节水量平衡（等式约束了）,根据起调水位，入库流量，出库流量确定
%水电站出力函数的具体表现形式了,这里可以使用循环求和的方法
%还有一个值得考虑的问题是，求出的水位只是时段初始或者时段末尾的不能算成是时段的平均水位
%电网负荷特性
MAX_LOAD_POWER=11800;
WATER_FULL_LOAD=0;
summer_load_rate=[0.936,0.920,0.912,0.890,0.900,0.936,0.953,0.957,0.959,0.948,0.952,0.967,0.958,0.951,0.969,0.965,0.982,0.970,0.956,0.949,1.000,0.991,0.964,0.950];
winter_load_rate=[0.901,0.899,0.881,0.880,0.883,0.918,0.920,0.945,0.955,0.982,0.957,0.981,0.969,0.962,0.939,0.908,0.928,0.971,1.000,0.993,0.989,0.984,0.919,0.895];
load_no_water      =[0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
summer_load =summer_load_rate*MAX_LOAD_POWER;
winter_load =winter_load_rate*MAX_LOAD_POWER;



%定义目标函数；水电出力最大；系统剩余负荷最小

% 泄量上下限两段范围
%lb = ones(24,1)*100;
% lb = ones(24,2);
% lb(:,1)=ones(24,1)*100;
% lb(:,2)=ones(24,1)*177;


% ub = ones(24,2);
% ub(:,1) = ones(24,1)*100;
% ub(:,2) = ones(24,1)*1186.2;
%等式约束，水量平衡约束
%Aeq=ones(1,24);
Aeq=ones(1,24);
beq=24*total_mouth_avg(MOUTH_NUM);
MOUTH_NUM=2;
%先用4月的
%beq=[24*total_mouth_avg(MOUTH_NUM);100;100;100;100];
%不等式约束
if WATER_FULL_LOAD
    lb = ones(24,1)*177;
    ub = ones(24,1)*1186.2;

else
    
    lb = zeros(24,1)*100;
    ub = zeros(24,1)*100;
   
    for i=1:length(load_no_water)
        if load_no_water(i) == 1
             lb(i)=100;
             ub(i)=100;
        else
            lb(i)=177;
            ub(i)=1186.2;
        end
    end
end
Q_in=total_mouth_avg(MOUTH_NUM);
inital_level=2712;
STEP=1;
wind_power=all_ty_days_01h(MOUTH_NUM,1,:);
net_load =winter_load;
%不等式约束 下泄流量约束
%如果考虑了限量的上下限限制和水量平衡，那么应该可能暂时不需要考虑设计蓄水位和死水位限制
%这里采用保留意见，如果不行
% 定义 options 结构体,
options = optimoptions('gamultiobj', 'PopulationSize', 290, 'Generations', 500, 'Display', 'iter','UseParallel',true);
%设置非线性约束

%x=500;
% 调用 gamultiobj 函数
%[x, fval] = gamultiobj(@(x)multiobjective(x,Q_in,inital_level,STEP,wind_power,net_load), 24, [], [], Aeq, beq, lb, ub, [], options);
[x, fval] = gamultiobj(@(x)[water_energy(x,Q_in,inital_level,STEP),power_std(x,Q_in,inital_level,STEP,wind_power,net_load)], 24, [], [], Aeq, beq, lb, ub,[] , options);%@(x) nonlcon (x,load_no_water,WATER_FULL_LOAD)
% energy=water_energy(x,Q_in,inital_level,STEP);
% std_power=power_std(x,Q_in,inital_level,STEP,wind_power,net_load);
%反转结果
fval_tmp=zeros(size(fval,1),size(fval,2));
fval_tmp(:,1)=-fval(:,1);
fval_tmp(:,2)=fval(:,2);
%根据流量计算尾水位
function level=end_level(Q)
    assert(Q>=40 && Q <= 2000,"Q out of band !");
    if (Q>=40 && Q < 120)
        level=2592+(Q-40)/(120-40);
    elseif (Q >= 120 && Q < 230)
        level=2593+(Q-120)/(230-120);
    elseif(Q>=230 && Q< 400)
        level=2594+(Q-230)/(400 -230);
    elseif(Q>=600 && Q < 900) 
        level=2596+1.1*(Q-600)/(900-600);
    else
        level=2597.1+3.4*(Q-900)/(2000-900);
    end
end


%计算水电每时段出力，step是以小时为基本单位
%还需要计算每时刻的水位
%如果需要每次确定上游的水位应该怎么确定呢，上游水位不仅与入库流量，下泄流量有关，还与上段时间时间结尾水位有关
%这里可以使用一个全局变量来实现记录上一刻的水位的功能 
%这里得知适应度函数的x是向量
%Q_out 是 X
%可能使用全局变量不太好因此把两个适应度函数合成一个
%Q_in，inital,step是一个数
%尝试使用两个
% function [energy,hydro_energy]=water_energy(Q_in,Q_out,inital_level,step)
%     hydro_energy=zeros(24/step,1);
%     last_level=inital_level;
%     len = 24/step;
%     %出力效率取0.9
%     %step为小时数
%     rate=0.90;
%     %这里可以后面考虑改成并行计算
%     for i = 1:len
%         change_volume = (Q_in - Q_out(i))*step*3600;
%         change_levlel = change_volume /(2.39*1000*1000*100);
%         hydro_energy(i)=rate*9.8*Q_out(i)*(last_level+change_levlel/2-end_level(Q_out(i)))*step*3600;
%         hydro_energy(i)=hydro_energy(i)/1000;%kw==>MW
%         last_level = last_level+change_levlel;
%     end
%     %计算总出力
%     energy=-sum(hydro_energy);
%     
% end
% %计算出力最小标准差最小的函数
% %以每小时出力为一个序列
% %其中的water_power 与自变量x有关
% %water,wind_power,net_load均是一个数组
% function load_std=power_std(water_power,wind_power,net_load)
%     %result=zeros(24,1);
%     result =net_load-water_power-wind_power;
%     load_std = std(result);
% end
%两个适应度函数合一

% function [energy, load_std] = multiobjective(x,Q_in,inital_level,step,wind_power,net_load)
%     % 计算水电站出力
%     [energy,hydro_power]=water_energy(Q_in,x,inital_level,step);
% 
%     % 计算出力标准差
%     load_std=power_std(hydro_power,wind_power,net_load);
%     %f=[energy, load_std];
% end
%尝试使用多个适应度函数
function energy=water_energy(Q_out,Q_in,inital_level,step)
    %global hydro_energy;
    hydro_energy=zeros(24/step,1);
    last_level=inital_level;
    len = 24/step;
    %出力效率取0.9
    %step为小时数
    rate=0.90;
    %这里可以后面考虑改成并行计算
    for i = 1:len
        change_volume = (Q_in - Q_out(i))*step*3600;
        change_levlel = change_volume /(2.39*1000*1000*100);
        if Q_out(i) < 177  %如果下泄流量小于最小发电流量，那么将不进行发电
            hydro_energy(i)=0;
            %hydro_energy(i)=rate*9.8*Q_out(i)*(last_level+change_levlel/2-end_level(Q_out(i)))*step/2000;
        else
            hydro_energy(i)=rate*9.8*Q_out(i)*(last_level+change_levlel/2-end_level(Q_out(i)))*step;
            hydro_energy(i)=hydro_energy(i)/1000;%kw==>MW
        end
        last_level = last_level+change_levlel;
    end
    %计算平均每个时段出力
    energy=-mean(hydro_energy);
    
end
%计算出力最小标准差最小的函数%时间可能到了，明天再想想把load_std使用流量输入
%以每小时出力为一个序列
%其中的water_power 与自变量x有关
%water,wind_power,net_load均是一个数组
function load_std=power_std(Q_out,Q_in,inital_level,step,wind_power,net_load)
    result=zeros(24,1);
    hydro_energy=zeros(24/step,1);
    last_level=inital_level;
    len = 24/step;
    %出力效率取0.9
    %step为小时数
    rate=0.90;
    %这里可以后面考虑改成并行计算
    for i = 1:len
        change_volume = (Q_in - Q_out(i))*step*3600;
        change_levlel = change_volume /(2.39*1000*1000*100);
         if Q_out(i) < 177  %如果下泄流量小于最小发电流量，那么将不进行发电
            hydro_energy(i)=0;
            %hydro_energy(i)=rate*9.8*Q_out(i)*(last_level+change_levlel/2-end_level(Q_out(i)))*step/2000;
         else
            hydro_energy(i)=rate*9.8*Q_out(i)*(last_level+change_levlel/2-end_level(Q_out(i)))*step;
            hydro_energy(i)=hydro_energy(i)/1000;%kw==>MW
         end
        last_level = last_level+change_levlel;
        result(i) =net_load(i)-hydro_energy(i)-wind_power(i);
    end
    
    load_std = std(result);
end
%设置非线性约束
function [c,ceq] = nonlcon(x,work_no_load,full_load)

if full_load 
    c=[];
else
    %c=zeros(length(x),1);
    for i=1:length(x)
        if work_no_load(i)==1
            c(i) =x(i)-100.00001;
            %c(i)=0;
        else
            c(i) =177-x(i);
            %c(i)=0;
        end
    end

end
% c=[];
ceq=[];
%ceq(1)=x(4)+x(5)+x(6)+x(24)-101*4;
%ceq(2)=x(2)-177;
% ceq(3)=x(3)-177;
%ceq(4)=x(4)-100;
end

