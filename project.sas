PROC IMPORT OUT= WORK.churndata 
            DATAFILE= "E:\Users\sxp190082\Desktop\Project\Telco-Customer-Churn.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

data churn1;
set churndata;

IF churn = "Yes" THEN ChurnYes=1; ELSE ChurnYes= 0;
IF gender = "Male" THEN genderMale=1; ELSE genderMale=0;
IF Partner = "Yes" THEN PartnerYes=1; ELSE PartnerYes=0;
IF Dependents = "Yes" THEN DependentsYes=1; ELSE DependentsYes=0;
IF PhoneService = "Yes" THEN PhoneServiceYes=1; ELSE PhoneServiceYes=0;
IF MultipleLines = "Yes" THEN MultipleLinesYes=1; ELSE MultipleLinesYes=0;
IF InternetService = "DSL" THEN InternetServiceDSL=1; else InternetServiceDSL=0;
IF InternetService = "Fiber optic" THEN InternetServiceFiberOptic =1; ELSE InternetServiceFiberOptic=0;
IF InternetService = "No" THEN InternetServiceNo=1; ELSE InternetServiceNo=0;

IF InternetService = "DSL" | InternetService = "Fiber optic" THEN InternetServiceOpt=1; else InternetServiceOpt=0;

IF OnlineSecurity = "Yes" THEN OnlineSecurityYes=1; ELSE OnlineSecurityYes=0;
IF OnlineBackup = "Yes" THEN OnlineBackupYes=1; ELSE OnlineBackupYes=0;
IF DeviceProtection = "Yes" THEN DeviceProtectionYes=1; ELSE DeviceProtectionYes=0;
IF TechSupport = "Yes" THEN TechSupportYes=1; ELSE TechSupportYes=0;
IF StreamingTV = "Yes" THEN StreamingTVYes=1; ELSE StreamingTVYes=0;
IF StreamingMovies = "Yes" THEN StreamingMoviesYes=1; ELSE StreamingMoviesYes=0;

IF StreamingMovies = "Yes" | StreamingTV = "Yes" THEN StreamingMediaYes=1; ELSE StreamingMediaYes=0;

IF Contract = "Month-to-month" THEN ContractMonthly=1; else ContractMonthly=0;
IF Contract = "One year" THEN ContractOneYear=1; ELSE ContractOneYear=0;
IF Contract = "Two year" THEN ContractTwoYear=1; ELSE ContractTwoYear=0;
IF PaymentMethod = "Bank transfer (automatic)" THEN PaymentMethodBankTransfer=1; ELSE PaymentMethodBankTransfer=0;
IF PaymentMethod = "Credit card (automatic)" THEN PaymentMethodCreditCard=1; ELSE PaymentMethodCreditCard=0;

IF PaymentMethod = "Bank transfer (automatic)" | PaymentMethod = "Credit card (automatic)" THEN PaymentMethodAutomatic=1; ELSE PaymentMethodAutomatic=0;

IF PaymentMethod = "Electronic check" THEN PaymentMethodElectronicCheck=1; ELSE PaymentMethodElectronicCheck=0;
IF PaymentMethod = "Mailed check" THEN PaymentMethodMailedCheck=1; ELSE PaymentMethodMailedCheck=0;

IF PaperlessBilling = "Yes" THEN PaperlessBillingYes=1; ELSE PaperlessBillingYes=0;


TVMovies = StreamingTVYes * StreamingMoviesYes;
DependentsPartner = DependentsYes * PartnerYes;
FibreMonthlycharges = InternetServiceFiberOptic * MonthlyCharges;

run;

proc surveyselect data=churn1 out=churn1_sampled outall samprate=0.8 seed=10;
run;
data churn1_training churn1_test;
 set churn1_sampled;
 if selected then output churn1_training; 
 else output churn1_test;
run;

ods graphics on;
proc logistic data=churn1_training;
logit: model ChurnYes (event='1') = tenure MonthlyCharges PartnerYes 
									DependentsYes PhoneServiceYes 
									MultipleLinesYes  
									InternetServiceDSL InternetServiceFiberOptic 
									StreamingTVYes StreamingMoviesYes 
									ContractMonthly ContractOneYear
									PaymentMethodAutomatic
									PaperlessBillingYes 
									TVMovies DependentsPartner FibreMonthlycharges/ clodds= wald orpvalue;
score data = churn1_test out = churn_logit_predict;
title 'Logistic regression model';
run;
ods graphics on;
proc logistic data=churn_logit_predict plots=roc;
 model ChurnYes (event='1') =  		tenure MonthlyCharges PartnerYes 
									DependentsYes PhoneServiceYes 
									MultipleLinesYes  
									InternetServiceDSL InternetServiceFiberOptic 
									StreamingTVYes StreamingMoviesYes 
									ContractMonthly ContractOneYear
									PaymentMethodAutomatic
									PaperlessBillingYes 
									TVMovies DependentsPartner FibreMonthlycharges/ nofit;
 roc pred=p_1;
 title 'ROC-Logit model';
run;

proc logistic data=churn1_training outmodel=Logitmodel;
 logit: model ChurnYes (event='1') =  tenure MonthlyCharges PartnerYes DependentsYes PhoneServiceYes 
									MultipleLinesYes  
									InternetServiceDSL InternetServiceFiberOptic 
									StreamingTVYes StreamingMoviesYes 
									ContractMonthly ContractOneYear
									PaymentMethodAutomatic
									PaperlessBillingYes 
									TVMovies DependentsPartner FibreMonthlycharges;
 weight selected;
 title 'Step 1';
run;

proc logistic inmodel=Logitmodel;
 score data=churn1_test outroc=churn_logit_roc;
 title 'Step 2';
run;
proc contents data=churn_logit_roc;
run;

data churn_cost;
set churn_logit_roc;
False_positive_cost=20*_FALPOS_; /*False positive cost is the cost of mistakenly predicted a churn while a customer stays*/
False_negative_cost=80*_FALNEG_;/* False negative cost is the cost of incorrectly predicting that a churning customer will stay*/
Total_cost=False_positive_cost+False_negative_cost;
run;

data churn_cost_email;
set churn_logit_roc;
False_positive_cost=3*_FALPOS_; /*False positive cost is the cost of mistakenly predicted a churn while a customer stays*/
False_negative_cost=10*_FALNEG_;/* False negative cost is the cost of incorrectly predicting that a churning customer will stay*/
Total_cost=False_positive_cost+False_negative_cost;
run;
