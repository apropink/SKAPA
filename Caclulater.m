clc
clear all

%________________제간부 결정
BH = 0; %(0은 트렁크 1은 제두부)
%________________파랑특성
Hs = 0.6;
T_1 = 8.96;
%________________실제 단면의 피복재 직경
Dn = 0.6
%________________방파제 제원 결정
h = 9.171;
h_prime = 6.771;
%________________피복재 종류2.9 및5.8 전면7.3 경사 결정  
Cota = 1.5;%%
KD = 2.9;%%
%________________소단길이
BM = 2.0;
BM_prime = 2.0;
%________________입사각 결정 (pi/n) pi/4 pi/3으로 표시
Beta = 0;
%________________변형특성
DN = 1; %%
N = 500;%% 
%________________피복재 특성
Rho_r = 2.65;
Rho_w = 1.03;

A = 1.3;
B = 1.5;
m = 1/3;

%___________________________________________________계산시작
if Beta == pi/3
    taw = 2.5;
else
    taw = 1.4;
end

dL=0.0001;
g=9.81;

    for L=0.0001:dL:1000
           a1 = L-((g*(T_1^2))/(2*pi))*tanh(2*pi*h_prime/L);
           b1 = (L+dL)-g*T_1^2/(2*pi)*tanh(2*pi*h_prime/(L+dL));
           if a1*b1<0
                break
           end
    end
    
    HpLp = h_prime/L;
    
Kappa1 = (4*pi*HpLp)/(sinh(4*pi*HpLp));

Alpha_S = 0.45;

%_____________________카파2 계산에서 l계산

lL1 = BM/L;
lL2 = BM_prime/L;

Kappa2_BM = max(Alpha_S*((sin(Beta))^2)*(cos(2*pi*lL1*cos(Beta)))^2,((cos(Beta))^2)*(sin(2*pi*lL1*cos(Beta)))^2);
Kappa2_BM_prime = max(Alpha_S*((sin(Beta))^2)*(cos(2*pi*lL2*cos(Beta)))^2,((cos(Beta))^2)*(sin(2*pi*lL2*cos(Beta)))^2);

if BH == 0
    
     if Beta == 0       
    Kappa2 = ((cos(Beta))^2)*(sin(2*pi*lL1*cos(Beta)))^2;
     else   
    Kappa2 = max(Kappa2_BM,Kappa2_BM_prime);
     end
else
Kappa2 = (1/4)*Alpha_S*taw^2;
end

AAA = Kappa2_BM;
BBB = Kappa2_BM_prime;

Kappa = Kappa1*Kappa2;

%____________________________________Ns
N_SO = (KD*Cota)^(1/3);
Sr = Rho_r/Rho_w;
h_pHs = h_prime/Hs;

Ns1 = A*((1-Kappa)/(Kappa^m))*h_pHs;
Ns2 = (N_SO)/(exp(B*(((1-Kappa)^2)/(Kappa^m))*h_pHs));

Ns = Ns1+Ns2;

%___________________변형을 허용하는 경우

Ns_star = Ns*(DN/exp(0.3*(1-500/N)))^0.25;
W = (Rho_r*(Hs^3))/((Ns_star^3)*(Sr-1)^3);
Dn_Tanimoto = (W/Rho_r)^(1/3);

%_______________________신뢰성 해석을 위한 변수

%변수입력
Mu_Ah = 1.0;
Mu_Delta = Sr-1;
Mu_Dn = Dn;
Mu_Cota = Cota;
Mu_Kei = Kappa; %무차원유속
Mu_hHs = h_pHs;
Mu_Hs = Hs;
Mu_Nw = N;

Kd = KD; 

%_____________________________________변수입력 끝
%변동계수
COV_Ah      = 18.0/100;
COV_Delta   = 3.8/100;
COV_Dn      = 6.7/100;
COV_Cota    = 5.0/100;
COV_Kei     = 10.0/100;
COV_hHs     = 10.0/100;
COV_Hs      = 16.0/100;
COV_Nw      = 50/100;

%각 변수에 대한 분산
Sigma_Ah    = Mu_Ah*COV_Ah;
Sigma_Delta = Mu_Delta*COV_Delta;
Sigma_Dn    = Mu_Dn*COV_Dn;
Sigma_Cota  = Mu_Cota*COV_Cota;
Sigma_Kei   = Mu_Kei*COV_Kei;
Sigma_hHs   = Mu_hHs*COV_hHs;
Sigma_Hs    = Mu_Hs*COV_Hs;
Sigma_Nw    = Mu_Nw*COV_Nw;

%검벨분포를 통한 카파와 람다의 계산
AA = sqrt(((pi^2)/6)*(1/Sigma_Hs^2));
BB = Mu_Hs-(0.57722/AA);

%_____________________________________AFDA 분석

%초기치
alpha_Ah    = 0.5;
alpha_Delta = 0.5;
alpha_Dn    = 0.5;
alpha_Cota  = 0.5;
alpha_Kei   = 0.5;
alpha_hHs   = 0.5;
alpha_Hs    = -0.5;
alpha_Nw    = -0.5;

%_____________________________________Beta 계산준비 끝
%반복 계산을 통한 Beta의 계산

for i = 1:1:10
    for beta = -10:0.00001:10

        %각 변수의 불확실성 고려
        X1  = Mu_Ah+Sigma_Ah*beta*alpha_Ah; 
        X2  = Mu_Delta+Sigma_Delta*beta*alpha_Delta;
        X3  = Mu_Dn+Sigma_Dn*beta*alpha_Dn;
        X5  = Mu_Kei+Sigma_Kei*beta*alpha_Kei;
        X6  = Mu_hHs+Sigma_hHs*beta*alpha_hHs;
        X7  = Mu_Hs+Sigma_Hs*beta*alpha_Hs;
        X8  = Mu_Nw+Sigma_Nw*beta*alpha_Nw;
        X10 = DN;

        Z1 = X1*X2*X3*((X10/(exp(0.3*(1-(500/X8)))))^0.25)*((1.3*((1-X5)/(X5^(1/3))*X6))+(1.8*exp(-1.5*(((1-X5)^2)/(X5^(1/3)))*X6)))-Mu_Hs;
        beta1 = Z1/(Sigma_Hs*alpha_Hs);
        p = beta1-beta;
        
        if abs(p) <= 0.00001
           beta2 = beta1;
           b(i,1) = beta2;
        end
    end 
        %다시 계산하기 위한 X
        V_F_1 = beta2*alpha_Ah; 
        V_F_2 = beta2*alpha_Delta; 
        V_F_3 = beta2*alpha_Dn; 
        V_F_5 = beta2*alpha_Kei; 
        V_F_6 = beta2*alpha_hHs; 
        V_F_7 = beta2*alpha_Hs; 
        V_F_8 = beta2*alpha_Nw; 
        
      %알파 다시 계산
      X_1 = Mu_Ah+Sigma_Ah*V_F_1;
      X_2 = Mu_Delta+Sigma_Delta*V_F_2;
      X_3 = Mu_Dn+Sigma_Dn*V_F_3;
      X_5 = Mu_Kei+Sigma_Kei*V_F_5;
      X_6 = Mu_hHs+Sigma_hHs*V_F_6;
      X_7 = Mu_Hs+Sigma_Hs*V_F_7;
      X_8 = Mu_Nw+Sigma_Nw*V_F_8;
      X_10 = DN;
        
     %편미분을 통한 K의 추정  
    K1 = -Sigma_Ah*((9*exp(-(3*(Mu_hHs + Sigma_hHs*V_F_6)*(Mu_Kei + Sigma_Kei*V_F_5 - 1)^2)/(2*(Mu_Kei + Sigma_Kei*V_F_5)^(1/3))))/5 - (13*(Mu_hHs + Sigma_hHs*V_F_6)*(Mu_Kei + Sigma_Kei*V_F_5 - 1))/(10*(Mu_Kei + Sigma_Kei*V_F_5)^(1/3)))*(Mu_Dn + Sigma_Dn*V_F_3)*(Mu_Delta + Sigma_Delta*V_F_2)*(DN*exp(150/(Mu_Nw + Sigma_Nw*V_F_8) - 3/10))^(1/4);
    K2 = -Sigma_Delta*((9*exp(-(3*(Mu_hHs + Sigma_hHs*V_F_6)*(Mu_Kei + Sigma_Kei*V_F_5 - 1)^2)/(2*(Mu_Kei + Sigma_Kei*V_F_5)^(1/3))))/5 - (13*(Mu_hHs + Sigma_hHs*V_F_6)*(Mu_Kei + Sigma_Kei*V_F_5 - 1))/(10*(Mu_Kei + Sigma_Kei*V_F_5)^(1/3)))*(Mu_Ah + Sigma_Ah*V_F_1)*(Mu_Dn + Sigma_Dn*V_F_3)*(DN*exp(150/(Mu_Nw + Sigma_Nw*V_F_8) - 3/10))^(1/4);
    K3 = -Sigma_Dn*((9*exp(-(3*(Mu_hHs + Sigma_hHs*V_F_6)*(Mu_Kei + Sigma_Kei*V_F_5 - 1)^2)/(2*(Mu_Kei + Sigma_Kei*V_F_5)^(1/3))))/5 - (13*(Mu_hHs + Sigma_hHs*V_F_6)*(Mu_Kei + Sigma_Kei*V_F_5 - 1))/(10*(Mu_Kei + Sigma_Kei*V_F_5)^(1/3)))*(Mu_Ah + Sigma_Ah*V_F_1)*(Mu_Delta + Sigma_Delta*V_F_2)*(DN*exp(150/(Mu_Nw + Sigma_Nw*V_F_8) - 3/10))^(1/4);
    K5 = (Mu_Ah + Sigma_Ah*V_F_1)*(Mu_Dn + Sigma_Dn*V_F_3)*(Mu_Delta + Sigma_Delta*V_F_2)*(DN*exp(150/(Mu_Nw + Sigma_Nw*V_F_8) - 3/10))^(1/4)*((9*exp(-(3*(Mu_hHs + Sigma_hHs*V_F_6)*(Mu_Kei + Sigma_Kei*V_F_5 - 1)^2)/(2*(Mu_Kei + Sigma_Kei*V_F_5)^(1/3)))*((3*Sigma_Kei*(Mu_hHs + Sigma_hHs*V_F_6)*(Mu_Kei + Sigma_Kei*V_F_5 - 1))/(Mu_Kei + Sigma_Kei*V_F_5)^(1/3) - (Sigma_Kei*(Mu_hHs + Sigma_hHs*V_F_6)*(Mu_Kei + Sigma_Kei*V_F_5 - 1)^2)/(2*(Mu_Kei + Sigma_Kei*V_F_5)^(4/3))))/5 + (13*Sigma_Kei*(Mu_hHs + Sigma_hHs*V_F_6))/(10*(Mu_Kei + Sigma_Kei*V_F_5)^(1/3)) - (13*Sigma_Kei*(Mu_hHs + Sigma_hHs*V_F_6)*(Mu_Kei + Sigma_Kei*V_F_5 - 1))/(30*(Mu_Kei + Sigma_Kei*V_F_5)^(4/3)));
    K6 = ((13*Sigma_hHs*(Mu_Kei + Sigma_Kei*V_F_5 - 1))/(10*(Mu_Kei + Sigma_Kei*V_F_5)^(1/3)) + (27*Sigma_hHs*exp(-(3*(Mu_hHs + Sigma_hHs*V_F_6)*(Mu_Kei + Sigma_Kei*V_F_5 - 1)^2)/(2*(Mu_Kei + Sigma_Kei*V_F_5)^(1/3)))*(Mu_Kei + Sigma_Kei*V_F_5 - 1)^2)/(10*(Mu_Kei + Sigma_Kei*V_F_5)^(1/3)))*(Mu_Ah + Sigma_Ah*V_F_1)*(Mu_Dn + Sigma_Dn*V_F_3)*(Mu_Delta + Sigma_Delta*V_F_2)*(DN*exp(150/(Mu_Nw + Sigma_Nw*V_F_8) - 3/10))^(1/4);
    K7 = Sigma_Hs;
    K8 = (75*DN*Sigma_Nw*exp(150/(Mu_Nw + Sigma_Nw*V_F_8) - 3/10)*((9*exp(-(3*(Mu_hHs + Sigma_hHs*V_F_6)*(Mu_Kei + Sigma_Kei*V_F_5 - 1)^2)/(2*(Mu_Kei + Sigma_Kei*V_F_5)^(1/3))))/5 - (13*(Mu_hHs + Sigma_hHs*V_F_6)*(Mu_Kei + Sigma_Kei*V_F_5 - 1))/(10*(Mu_Kei + Sigma_Kei*V_F_5)^(1/3)))*(Mu_Ah + Sigma_Ah*V_F_1)*(Mu_Dn + Sigma_Dn*V_F_3)*(Mu_Delta + Sigma_Delta*V_F_2))/(2*(Mu_Nw + Sigma_Nw*V_F_8)^2*(DN*exp(150/(Mu_Nw + Sigma_Nw*V_F_8) - 3/10))^(3/4));
    
    K = (K1^2+K2^2+K3^2+K5^2+K6^2+K7^2+K8^2)^(1/2);
         
    alpha_Ah    = -K1/K;
    alpha_Delta = -K2/K;
    alpha_Dn    = -K3/K;
    alpha_Kei   = -K5/K;
    alpha_hHs   = -K6/K;
    alpha_Hs    = -K7/K;
    alpha_Nw    = -K8/K;
    
    a = alpha_Ah^2+alpha_Delta^2+alpha_Dn^2+alpha_Kei^2+alpha_hHs^2+alpha_Hs^2+alpha_Nw^2;   
    
    %알파 Table
    alpha(i,1) = alpha_Ah;
    alpha(i,2) = alpha_Delta;
    alpha(i,3) = alpha_Dn;
    alpha(i,4) = alpha_Kei;
    alpha(i,5) = alpha_hHs;
    alpha(i,6) = alpha_Hs;
    alpha(i,7) = alpha_Nw;
    alpha(i,8) = Mu_Hs;
    alpha(i,9) = Sigma_Hs;
    alpha(i,10) = -beta2;
    
    K_a(i,1) = K;
    
    %검벨 다시계산 (kappa lambda는 고정)
    Gumbel = exp(-exp(-AA*(Mu_Hs-BB)));
    Gumbel_prime = AA*exp(-AA*(Mu_Hs-BB)-exp(-AA*(Mu_Hs-BB)));

    Sigma_Hs = normpdf(norminv(Gumbel))/Gumbel_prime;
    Mu_Hs = Mu_Hs-norminv(Gumbel)*Sigma_Hs;
  
    end 
Beta_sel = -beta2;
Pf_AFDA = round((1-normcdf(Beta_sel))*100,5)

Table1(1,1) = round(L,2);
Table1(2,1) = round(Sr,4);
Table1(3,1) = round(Sr-1,4);
Table1(4,1) = N;
Table1(5,1) = DN;
Table1(6,1) = round(h_pHs,4)

Table2(1,1) = Beta;
Table2(2,1) = Cota;
Table2(3,1) = KD;
Table2(4,1) = Kappa1;
Table2(5,1) = AAA;
Table2(6,1) = BBB;
Table2(7,1) = Kappa2;
Table2(8,1) = Kappa;
Table2(9,1) = Ns;
Table2(10,1) = Ns_star;
Table2(11,1) = W;
Table2(12,1) = Dn_Tanimoto