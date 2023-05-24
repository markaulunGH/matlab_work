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
%最后输出的结果
%最终需要求出水电出力过程，剩余负荷过程，水库下泄流量过程，水库库水位变化过程，还有你的两个优化目标等，以上6个必须要有
%电网负荷特性
disp('=======>Running NSGA.m<===========');
MAX_LOAD_POWER=11800;
%设置求解的最小单位（h)（但是没有完工,目前只支持1h
STEP=1;
%夏天冬天负荷率
summer_load_rate=[0.936,0.920,0.912,0.890,0.900,0.936,0.953,0.957,0.959,0.948,0.952,0.967,0.958,0.951,0.969,0.965,0.982,0.970,0.956,0.949,1.000,0.991,0.964,0.950];
winter_load_rate=[0.901,0.899,0.881,0.880,0.883,0.918,0.920,0.945,0.955,0.982,0.957,0.981,0.969,0.962,0.939,0.908,0.928,0.971,1.000,0.993,0.989,0.984,0.919,0.895];
%不能24小时全天发电的时候，不出力的时间
load_no_water      =[0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
%夏天的范围
TYPE_SUMMER =[0,0,0,0,0,1,1,1,1,1,1,0];
summer_load =summer_load_rate*MAX_LOAD_POWER;
winter_load =winter_load_rate*MAX_LOAD_POWER;
%定义一下是不是设置用水小于或等于来水，为零表示
USE_LESS_EQUAL_IN=1;
USE_POPULATIONS=50;
USE_MAX_GENS=600;

%使用一个二维表格记录每个月输出的5个数据
%24小时的流量数据

%定义目标函数；水电出力最大；系统剩余负荷波动最小

if exist('./source_data/ga_out_LESS.mat','file')==2
    disp("=====>NSGA.m:Pre-saved files exist, select them for consistency.");
    load('./source_data/ga_out_LESS.mat','ga_out_LESS');
else
    disp('=====>NSGA.m:No pre-saved files found, the next one needs to run for 1 to 2 hours');
    fprintf("=====>NSGA.m:population:%d;max Generations:%d.\n",USE_POPULATIONS,USE_MAX_GENS);
for MOUTH_NUM=1:12
    tic;
    t0=cputime;
    Q_in=total_mouth_avg(MOUTH_NUM);
    %水量平衡（等式平衡
    Aeq=ones(1,24);
    beq=24*Q_in;
    A=[];b=[];
    %设置自变量范围
    lb = ones(24,1)*177.001;
    ub = ones(24,1)*1186.2;
    %判断来水是不是够全天发电
    WATER_FULL_LOAD = Q_in >= 177;
    %根据月份判断负载选择，起调节水位
    if TYPE_SUMMER(MOUTH_NUM)==1    
        net_load =summer_load;
        initial_level=2713;
    else
        net_load =winter_load;
        initial_level=2712;
    end
    
    % 泄量上下限两段范围,%设置不同月份的不同的水位范围
    %如果全天可以发电
    if WATER_FULL_LOAD
        %如果平均来流量大于额定发电量
        if Q_in > 1186.2
            %由等式约束变成不等式约束
            Aeq=[];beq=[];
            %设置大于额定发电流量的的情况
            A(1,:)=ones(1,24);
            A(2,:)=ones(1,24)*(-1);
            b=[1186.2*24,-1186.2*24*0.96];
        end
    else%这里是1月和2月不能做到全天发电，%选择几个小时确定不发电，以100生态流量下泄，为了给后面的调节存储一部分水
        %清理自变量范围，需要按照不同的小时设置不同下泄流量
        lb = zeros(24,1)*100;
        ub = zeros(24,1)*100;
        for i=1:length(load_no_water)
            if load_no_water(i) == 1
                lb(i)=100;
                ub(i)=100;
            else
                lb(i)=177.0001;
                ub(i)=1186.2;
            end
        end
    end 
    intcon=[];
    %使来用水小于或等于来水
    if USE_LESS_EQUAL_IN
        %取消等式约束
        Aeq=[];beq=[];
        A=[];
        A(1,:)=ones(1,24);       
        if Q_in > 1186.2
            b=[1186.2*24*0.98,-1186.2*24*0.80];%;;
            A(2,:)=ones(1,24)*(-1);
        else 
            A(2,:)=ones(1,24)*(-1);
            b=[Q_in*24,-Q_in*24*0.80];
        end
        %整数约束,不知道可不可以扩大搜索空间
        intcon=1:1:23;
        %disp("SOLVE USE_LESS_EQUAL_IN");
    end

%     %%%循环求解三个方案%%%
%         %原方案
%     if count==1
%         USE_LESS_EQUAL_IN=0;
%         USE_POPULATIONS=280;
%         USE_MAX_GENS=600;
%         intcon=[];
%     elseif count == 2 %优化方案1
%         USE_LESS_EQUAL_IN=1;
%         USE_POPULATIONS=280;
%         USE_MAX_GENS=1000;
%         intcon=[];
%     else  %优化方案2
%         USE_LESS_EQUAL_IN=1;
%         USE_POPULATIONS=200;
%         USE_MAX_GENS=600;
%     end


    %每月有5个典型日需要计算
    for ty_day=1:5
        fprintf('=====>NSGA.m:Computer Mouth:(%d/12), typical days:(%d/5)\n',MOUTH_NUM,ty_day);
        wind_power=zeros(1,size(all_ty_days_01h,3));
        wind_power(:,:)=all_ty_days_01h(MOUTH_NUM,ty_day,:);
        %如果考虑了限量的上下限限制和水量平衡，那么应该可能暂时不需要考虑设计蓄水位和死水位限制 
        %这里采用保留意见，如果不行
        % 定义 options 结构体,
         x=[];fval=[];population=[];scores=[];
         %output
         %设置option
        options = optimoptions('gamultiobj', 'FunctionTolerance',1e-6,'PopulationSize', USE_POPULATIONS, 'Generations',USE_MAX_GENS,'display','final','UseParallel',true);%final
        % 调用 gamultiobj 函数%,use_rate(x,Q_in)
        %[x, fval,exitflag,output,population,scores] = gamultiobj(@(x)[water_energy(x,Q_in,initial_level,STEP),power_std(x,Q_in,initial_level,STEP,wind_power,net_load)], 24, A, b, Aeq, beq, lb, ub,[] , options);
        [x, fval,exitflag,output,population,scores] = gamultiobj(@(x)[V_water_energy(x,Q_in,initial_level,STEP,wind_power,net_load,WATER_FULL_LOAD)], 24, A, b, Aeq, beq, lb, ub,[] ,intcon, options);
        %反转结果，自带函数仅能求最小值情况，要求最大值需要先转换成负数最后再把结果转换为正数
        %fprintf('Output Generations:%d\n',output.generations);
        %output
        fval_tmp=zeros(size(fval,1),size(fval,2));
        fval_tmp(:,1)=-fval(:,1);
        fval_tmp(:,2)=fval(:,2);
        %fval_tmp(:,3)=fval(:,3);
        %记录输出数据
        if USE_LESS_EQUAL_IN
            %clear data
            ga_out_LESS(MOUTH_NUM).fval{ty_day}=[];
            ga_out_LESS(MOUTH_NUM).flow{ty_day}=[];
            ga_out_LESS(MOUTH_NUM).exitflag{ty_day}=[];
            ga_out_LESS(MOUTH_NUM).output{ty_day}=[];
            ga_out_LESS(MOUTH_NUM).population{ty_day}=[];
            ga_out_LESS(MOUTH_NUM).scores{ty_day}=[];

            %write new value
            ga_out_LESS(MOUTH_NUM).fval{ty_day}(1:size(fval_tmp,1),:)=fval_tmp;
            ga_out_LESS(MOUTH_NUM).flow{ty_day}(1:size(x,1),:)=x;
            ga_out_LESS(MOUTH_NUM).exitflag{ty_day}(1)=exitflag;
            ga_out_LESS(MOUTH_NUM).output{ty_day}=output;
            ga_out_LESS(MOUTH_NUM).population{ty_day}(:,:)=population;
            ga_out_LESS(MOUTH_NUM).scores{ty_day}(:,:)=scores;

        else
            %clear data
            ga_out(MOUTH_NUM).fval{ty_day}=[];
            ga_out(MOUTH_NUM).flow{ty_day}=[];
            ga_out(MOUTH_NUM).exitflag{ty_day}=[];
            ga_out(MOUTH_NUM).output{ty_day}=[];
            ga_out(MOUTH_NUM).population{ty_day}=[];
            ga_out(MOUTH_NUM).scores{ty_day}=[];
            %write new value
            ga_out(MOUTH_NUM).fval{ty_day}(1:size(fval_tmp,1),:)=fval_tmp;
            ga_out(MOUTH_NUM).flow{ty_day}(1:size(x,1),:)=x;
            ga_out(MOUTH_NUM).exitflag{ty_day}(1)=exitflag;
            ga_out(MOUTH_NUM).output{ty_day}=output;
            ga_out(MOUTH_NUM).population{ty_day}(:,:)=population;
            ga_out(MOUTH_NUM).scores{ty_day}(:,:)=scores;
        end

       
    end
    cpu_time=cputime-t0;
    clock_time=toc;
    fprintf('CPU_time:%f s;clock_time:%f s.\n',cpu_time,clock_time);

end%for
    disp('=====>NSGA.m:Save var:ga_out_LESS to ./source_data/ga_out_LESS.mat.');
    save('./source_data/ga_out_LESS.mat','ga_out_LESS');

end%if
disp('=======>NSGA.m:Done.<========');

%     %原方案
%     if count==1     
%         ga_out_1=ga_out;
%     elseif count == 2 %优化方案1
%         ga_out_LESS_2=ga_out_LESS;      
%     else  %优化方案2
%         ga_out_LESS_3=ga_out_LESS;      
%     end
% 
% 
%end
%run('Pareto.m');


%根据流量线性内插计算尾水位
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

%可能使用全局变量不太好因此把两个适应度函数合成一个适应度函数以减少计算时间
%计算水电每时段出力，step是以小时为基本单位
%还需要计算每时刻的水位
%如果需要每次确定上游的水位应该怎么确定呢，上游水位不仅与入库流量，下泄流量有关，还与上段时间时间结尾水位有关
%这里可以使用一个全局变量来实现记录上一刻的水位的功能 
%这里得知适应度函数的x是向量
%Q_out 是 X，是一个行向量
%Q_in，inital,step是一个数
%以每小时出力为一个序列
%wind_power,net_load均是一个数组
%WORK_FULL_DAY只有0或者1两个值，表示来水能不能是当天24小时都发电
function fitness=V_water_energy(Q_out,Q_in,initial_level,step,wind_power,net_load,WORK_FULL_DAY)
    %初始化一些数据
    %(2.39*1000*1000*100)是水库的可调库容，5是可调库容对应水位变化范围
    volume_per_meter=(2.39*1000*1000*100/5);
    hydro_energy=zeros(1,24/step);
    change_volume=zeros(1,24/step);
    change_level=zeros(1,24/step);
    last_level=initial_level;
    step_time=step*3600;%每个时段的秒数
    %将入库流量扩展成一个向量，方便后面计算
    Q_in_group=ones(1,24/step)*Q_in;
    %循环长度（这里是24）
    len = 24/step;
    %出力效率取0.9
    rate=0.90;
    %计算每个时段水库内水的体积改变量
    change_volume = (Q_in_group - Q_out)*step_time;
    %计算每个时段水库内水的水位改变量，
    change_levlel = change_volume /volume_per_meter;
    %分离不同天，可以减少if 判断的次数
    if WORK_FULL_DAY
        for i = 1:len
            hydro_energy(i)=last_level+change_levlel(i)/2-end_level(Q_out(i));%这里只计算不能并行的部分，这里是计算时段平均水位差
            last_level = last_level+change_levlel(i);%记录上一时段的水位
        end
    else
        for i = 1:len
            if Q_out(i) < 177  %如果下泄流量小于最小发电流量，那么将不进行发电
                hydro_energy(i)=0;
            else
                hydro_energy(i)=last_level+change_levlel(i)/2-end_level(Q_out(i));%这里只计算不能并行的部分，这里是计算时段平均水位差
            end
            last_level = last_level+change_levlel(i);
        end

    end

    hydro_energy=(hydro_energy.*Q_out*rate)*9.8*step/1000;     %计算出力并且 kw==>MW
    remain_power=net_load-hydro_energy-wind_power;  %计算剩余负荷
    load_std=std(remain_power);                     %剩余负荷波动标准差
    %计算平均每个时段出力
    energy=-mean(hydro_energy);                     
    %添加剩余负荷差波动范围最小
    %peak_diff=(max(remain_power)-min(remain_power))*0.4;
    %组合两个优化目标，使两个适应度函数缩减为一个，减少中间重复计算的部分，提高性能
    fitness = [energy, load_std];
    
end



%添加适应函数之来水利用率，目前没有添加，之前添加过后效果也不太理想
%此函数没有使用
function rate =use_rate(Q_out,Q_in)
    rate= (-sum(Q_out)/(Q_in*24))*100;
end


