clc
clear all

%난수갯수

Arp = 60;

%변수입력

Mu_Ah = 1.0;
Mu_Delta = 1.5728;
Mu_Dn = 0.8326;
Mu_Kei = 0.1476;
Mu_hHs = 1.8;
Mu_Hs = 5.0;
Mu_Nw = 500;

DN = 5;

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

Sigma_Kei   = Mu_Kei*COV_Kei;
Sigma_hHs   = Mu_hHs*COV_hHs;
Sigma_Hs    = Mu_Hs*COV_Hs;
Sigma_Nw    = Mu_Nw*COV_Nw;

%_____________________________________몬테카를로 시뮬레이션

%검벨분포를 통한 카파와 람다의 계산
kappa   = sqrt(((pi^2)/6)*(1/Sigma_Hs^2));
lambda  = Mu_Hs-(0.57722/kappa);

for YY = 0:1:Arp
%난수의 갯수
N = 1000+(YY)*1000;

%난수의 생성
    for i=1:1:N
    
    X1 = random('Normal',Mu_Ah,Sigma_Ah,1,1);
    X2 = random('Normal',Mu_Delta,Sigma_Delta,1,1);
    X3 = random('Normal',Mu_Dn,Sigma_Dn,1,1);
    X5 = random('Normal',Mu_Kei,Sigma_Kei,1,1);
    X6 = random('Normal',Mu_hHs,Sigma_hHs,1,1);
    
    %파수의 Truncated

    %Monday = random('Normal',Mu_Nw,Sigma_Nw,1,1);  %1안
    %Monday_1 = Monday>0; %2안
   
    %if Monday<0 %1안
    %    Monday = -Monday;   %1안
    %end  %1안
    
    %X8 = Monday_1*Monday; %2안
    %X8 = Monday; %1안
    
    %truncated distribution wave number
    %truncate1 = makedist('Normal',Mu_Nw,Sigma_Nw); %3안
    %truncate2 = truncate(truncate1,0,inf); %3안
    %X8 = random(truncate2); %3안
    
    %4안 시작
    %상한과 하한의 결정
    a = 0;
    b = +inf;
    for iUL=1:1:1475

    erf1_pdf = (1/sqrt(2*pi))*exp(-(1/2)*(((iUL-Mu_Nw)/Sigma_Nw)^2));

    erf1_cdf = (1/2)*(1+erf((iUL-Mu_Nw)/(Sigma_Nw*sqrt(2))));
    erf2_cdf = (1/2)*(1+erf((a-Mu_Nw)/(Sigma_Nw*sqrt(2))));
    erf3_cdf = (1/2)*(1+erf((b-Mu_Nw)/(Sigma_Nw*sqrt(2))));

    %Trunc_pdf(iUL,1) = (1/Sigma_Nw)*(erf1_pdf/(1-erf2_cdf));
    Trunc_cdf(iUL,1) = (erf1_cdf-erf2_cdf)/(1-erf2_cdf);

    end
    Jebal = randi([1,1475],1,1);
    X8 = Trunc_cdf(Jebal,1)*1476;
    
    %4안 끝
   
    X10 = DN;
     
    %검벨분포를 통한 유의파고의 난수 생성
    U = rand; %지우지말것
    X7 = round(lambda-(1/kappa)*log(log(1/U)),4); %검벨분포에 대한 역함수

    Z = X1*X2*X3*((X10/(exp(0.3*(1-(500/X8)))))^0.25)*((1.3*((1-X5)/(X5^(1/3))*X6))+(1.8*exp(-1.5*(((1-X5)^2)/(X5^(1/3)))*X6)))-X7;
    
    A1(i,1)=X1;
    A2(i,1)=X2;
    A3(i,1)=X3;
    A5(i,1)=X5;
    A6(i,1)=X6;
    A7(i,1)=X7;
    A8(i,1)=X8;
    A9(i,1)=(Z>=-100)*(Z<=100)*Z;
    
    end

    Pf_mean(YY+1,1) = sum(A9)/N;
    Pf_std(YY+1,1) = std(A9);
    
    %히스토그램
    edges = 0:0.001:10;
    edges_Hs = 0:0.001:10;
    edges_Nw = -100:1:1500;
    edges_Z = -100:0.01:100;
    edges_hHs = -10:0.001:20;

    hist_Ah = histcounts(A1,edges);
    hist_Delta = histcounts(A2,edges);
    hist_Dn = histcounts(A3,edges);
    hist_Kei = histcounts(A5,edges);
    hist_hHs = histcounts(A6,edges_hHs);
    hist_Hs = histcounts(A7,edges_Hs);
    hist_Nw = histcounts(A8,edges_Nw);
    hist_Z = histcounts(A9,edges_Z);
    
    %히스토그램의 정규화
    
    NOR_hist_Ah = hist_Ah/i;
    Sum_NOR_hist_Ah = sum(NOR_hist_Ah);
    
    NOR_hist_Delta = hist_Delta/i;
    Sum_NOR_hist_Delta = sum(NOR_hist_Delta);
    
    NOR_hist_Dn = hist_Dn/i;
    Sum_NOR_hist_Dn = sum(NOR_hist_Dn);

    NOR_hist_Kei = hist_Kei/i;
    Sum_NOR_hist_Kei = sum(NOR_hist_Kei);
    
    NOR_hist_hHs = hist_hHs/i;
    Sum_NOR_hist_hHs = sum(NOR_hist_hHs);
    
    NOR_hist_Hs = hist_Hs/i;
    Sum_NOR_hist_Hs = sum(NOR_hist_Hs);
    
    NOR_hist_Nw = hist_Nw/i;
    Sum_NOR_hist_Nw = sum(NOR_hist_Nw);
    
    NOR_hist_Z = hist_Z/i;
    Sum_NOR_hist_Z = sum(NOR_hist_Z);
   
    %각 변수별 pdf 산정
    range_size=1000;
    range = 0:0.001:10;
    range_Nw = -100:1:1500;
    range_hHs = -10:0.001:20;
    range_Hs = -10:0.001:10;
    
    PDF_Ah = normpdf(range,Mu_Ah,Sigma_Ah)/range_size;
    Sum_PDF_Ah = sum(PDF_Ah);
    
    PDF_Delta = normpdf(range,Mu_Delta,Sigma_Delta)/range_size;
    Sum_PDF_Delta = sum(PDF_Delta);
    
    PDF_Dn = normpdf(range,Mu_Dn,Sigma_Dn)/range_size;
    Sum_PDF_Dn = sum(PDF_Dn);
    
    PDF_Kei = normpdf(range,Mu_Kei,Sigma_Kei)/range_size;
    Sum_PDF_Kei = sum(PDF_Kei);
    
    PDF_hHs = normpdf(range_hHs,Mu_hHs,Sigma_hHs)/range_size;
    Sum_PDF_Kei = sum(PDF_hHs);
   
    PDF_Hs = kappa*exp(-kappa*(edges_Hs-lambda)-exp(-kappa*(edges_Hs-lambda)))/range_size;
    Sum_PDF_Hs = sum(PDF_Hs);
    
    PDF_Nw = normpdf(range_Nw,Mu_Nw,Sigma_Nw)/1;
    Sum_PDF_Nw = sum(PDF_Nw);
    
    %파괴확률의 계산
    
    count = sum(A9<0);
    Pf_Blossom(YY+1,1) = round((count/i)*100,4);
    Mean_Pf_Blossom(YY+1,1) = mean(Pf_Blossom);
    Pf_Blossom_Number(YY+1,1) = YY+1;
    
    RTRT(YY+1,1) = Pf_Blossom(YY+1,1)
    RTRT(YY+1,2) = Mean_Pf_Blossom(YY+1,1)
    RTRT(YY+1,3) = Pf_Blossom_Number(YY+1,1)
    end