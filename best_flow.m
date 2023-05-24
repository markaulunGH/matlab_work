%试算最佳流量
%试算就去两个月的5个典型出力场景进行试算，仅仅使用等式约束
%电网负荷特性
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
USE_LESS_EQUAL_IN=0;
MAX_BEST_FLOW=290;
MIN_BEST_FLOW=180;
FLOW_STEP=10;
USE_POPULATIONS=11;
USE_MAX_GENS=600;
elapsed_time_LESS=zeros(2,100);
%设置空的，解决保存的时候提示没有
ga_out_SUMMER=[];
ga_out_WINTER=[];

%使用一个二维表格记录每个月输出的5个数据
%24小时的流量数据

%定义目标函数；水电出力最大；系统剩余负荷波动最小
tic
t0=cputime;
for tmp_count=1:2
    if tmp_count ==1 
        MOUTH_NUM=7;
    else
        MOUTH_NUM=1;
    end
for FLOW_TMP=MIN_BEST_FLOW:FLOW_STEP:MAX_BEST_FLOW
    NO_FLOW_NUM=((FLOW_TMP-MIN_BEST_FLOW)/FLOW_STEP)+1;
    Q_in=FLOW_TMP;
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
    

    %如果平均来流量大于额定发电量
    if Q_in > 1186.2 || Q_in < 180
        assert(0);
    end

    intcon=1:1:23;


    %每月有5个典型日需要计算
    for ty_day=1:5
        fprintf('Computer Mouth:(%d/12), typical days:(%d/5);STEP_FLOW:%d;MIN_FLOW:%d,MAX_FLOW:%d,NOW_FLOW:%d.\n',MOUTH_NUM,ty_day,FLOW_STEP,MIN_BEST_FLOW,MAX_BEST_FLOW,Q_in);
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
        fprintf('Output Generations:%d\n',output.generations);
        %output
        fval_tmp=zeros(size(fval,1),size(fval,2));
        fval_tmp(:,1)=-fval(:,1);
        fval_tmp(:,2)=fval(:,2);
        %fval_tmp(:,3)=fval(:,3);
        %记录输出数据
        
        if tmp_count==1
        %clear data
        ga_out_SUMMER(NO_FLOW_NUM).fval{ty_day}=[];
        ga_out_SUMMER(NO_FLOW_NUM).flow{ty_day}=[];
        ga_out_SUMMER(NO_FLOW_NUM).exitflag{ty_day}=[];
        ga_out_SUMMER(NO_FLOW_NUM).output{ty_day}=[];
        ga_out_SUMMER(NO_FLOW_NUM).population{ty_day}=[];
        ga_out_SUMMER(NO_FLOW_NUM).scores{ty_day}=[];
        %write new value
        ga_out_SUMMER(NO_FLOW_NUM).fval{ty_day}(1:size(fval_tmp,1),:)=fval_tmp;
        ga_out_SUMMER(NO_FLOW_NUM).flow{ty_day}(1:size(x,1),:)=x;
        ga_out_SUMMER(NO_FLOW_NUM).exitflag{ty_day}(1)=exitflag;
        ga_out_SUMMER(NO_FLOW_NUM).output{ty_day}=output;
        ga_out_SUMMER(NO_FLOW_NUM).population{ty_day}(:,:)=population;
        ga_out_SUMMER(NO_FLOW_NUM).scores{ty_day}(:,:)=scores;
        else
        ga_out_WINTER(NO_FLOW_NUM).fval{ty_day}=[];
        ga_out_WINTER(NO_FLOW_NUM).flow{ty_day}=[];
        ga_out_WINTER(NO_FLOW_NUM).exitflag{ty_day}=[];
        ga_out_WINTER(NO_FLOW_NUM).output{ty_day}=[];
        ga_out_WINTER(NO_FLOW_NUM).population{ty_day}=[];
        ga_out_WINTER(NO_FLOW_NUM).scores{ty_day}=[];
        %write new value
        ga_out_WINTER(NO_FLOW_NUM).fval{ty_day}(1:size(fval_tmp,1),:)=fval_tmp;
        ga_out_WINTER(NO_FLOW_NUM).flow{ty_day}(1:size(x,1),:)=x;
        ga_out_WINTER(NO_FLOW_NUM).exitflag{ty_day}(1)=exitflag;
        ga_out_WINTER(NO_FLOW_NUM).output{ty_day}=output;
        ga_out_WINTER(NO_FLOW_NUM).population{ty_day}(:,:)=population;
        ga_out_WINTER(NO_FLOW_NUM).scores{ty_day}(:,:)=scores;    
%         
        end

       end
    elapsed_time_LESS(:,NO_FLOW_NUM)=[cputime-t0,toc];
    fprintf('CPU_time:%f;clock_time:%d.\n',elapsed_time_LESS(1,NO_FLOW_NUM),elapsed_time_LESS(2,NO_FLOW_NUM));
%     disp("Elapsed:cputime; clock_time");
%     disp(elapsed_time_LESS(:,NO_FLOW_NUM));

    save('H:\best_flow\tmp_data.mat','ga_out_WINTER','ga_out_SUMMER','elapsed_time_LESS');
    end

end



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


