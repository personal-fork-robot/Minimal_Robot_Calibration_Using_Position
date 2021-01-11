function [ xi,xist ] = Puma560Minimal( xi0,xist0,vtheta,gm,M )
%[xi,xist] = Puma560Minimal(xi0,xist0,vtheta,gm,M) : Minimal calibration model for puma560 robot
%
%Input:
%   xi0: nominal joint twists; 
%   xist0: nominal initial twist; 
%   vtheta: joint positions;
%   gm: Actual measured end-effector poses
%   M: iteration steps
%
%Output:
%   xi: calibrated joint twists; 
%   xist: calibrated initial twist; 
%
%Please refer to 
%Xiangdong Yang, Liao Wu, Jinquan Li, Ken Chen, A minimal kinematic model for serial robot calibration using POE formula, Robotics and Computer-Integrated Manufacturing, Volume 30, Issue 3, June 2014, Pages 326-334
%and
%Liao Wu, Xiangdong Yang, Ken Chen, Hongliang Ren. A minimal POE-based model for robotic kinematic calibration with only position measurements. IEEE Transactions on Automation Science and Engineering. 2015, 12(2): 758-763.

%memory allocation
xi=xi0;
xist=xist0;
N=size(vtheta,1);

gn=zeros(4,4,N);%nominal end-effector poses
dg=zeros(4,4,N);%pose error
vLog=zeros(6,N);%pose error in twist form

for m=1:M
    for i=1:N
        gn(:,:,i)=fkPUMA560(xi,xist,vtheta(i,:),6);
        dg(:,:,i)=gm(:,:,i)/gn(:,:,i);
        vLog(:,i)=vlog(dg(:,:,i));
    end
    simY=zeros(6*N,1);
    for i=1:N
        simY(6*i-5:6*i,1)=vLog(:,i);
    end
    
    %transformation from base frame to link frame
    t1=twistframe(xi(:,1));
    t2=twistframe(xi(:,2));
    t3=twistframe(xi(:,3));
    t4=twistframe(xi(:,4));
    t5=twistframe(xi(:,5));
    t6=twistframe(xi(:,6));
    
    %Jacobian matrix
    for k=0:N-1
        simJ(1+6*k:6+6*k,1:6)=aMatrix(xi(:,1),vtheta(k+1,1));
        simJ(1+6*k:6+6*k,7:12)=adM(se3Exp(vtheta(k+1,1)*xi(:,1)))*aMatrix(xi(:,2),vtheta(k+1,2));
        simJ(1+6*k:6+6*k,13:18)=adM(se3Exp(vtheta(k+1,1)*xi(:,1))*se3Exp(vtheta(k+1,2)*xi(:,2)))*aMatrix(xi(:,3),vtheta(k+1,3));
        simJ(1+6*k:6+6*k,19:24)=adM(se3Exp(vtheta(k+1,1)*xi(:,1))*se3Exp(vtheta(k+1,2)*xi(:,2))*se3Exp(vtheta(k+1,3)*xi(:,3)))*aMatrix(xi(:,4),vtheta(k+1,4));
        simJ(1+6*k:6+6*k,25:30)=adM(se3Exp(vtheta(k+1,1)*xi(:,1))*se3Exp(vtheta(k+1,2)*xi(:,2))*se3Exp(vtheta(k+1,3)*xi(:,3))*se3Exp(vtheta(k+1,4)*xi(:,4)))*aMatrix(xi(:,5),vtheta(k+1,5));
        simJ(1+6*k:6+6*k,31:36)=adM(se3Exp(vtheta(k+1,1)*xi(:,1))*se3Exp(vtheta(k+1,2)*xi(:,2))*se3Exp(vtheta(k+1,3)*xi(:,3))*se3Exp(vtheta(k+1,4)*xi(:,4))*se3Exp(vtheta(k+1,5)*xi(:,5)))*aMatrix(xi(:,6),vtheta(k+1,6));
        simJ(1+6*k:6+6*k,37:42)=adM(se3Exp(vtheta(k+1,1)*xi(:,1))*se3Exp(vtheta(k+1,2)*xi(:,2))*se3Exp(vtheta(k+1,3)*xi(:,3))*se3Exp(vtheta(k+1,4)*xi(:,4))*se3Exp(vtheta(k+1,5)*xi(:,5))*se3Exp(vtheta(k+1,6)*xi(:,6)))*aMatrixST(xist);
    end
    
    Brot=[1, 0, 0, 0;
    0, 1, 0, 0;
    0, 0, 0, 0;
    0, 0, 0, 1;
    0, 0, -1, 0;
    0, 0, 0, 0];
    
    simJ1(:,1:4)=simJ(:,1:6)*adM(t1)*Brot;
    simJ1(:,5:8)=simJ(:,7:12)*adM(t2)*Brot;
    simJ1(:,9:12)=simJ(:,13:18)*adM(t3)*Brot;
    simJ1(:,13:16)=simJ(:,19:24)*adM(t4)*Brot;
    simJ1(:,17:20)=simJ(:,25:30)*adM(t5)*Brot;
    simJ1(:,21:24)=simJ(:,31:36)*adM(t6)*Brot;
    simJ1(:,25:30)=simJ(:,37:42);
    
    dp=simJ1\simY;

    %update
    omega1=[dp(1);dp(2);(1-dp(1)*dp(1)-dp(2)*dp(2))^0.5];
    q1=[dp(3);dp(4);0];
    v1=cross(q1,omega1);
    xi(:,1)=adM(t1)*[omega1;v1];

    omega2=[dp(5);dp(6);(1-dp(5)*dp(5)-dp(6)*dp(6))^0.5];
    q2=[dp(7);dp(8);0];
    v2=cross(q2,omega2);
    xi(:,2)=adM(t2)*[omega2;v2];

    omega3=[dp(9);dp(10);(1-dp(9)*dp(9)-dp(10)*dp(10))^0.5];
    q3=[dp(11);dp(12);0];
    v3=cross(q3,omega3);
    xi(:,3)=adM(t3)*[omega3;v3];

    omega4=[dp(13);dp(14);(1-dp(13)*dp(13)-dp(14)*dp(14))^0.5];
    q4=[dp(15);dp(16);0];
    v4=cross(q4,omega4);
    xi(:,4)=adM(t4)*[omega4;v4];

    omega5=[dp(17);dp(18);(1-dp(17)*dp(17)-dp(18)*dp(18))^0.5];
    q5=[dp(19);dp(20);0];
    v5=cross(q5,omega5);
    xi(:,5)=adM(t5)*[omega5;v5];

    omega6=[dp(21);dp(22);(1-dp(21)*dp(21)-dp(22)*dp(22))^0.5];
    q6=[dp(23);dp(24);0];
    v6=cross(q6,omega6);
    xi(:,6)=adM(t6)*[omega6;v6];

    xist=xist+dp(25:30);

end

