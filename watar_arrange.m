%%说明：用于计算水位变化范围，需要先执行flow_data.m%%
format long e % 设置精度为6位有效数字的科学计数法
%设置各月的起调水位
begin_level=[2712,2712,2712,2712,2713,2713,2713,2713,2713,2713,2712,2712];
%设置是不是丰水季节
mouth_type=[0,0,0,0,1,1,1,1,1,1,0,0];
%设置一些常量
%额定发电流量用于最大泄量
MAX_FLOW=1186.2;
%最小发电流量，如果低于此流量就不发电
MIN_FLOW=177;
%丰水季节最小流量
MIN_HFLOW=300;
%如果枯水季流量大于MIN_FLOW可以把高出的水暂时存储下来，
%丰水季流量大于MIN_HFLOW可以把高出的水暂存下来
%水位不可以高于设计蓄水位，不能低于一下死水位；水位可以暂时低于起调水位，但是最后不能低于起调水位
MAX_LEVEL=2715;
MIN_LEVEL=2710;

%设置实际水位
%设置步长
STEP=1;
%确定步长总数
mouth_num=size(begin_level,2);
%初始化数据
%小时最大水位和小时最小水位
%24个小时，但是有25个节点
max_group=zeros(24/STEP+1,12);
min_group=zeros(24/STEP+1,12);
max_group_avg=zeros(24/STEP,12);
min_group_avg=zeros(24/STEP,12);
max_group_01h=zeros(241,12);
min_group_01h=zeros(241,12);
%循环计算每月的水位
for i = 1:mouth_num
    max_group(:,i) = max_hours_level(begin_level(i),total_mouth_avg(i),mouth_type(i),MAX_FLOW,MIN_HFLOW,MIN_FLOW,STEP);
    min_group(:,i) = min_hours_level(begin_level(i),total_mouth_avg(i),mouth_type(i),MAX_FLOW,MIN_HFLOW,MIN_FLOW,STEP);
    %由于舍入误差需要对部分数据进行稍微校准一下
    if (max_group(24/STEP+1,i)-max_group(1,i)) <0.0040
        max_group(24/STEP+1,i)=max_group(1,i);
    end
    if (min_group(24/STEP+1,i)-min_group(1,i)) <0.0040
        min_group(24/STEP+1,i)=min_group(1,i);
    end
    %计算时段中间的水位
    for j=1:24/STEP
        max_group_avg(j,i)=mean(max_group(j:j+1,i));
        min_group_avg(j,i)=mean(min_group(j:j+1,i));
    end
end
%画图，画水位廊道图
% % % 循环生成和保存每个天平均值然后月的图
folder = 'G:\大一下\毕业设计多能互补\data\plot_out'; % 文件夹名称
% 文件名前缀
prefix = 'mouth_level_arrange';
for i = 1:mouth_num
    % 生成第i个图
    figure(i)
    hold on;
    plot(max_group(:,i),'-m','LineWidth',2,'DisplayName', '最高水位');
    plot(min_group(:,i),'-b','LineWidth',2,'DisplayName', '最低水位');
    ylabel('水位(m)');
    xlabel('时刻(时)')
    if mouth_type(i) == 1
        ylim([2712.6, 2713.4]);
    else 
        ylim([2711.6, 2712.5]);
    end
    xmin=1;
    % 将第一个点移到 x 轴的零点处
    xticks([xmin:24/STEP+1]);
    xticklabels({0:24/STEP});
    % 设置横坐标轴刻度和标签
    xticks(linspace(xmin, 24/STEP+1, 25));
    %xticklabels({'0', '0.1', '0.2', '0.3', '0.4', '0.5', '0.6', '0.7', '0.8', '0.9', '1'});
    xticklabels({0:24});
    xticks(0:10:241);
    legend('Location', 'northeast','NumColumns', 2);
    title(sprintf(' %d 月水位变化', i),'FontName', '宋体', 'FontSize', 20);    
     
    % 生成文件名
    plotname = [prefix, num2str(i), '.png'];
                                                                                                                                                                                                              
    % 拼接保存路径
    savepath = fullfile(folder, plotname);

    width=700;
    height=600;

    set(gcf, 'Units', 'pixels','Position', [100 100 width height]);%设置长宽比
    set(gca, 'LooseInset', get(gca, 'TightInset'));
    
    % 保存图
    saveas(gcf, savepath);
    hold off;
    % 关闭当前窗口
    close;
end

x=volume2level(00);
%水位转库容
function level = volume2level(volume_1)
    level=2710+volume_1*5/(2.39*1000*1000*100);
    %限制水位范围
    assert(level<=2715 && level >=2710);
end
%根据变化容积计算变化水位
%volume可以是负数表示水位下降的情况，只要保证最后的水位在规定范围内即可
function level =change_level(inital_level,volume)
    level=inital_level+volume*5/(2.39*1000*1000*100);
    %限制水位范围
    assert (inital_level >= 2710 && inital_level <= 2715,"change_level_assert",inital_level);
    if (level > 2715 || level < 2710) 
%         disp(level);
%         disp(inital_level);
%         disp(volume);
    end
    assert(level<=2715 && level >= 2710,"change_level",level);
end

%水位计算函数最大值
%这里也需要尽量保持最后水位与开始水位大致相同
%下泄水量也是不能小于特定时期的最小值
%这里也需要分为3种情况
%1.如果大于max_out=1186.2额定流量那就一直下泄就行（只有一个月是这样的）
%2.小于最小下泄流量（枯水季和丰水季节不一样），小于就不发电直接下泄
%3.两者之间，不能高于2715，不能低于2710，最后需要水位回到起调水位
%最高和最低水位的下泄水位思路正好相反，最高的水位需要在开始最小下泄，最后阶段最大下泄
%最低水位是，一开始最大下泄，然后就是最低下泄
%step 时间尺度，以小时为单位
function result_level = max_hours_level(inital_level,avg_in,type,MAX_FLOW,MIN_HFLOW,MIN_FLOW,step)
    result_level = zeros(24/step+1,1);
    len=size(result_level,1);
    step_time=3600*step;
    max_out = MAX_FLOW;
    %枯水季和丰水季节下泄流量最小值不一样
    if type == 1
        min_out = MIN_HFLOW;
    %如果入流平均流量低于MIN_FLOW那么来水多少就直接放水
    elseif avg_in < MIN_FLOW
        min_out = avg_in;
    else 
        min_out = MIN_FLOW;
    end
    result_level(1)=inital_level;
    if avg_in > max_out 
        for hours = 2:len
            change_volume = (avg_in - max_out)*step_time;
            result_level(hours)=change_level(result_level(hours-1),change_volume);
        end
        %来水流量小于最小发电流量，直接下泄
    elseif avg_in <= min_out
        for hours=2:len
            change_volume = (avg_in - min_out)*step_time;
            result_level(hours)=change_level(result_level(hours-1),change_volume);
        end
    else
        %计算可以超泄的体积
        over_volume = (avg_in - min_out) *24 *3600;
        %计算可以超泄的步长
        over_steps  = over_volume / ((max_out -min_out)*step_time);
        %注意有可能超泄的小时数可能不是整数,hours也不一定是小时整数,具体大小为步长
        for hours=2:len
            %最小流量阶段
            if (len-over_steps) > hours 
                change_volume = (avg_in - min_out)*step_time;
                result_level(hours)=change_level(result_level(hours-1),change_volume);
            %混合流量阶段
            elseif (len-over_steps) <= hours && (len-over_steps + 1) > hours
                %如果是7.6小时开始额定下泄，这个时候8时的水位需要分两段计算，第一段是最小流量，第二段是额定流量
                change_volume = (avg_in  - max_out*(hours-(len-over_steps)) - min_out*(abs(hours - (len-over_steps))))*step_time;
                result_level(hours)=change_level(result_level(hours-1),change_volume);
            %额定流量阶段
            else
                change_volume = (avg_in - max_out)*step_time;
                result_level(hours)=change_level(result_level(hours-1),change_volume);
            end%if
        end%for
    end%if
end%function

%水位计算函数最小值
function result_level = min_hours_level(inital_level,avg_in,type,MAX_FLOW,MIN_HFLOW,MIN_FLOW,step)
    result_level = zeros(24/step+1,1);
    len=size(result_level,1);
    step_time=3600*step;
    result_level(1) = inital_level;
    max_out = MAX_FLOW;
    %枯水季和丰水季节下泄流量最大值不一样
    %需要确保的目标是至少需要维持最后的水位不低于开始水位，
    %中间的水位可以低于初始水位，但是不能低于死水位
    %由于水轮机满载流量很大，来水比较小因此丰水期情况下基本可以按照水轮机的额定流量当成最大流量
    %其他情况下出库流量需要满足一个最小值，如果出库流量比最小值还要小那就是不发电了，直接下泄这部分流量
    %如果大于这个最小值，可以选择部分时间内超量使用部分值水资源，最后还是要确保最后的水位是和初始水位一样
    %这里不考虑水量利用效率（高水头情况下肯定利用效率是更高的），比如高峰时间再使用可能更好
    %因此在可以超量使用的情况下，一开始就超量下泄的时候水位可以达到最低值
    %如果来水大于基荷流量的时候，每天需要流出的最小流量就是最小流量是24小时基荷
    %因此每天可以超泄的水的体积是（avg_in-min_out)*24hours
    %为了尽快达到最大值超泄的体积，这里采用超泄流量采用额定值
    if type == 1
        min_out = MIN_HFLOW;
    %如果入流平均流量低于MIN_FLOW那么来水多少就直接放水
    elseif avg_in < MIN_FLOW
        min_out = avg_in;
    else 
        min_out = MIN_FLOW;
    end

    if avg_in > max_out
        for hours=2:len
           change_volume=(avg_in - max_out)*step_time;
           result_level(hours)=change_level(result_level(hours-1),change_volume);
        end
    elseif avg_in < min_out
        for hours=2:len
           change_volume=(avg_in - min_out)*step_time;
           result_level(hours)=change_level(result_level(hours-1),change_volume);
        end
    else 
        %计算可以超泄的体积
        over_volume = (avg_in - min_out) *24 *3600;
        %计算可以超泄的小时数
        %这里超泄小时数加1，因为数组开始是1，1代表是0点，因此为了正确表述，因此需要加1，求最高水位因为最后不同，可能不需要做相关调整
        over_steps  = over_volume / ((max_out -min_out)*step_time) + 1;
        %注意有可能超泄的小时数可能不是整数
        for hours=2:len
  
            if over_steps > hours 
                change_volume = (avg_in - max_out)*step_time;
                result_level(hours)=change_level(result_level(hours-1),change_volume);
            elseif over_steps <= hours && over_steps + 1 > hours
                %如果是7.6小时后超泄达到最大值，那么8时的水位需要分成段计算
                change_volume = (avg_in *step_time) - (max_out*(over_steps+1-hours)*step_time) - min_out*((hours - over_steps)*step_time);
                result_level(hours)=change_level(result_level(hours-1),change_volume);
            else
                change_volume = (avg_in - min_out)*step_time;
                result_level(hours)=change_level(result_level(hours-1),change_volume);
            end%if
        end%for
    end%if
end%function