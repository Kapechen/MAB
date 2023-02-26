classdef (Sealed) MAB
    %MAB MAB框架,密封类
    %   此框架封装了常用的MAB算法
    %Author：Kapechen
    %Last Modified Time：2022/06/16
    properties
        ActionSpace;            %动作空间
        ActionSpaceSize;        %动作空间大小
        ActionTime;             %动作时间
        CurrentActionPoint;     %当前动作对象指针
        I;                      %动作被选中标记矩阵
        ActionSelectedCount;    %动作被选中次数统计
        MeanActionReward;       %期望动作奖励
        Nt;                     %动作选中折扣统计量
        G;                      %索引值
    end
    methods 
        function self = MAB(ActionSpace,ActionTime)
            %MAB 构造此类的实例
            %   ActionSpace:动作空间，应为列向量; ActionTime:执行MAB所需要的时间
            self.ActionSpace = ActionSpace;
            self.ActionTime = ActionTime;
            self.ActionSpaceSize = size(ActionSpace,1);
            self.CurrentActionPoint = zeros(self.ActionTime,1);
            self.I = zeros(self.ActionTime,self.ActionSpaceSize);
            self.ActionSelectedCount = zeros(1,self.ActionSpaceSize);
            self.G = zeros(self.ActionTime,self.ActionSpaceSize);
            self.Nt = zeros(self.ActionTime,self.ActionSpaceSize);
            self.MeanActionReward = zeros(self.ActionTime,self.ActionSpaceSize);
        end
        function tempCurrentActionPoint = getCurrentActionPoint(self,t)
            %GETCURRENTACTIONPOINT
            %   输入当前时间t,寻找当前动作指针
            if t <=  self.ActionSpaceSize
                tempCurrentActionPoint = t;
            else
                [~,tempCurrentActionPoint] = max(self.G(t-1,:));
            end
        end
        function self = DUCB(self,t,tempCurrentActionPoint,reward,gamma,exploreF,B)
            %DUCB DUCB算法封装
            %   self:MAB对象;t:当前时刻;tempCurrentActionPoint:当前动作指针;reward:当前时刻奖励值;gamma:折扣因子超参;exploreF:探索因子;B:奖励的上限，默认设置为1
            if nargin < 6
                B = 1;
            end
            self.CurrentActionPoint(t) = tempCurrentActionPoint;
            self.I(t,tempCurrentActionPoint) = 1;
            self.ActionSelectedCount(tempCurrentActionPoint) = self.ActionSelectedCount(tempCurrentActionPoint) + 1;
            gammaV = ones(1,t);
            for s = 1:1:t
                gammaV(1,s) = gamma^(t-s);
            end
            self.Nt(t,:) = gammaV*self.I(1:1:t,:);
            % 动作的期望奖励和探索因子计算
            tempRewardSum = zeros(1,self.ActionSpaceSize);
            explore = zeros(1,self.ActionSpaceSize);
            for i = 1:1:self.ActionSpaceSize
                tempRewardSum(i) = gammaV * (reward(1:1:t,i).*self.I(1:1:t,i));
                explore(i) = 2*B*sqrt(exploreF*log(sum(self.Nt(t,:)))/self.Nt(t,i));
            end
            self.MeanActionReward(t,:) = tempRewardSum(1,:)./self.Nt(t,:);
            % 计算索引值
            self.G(t,:) = self.MeanActionReward(t,:) + explore(1,:);
        end
    end
end