/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
DROP PREV TABLES
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

USE [NHSE_Sandbox_CHC]
IF OBJECT_ID (N'dbo.tbl_CHC_PLDS_Recon_Quarterly_01') IS NOT NULL
DROP TABLE [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_Recon_Quarterly_01]
IF OBJECT_ID (N'dbo.tbl_CHC_PLDS_Recon_Quarterly_02') IS NOT NULL
DROP TABLE [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_Recon_Quarterly_02]
IF OBJECT_ID (N'dbo.tbl_CHC_PLDS_Recon_Quarterly_03') IS NOT NULL
DROP TABLE [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_Recon_Quarterly_03]
IF OBJECT_ID (N'dbo.tbl_CHC_PLDS_Recon_Quarterly_04') IS NOT NULL
DROP TABLE [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_Recon_Quarterly_04]
IF OBJECT_ID (N'dbo.tbl_CHC_PLDS_Recon_Quarterly_05') IS NOT NULL
DROP TABLE [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_Recon_Quarterly_05]
IF OBJECT_ID (N'dbo.tbl_CHC_PLDS_Recon_Quarterly_06') IS NOT NULL
DROP TABLE [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_Recon_Quarterly_06]
IF OBJECT_ID (N'dbo.tbl_CHC_PLDS_Recon_Quarterly_07') IS NOT NULL
DROP TABLE [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_Recon_Quarterly_07]
IF OBJECT_ID (N'dbo.tbl_CHC_PLDS_Recon_Quarterly_08') IS NOT NULL
DROP TABLE [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_Recon_Quarterly_08]
IF OBJECT_ID (N'dbo.tbl_CHC_PLDS_Recon_Quarterly_09') IS NOT NULL
DROP TABLE [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_Recon_Quarterly_09]


/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CHC_PLDS_Recon_01	Percentage of standard CHC referrals completed within 28 days
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

-- v1.4 Brackets missing from the WHERE clauses in orginal code so I've added these in 
-- v1.4 Not eligible for std CHC but eligible for FNC ([CommEligibilityDecisionOutcomeStandardCHC] = 02) was missing from All Referrals WHERE clause so have added in
-- v1.4 Changed to assign quarter using RefDiscountedDateStandardCHC or CommEligibilityDecisionDateStandardCHC instead of ReportingPeriod quarter (required a UNION)
-- v1.7 Updated logic around discounted referrals
-- v1.10 Swapped AgeServReferRecDateYears >= 18 to AgeRepPeriodEndYears >= 18

----------*************************----------
------------REFERRALS IN 28 DAYS-------------
----------*************************----------

DECLARE @firstMonthOfFiscalQ1 int = 4; -- sets April (month 4) as start of Fiscal Q1

IF OBJECT_ID ('tempdb..#Refsin28daysSL') IS NOT NULL
DROP TABLE #Refsin28daysSL

SELECT a.LocalPatientID
	  ,a.ServiceRequestId
	  ,a.OrgIDComm
	  ,b.[Sub_ICB_Location_Name_Local_Reference]
	  ,b.ICB_Code
	  ,b.Integrated_Care_Board_Name
	  ,b.Region_Code
	  ,b.Region_Name
	  --,a.ReferralRequestReceivedDateCHC
	  --,a.RefRequestStandardCHC
	  --,a.RefNotificationOutcomeStandardCHC
	  --,a.RefDiscountReasonCHC
	  --,c.RPEndDate
	  , CONVERT(varchar, YEAR(RefDiscountedDateStandardCHC) - IIF(MONTH(RefDiscountedDateStandardCHC) < @firstMonthOfFiscalQ1, 1, 0)) 
		  + '/'
		  + RIGHT(CONVERT(varchar, (YEAR(RefDiscountedDateStandardCHC)+1) - IIF(MONTH(RefDiscountedDateStandardCHC) < @firstMonthOfFiscalQ1, 1, 0)),2)
		  + ' Q' 
		  + CONVERT(varchar, FLOOR(((12 + MONTH(RefDiscountedDateStandardCHC) - @firstMonthOfFiscalQ1) % 12) / 3 ) + 1) AS [Quarter]

INTO #Refsin28daysSL

FROM [NHSE_Sandbox_CHC].[chc].[vw_reporting_101_ReferralAssessmentOutcome_Current] a

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_001_MPI_Current] mpi 

ON mpi.LocalPatientId = a.LocalPatientId AND mpi.UniqSubmissionID = a.UniqSubmissionID

LEFT JOIN [NHSE_Reference].[dbo].[vw_Ref_ODS_Commissioner_Hierarchies] b

ON b.Organisation_Code = a.OrgIDComm

WHERE

--Discounted (Below makes the assumption that where referral discounted date is complete, that the service request started out as a 'referral for assessment')

[ActivityTypeCHC] = '01' 

AND DATEDIFF(DAY,[ReferralRequestReceivedDateCHC],[RefDiscountedDateStandardCHC]) < 29

AND a.RecordEndDate is NULL 

--30.01.23 added condition to exclude transition cases
AND AgeRepPeriodEndYears >= 18

AND [RefDiscountedDateStandardCHC] > '2022-03-31'  -- FY 22/23 onwards only

UNION

-- Refer for full assessment 

SELECT a.LocalPatientID
	  ,a.ServiceRequestId
	  ,a.OrgIDComm
	  ,b.[Sub_ICB_Location_Name_Local_Reference]
	  ,b.ICB_Code
	  ,b.Integrated_Care_Board_Name
	  ,b.Region_Code
	  ,b.Region_Name
--	  ,ReferralRequestReceivedDateCHC
--	  ,CommEligibilityDecisionDateStandardCHC AS DecisionorDiscountedDate
      , CONVERT(varchar, YEAR(CommEligibilityDecisionDateStandardCHC) - IIF(MONTH(CommEligibilityDecisionDateStandardCHC) < @firstMonthOfFiscalQ1, 1, 0)) 
		  + '/'
		  + RIGHT(CONVERT(varchar, (YEAR(CommEligibilityDecisionDateStandardCHC)+1) - IIF(MONTH(CommEligibilityDecisionDateStandardCHC) < @firstMonthOfFiscalQ1, 1, 0)),2)
		  + ' Q' 
		  + CONVERT(varchar, FLOOR(((12 + MONTH(CommEligibilityDecisionDateStandardCHC) - @firstMonthOfFiscalQ1) % 12) / 3 ) + 1) AS [Quarter]

FROM [NHSE_Sandbox_CHC].[chc].[vw_reporting_101_ReferralAssessmentOutcome_Current] a

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_001_MPI_Current] mpi 

ON mpi.LocalPatientId = a.LocalPatientId AND mpi.UniqSubmissionID = a.UniqSubmissionID

LEFT JOIN [NHSE_Reference].[dbo].[vw_Ref_ODS_Commissioner_Hierarchies] b

ON b.Organisation_Code = a.OrgIDComm

WHERE

[ActivityTypeCHC] = '01' 

AND RefNotificationOutcomeStandardCHC = '01' 

AND [RefDiscountReasonCHC] is NULL  

AND [RefDiscountedDateStandardCHC] is NULL

AND [CommEligibilityDecisionOutcomeStandardCHC] IN ('01', '02', '03') -- Eligible for Std CHC, Not eligible for Std CHC but elgiible for FNC, Not elibile for Std CHC

AND DATEDIFF(DAY,[ReferralRequestReceivedDateCHC],[CommEligibilityDecisionDateStandardCHC]) < 29

AND a.RecordEndDate is NULL 

AND AgeRepPeriodEndYears >= 18

AND [CommEligibilityDecisionDateStandardCHC] > '2022-03-31' -- FY 22/23 onwards only



----------*************************----------
---------------ALL REFERRALS-----------------
----------*************************----------

IF OBJECT_ID ('tempdb..#AllRefsComp') IS NOT NULL
DROP TABLE #AllRefsComp

--DECLARE @firstMonthOfFiscalQ1 int = 4

SELECT a.LocalPatientID
	  ,a.ServiceRequestId
	  ,a.OrgIDComm
	  ,b.[Sub_ICB_Location_Name_Local_Reference]
	  ,b.ICB_Code
	  ,b.Integrated_Care_Board_Name
	  ,b.Region_Code
	  ,b.Region_Name
	  --,a.ReferralRequestReceivedDateCHC
	  --,a.RefRequestStandardCHC
	  --,a.RefNotificationOutcomeStandardCHC
	  --,a.RefDiscountReasonCHC
	  --,c.RPEndDate
	  , CONVERT(varchar, YEAR(RefDiscountedDateStandardCHC) - IIF(MONTH(RefDiscountedDateStandardCHC) < @firstMonthOfFiscalQ1, 1, 0)) 
		  + '/'
		  + RIGHT(CONVERT(varchar, (YEAR(RefDiscountedDateStandardCHC)+1) - IIF(MONTH(RefDiscountedDateStandardCHC) < @firstMonthOfFiscalQ1, 1, 0)),2)
		  + ' Q' 
		  + CONVERT(varchar, FLOOR(((12 + MONTH(RefDiscountedDateStandardCHC) - @firstMonthOfFiscalQ1) % 12) / 3 ) + 1) AS [Quarter]

INTO #AllRefsComp

FROM [NHSE_Sandbox_CHC].[chc].[vw_reporting_101_ReferralAssessmentOutcome_Current] a

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_001_MPI_Current] mpi 

ON mpi.LocalPatientId = a.LocalPatientId AND mpi.UniqSubmissionID = a.UniqSubmissionID

LEFT JOIN [NHSE_Reference].[dbo].[vw_Ref_ODS_Commissioner_Hierarchies] b

ON b.Organisation_Code = a.OrgIDComm

WHERE

--Discounted (Below makes the assumption that where referral discounted date is complete, that the service request started out as a 'referral for assessment')

[ActivityTypeCHC] = '01' 

AND [RefDiscountedDateStandardCHC] is not NULL

AND a.RecordEndDate is NULL 

--30.01.23 added condition to exclude transition cases
AND AgeRepPeriodEndYears >= 18

AND [RefDiscountedDateStandardCHC] > '2022-03-31'  -- FY 22/23 onwards only

UNION

-- Refer for full assessment 

SELECT a.LocalPatientID
	  ,a.ServiceRequestId
	  ,a.OrgIDComm
	  ,b.[Sub_ICB_Location_Name_Local_Reference]
	  ,b.ICB_Code
	  ,b.Integrated_Care_Board_Name
	  ,b.Region_Code
	  ,b.Region_Name
--	  ,ReferralRequestReceivedDateCHC
--	  ,CommEligibilityDecisionDateStandardCHC AS DecisionorDiscountedDate
      , CONVERT(varchar, YEAR(CommEligibilityDecisionDateStandardCHC) - IIF(MONTH(CommEligibilityDecisionDateStandardCHC) < @firstMonthOfFiscalQ1, 1, 0)) 
		  + '/'
		  + RIGHT(CONVERT(varchar, (YEAR(CommEligibilityDecisionDateStandardCHC)+1) - IIF(MONTH(CommEligibilityDecisionDateStandardCHC) < @firstMonthOfFiscalQ1, 1, 0)),2)
		  + ' Q' 
		  + CONVERT(varchar, FLOOR(((12 + MONTH(CommEligibilityDecisionDateStandardCHC) - @firstMonthOfFiscalQ1) % 12) / 3 ) + 1) AS [Quarter]

FROM [NHSE_Sandbox_CHC].[chc].[vw_reporting_101_ReferralAssessmentOutcome_Current] a

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_001_MPI_Current] mpi 

ON mpi.LocalPatientId = a.LocalPatientId AND mpi.UniqSubmissionID = a.UniqSubmissionID

LEFT JOIN [NHSE_Reference].[dbo].[vw_Ref_ODS_Commissioner_Hierarchies] b

ON b.Organisation_Code = a.OrgIDComm

WHERE

[ActivityTypeCHC] = '01' 

AND RefNotificationOutcomeStandardCHC = '01' 

AND [RefDiscountReasonCHC] is NULL  

AND [RefDiscountedDateStandardCHC] is NULL

AND [CommEligibilityDecisionOutcomeStandardCHC] IN ('01', '02', '03') -- Eligible for Std CHC, Not eligible for Std CHC but elgiible for FNC, Not elibile for Std CHC

AND a.RecordEndDate is NULL 

AND AgeRepPeriodEndYears >= 18

AND [CommEligibilityDecisionDateStandardCHC] > '2022-03-31' -- FY 22/23 onwards only



----------------------------------------------------------------------------
-- Example of RefDiscountedDate being used incorrectly - DQ investigation
----------------------------------------------------------------------------

--select * from #AllRefsComp 
--where LocalPatientId = '8702' and OrgIDComm = '03n'

--select * from [NHSE_Sandbox_CHC].[chc].[vw_reporting_101_ReferralAssessmentOutcome_Current] 
--where LocalPatientId = '8702' and OrgIDComm = '03n'
--and RecordEndDate is null 



----------********************---------
---------------OUTPUT------------------    
----------********************---------    

SELECT	 a.OrgIDComm
		,a.[Sub_ICB_Location_Name_Local_Reference]
		,a.ICB_Code
		,a.Integrated_Care_Board_Name
		,a.Region_Code
		,a.Region_Name
		,a.[Quarter]
--		,CAST(LEFT(a.[Quarter],4) AS int) AS [FY]
--		,a.LocalPatientID
		,COUNT(a.ServiceRequestId) AS AllReferrals
		,COUNT(b.ServiceRequestId) AS Referralsin28
		,CAST(COUNT(b.ServiceRequestId) AS float) / CAST(COUNT(a.ServiceRequestId) AS float) AS [Percentage_Refsin28]

INTO [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_Recon_Quarterly_01] 

FROM #AllRefsComp a

LEFT JOIN #Refsin28daysSL b

ON b.OrgIDComm = a.OrgIDComm AND b.LocalPatientId = a.LocalPatientId AND b.ServiceRequestId = a.ServiceRequestId

WHERE CAST(LEFT(a.[Quarter],4) AS int) > 2021  -- excludes historic referrals caused by poor DQ

GROUP BY a.OrgIDComm
		,a.[Sub_ICB_Location_Name_Local_Reference]
--		,a.LocalPatientId
		,a.ICB_Code
		,a.Integrated_Care_Board_Name
		,a.Region_Code
		,a.Region_Name
		,a.[Quarter]
--		,CAST(LEFT(a.[Quarter],4) AS int)
		


/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CHC_PLDS_Recon_02	Number of incomplete referrals exceeding 28 days by 12+ weeks
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

-- Over half are referrals from 2021 or earlier, do we want to include that far back?! 
-- Maybe these are being stripped out in aggregate? Since large reconciliation difference
-- v1.5 Have removed RIP patients
-- v1.6 Added back in RIP patients
-- v1.7 Corrected number of days to 112 (28 days + 12 weeks) instead of 84 (12 weeks)
--      Corrected day referral received to day 0 instead of day 1 (as per aggregate policy)
--      Removed 'RefRequestStandardCHC' IN ('01','02') incase this had not been completed and would lead to referrals being missed
-- v1.9 Excluded historical referrals (prior to FY 22/23)
-- v1.10 Swapped AgeServReferRecDateYears >= 18 to AgeRepPeriodEndYears >= 18
-- v1.11 Added Sub Query with partition to select the most record of each referral (service request) per Quarter

----------*************************----------
----------GET 12+ WEEKS COHORT DATA----------
----------*************************----------

IF OBJECT_ID ('tempdb..#Over12WeeksSL') IS NOT NULL
DROP TABLE #Over12WeeksSL

SELECT LocalPatientId   
	  ,ServiceRequestId 
	  ,OrgIDComm
	  ,[Sub_ICB_Location_Name_Local_Reference]
	  ,ICB_Code
	  ,Integrated_Care_Board_Name
	  ,Region_Code
	  ,Region_Name
	  ,[Quarter]
	  --,ReferralRequestReceivedDateCHC
	  --,RefDiscountedDateStandardCHC
	  --,CommEligibilityDecisionDateStandardCHC

INTO #Over12WeeksSL

FROM (
		SELECT ROW_NUMBER() OVER(PARTITION BY a.OrgIDComm, a.LocalPatientID, a.ServiceRequestId, d.[Quarter] ORDER BY c.RPEndDate DESC) RN  
			  ,a.ServiceRequestId  
			  ,a.LocalPatientId   
			  ,a.OrgIDComm
			  ,b.[Sub_ICB_Location_Name_Local_Reference]
			  ,b.ICB_Code
			  ,b.Integrated_Care_Board_Name
			  ,b.Region_Code
			  ,b.Region_Name
			  ,d.[Quarter]
			  --,c.RPEndDate
			  ,a.ActivityTypeCHC
			  ,a.ReferralRequestReceivedDateCHC
			  ,a.RefNotificationOutcomeStandardCHC
			  ,a.RefDiscountedDateStandardCHC
			  ,a.CommEligibilityDecisionDateStandardCHC
			  ,mpi.AgeRepPeriodEndYears
			  ,d.QuarterEndDate
--			  ,c.RPEndDate

FROM [NHSE_Sandbox_CHC].[chc].[vw_reporting_101_ReferralAssessmentOutcome_Current] a

LEFT JOIN [NHSE_Reference].[dbo].[vw_Ref_ODS_Commissioner_Hierarchies] b

ON b.Organisation_Code = a.OrgIDComm

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_001_MPI_Current] mpi 

ON mpi.LocalPatientId = a.LocalPatientId AND mpi.UniqSubmissionID = a.UniqSubmissionID

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_000_Header_Current] c

ON c.UniqSubmissionID = a.UniqSubmissionID

LEFT JOIN [NHSE_Sandbox_CHC].[dbo].[tbl_Period_Lookup_PLDS_temp] d

ON d.[RPEndDate] = c.RPEndDate

) r

WHERE RN = 1

AND ActivityTypeCHC = '01' 

AND ReferralRequestReceivedDateCHC < CAST(QuarterEndDate AS DATE)

AND RefNotificationOutcomeStandardCHC = '01'	

AND (CommEligibilityDecisionDateStandardCHC IS NULL OR CommEligibilityDecisionDateStandardCHC > CAST(QuarterEndDate AS date))

AND (RefDiscountedDateStandardCHC IS NULL OR RefDiscountedDateStandardCHC > CAST(QuarterEndDate AS date))

--AND [RefDiscountReasonCHC] is NULL

AND DATEDIFF(DAY,[ReferralRequestReceivedDateCHC],CAST(QuarterEndDate AS DATE)) > 112 

--30.01.23 added condition to exclude transition cases
AND AgeRepPeriodEndYears >= 18

-- FY 22/23 onwards only i.e. exclude historic referrals 
AND ReferralRequestReceivedDateCHC > '2022-03-31'

GROUP BY  LocalPatientId   
		 ,ServiceRequestId 
		 ,OrgIDComm
		 ,[Sub_ICB_Location_Name_Local_Reference]
		 ,ICB_Code
		 ,Integrated_Care_Board_Name
		 ,Region_Code
		 ,Region_Name
		 ,[Quarter]
		 --,ReferralRequestReceivedDateCHC
		 --,RefDiscountedDateStandardCHC
		 --,CommEligibilityDecisionDateStandardCHC

		 
----------*************************----------
-------------REFS >12 WEEKS OUTPUT-----------
----------*************************----------

SELECT OrgIDComm
	  ,[Sub_ICB_Location_Name_Local_Reference]
	  ,ICB_Code
	  ,Integrated_Care_Board_Name
	  ,Region_Code
	  ,Region_Name
	  --,RPEndDate
	  ,[Quarter]
	  ,COUNT (*) AS [Referrals>12Weeks]

INTO [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_Recon_Quarterly_02]

FROM #Over12WeeksSL

GROUP BY OrgIDComm
		,[Sub_ICB_Location_Name_Local_Reference]
		,ICB_Code
		,Integrated_Care_Board_Name
		,Region_Code
		,Region_Name
		,[Quarter]
		--,RPEndDate



/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CHC_PLDS_Recon_03	Percentage of Decision Support Tools carried out in an acute hospital setting
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

-- v1.4 Changed to assign quarter using DecSupportToolCompletionDateStandardCHC instead of ReportingPeriod quarter (and added WHERE clause to include DSTs completed in FY 22/23 onwards only)
-- v1.10 Swapped AgeServReferRecDateYears >= 18 to AgeRepPeriodEndYears >= 18

----------*************************----------
---------------GET DST DATA------------------
----------*************************----------

IF OBJECT_ID ('tempdb..#DSTdataSL') IS NOT NULL
DROP TABLE #DSTdataSL

--DECLARE @firstMonthOfFiscalQ1 int = 4 --1=January

SELECT a.LocalPatientID
	  ,a.ServiceRequestId
	  ,a.OrgIDComm
	  ,b.[Sub_ICB_Location_Name_Local_Reference]
	  ,b.ICB_Code
	  ,b.Integrated_Care_Board_Name
	  ,b.Region_Code
	  ,b.Region_Name
	  ,a.DecSupportToolCompletionDateStandardCHC
	  --,c.Unique_MonthID
	  --,c.RPEndDate
	  ,CASE WHEN [PatientSettingDecisionSupportToolStandardCHC] = 1 THEN 1 ELSE 0 END AS UniqDSTsinAcute
      ,CASE WHEN [DecSupportToolCompletionDateStandardCHC] IS NOT NULL THEN 1 ELSE 0 END AS UniqDSTsComplete
	  ,CONVERT(varchar, YEAR(DecSupportToolCompletionDateStandardCHC) - IIF(MONTH(DecSupportToolCompletionDateStandardCHC) < @firstMonthOfFiscalQ1, 1, 0)) 
		  + '/'
		  + RIGHT(CONVERT(varchar, (YEAR(DecSupportToolCompletionDateStandardCHC)+1) - IIF(MONTH(DecSupportToolCompletionDateStandardCHC) < @firstMonthOfFiscalQ1, 1, 0)),2)
		  + ' Q' 
		  + CONVERT(varchar, FLOOR(((12 + MONTH(DecSupportToolCompletionDateStandardCHC) - @firstMonthOfFiscalQ1) % 12) / 3 ) + 1) AS [Quarter]

INTO #DSTdataSL

FROM [NHSE_Sandbox_CHC].[chc].[vw_reporting_101_ReferralAssessmentOutcome_Current] a

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_001_MPI_Current] mpi 

ON mpi.LocalPatientId = a.LocalPatientId AND mpi.UniqSubmissionID = a.UniqSubmissionID

LEFT JOIN [NHSE_Reference].[dbo].[vw_Ref_ODS_Commissioner_Hierarchies] b

ON b.Organisation_Code = a.OrgIDComm

WHERE AgeRepPeriodEndYears >= 18

AND a.RecordEndDate IS NULL

AND a.DecSupportToolCompletionDateStandardCHC IS NOT NULL --55,645

AND a.DecSupportToolCompletionDateStandardCHC > '2022-03-31'


----------*************************----------
------------------DST OUTPUT-----------------
----------*************************----------

SELECT OrgIDComm
	  ,[Sub_ICB_Location_Name_Local_Reference]
	  ,ICB_Code
	  ,Integrated_Care_Board_Name
	  ,Region_Code
	  ,Region_Name
	  --,Unique_MonthID
	  --,RPEndDate
	  ,[Quarter]
	  ,CAST(SUM([UniqDSTsinAcute]) as float) AS [DSTsinAcute]
	  ,CAST(SUM([UniqDSTsComplete]) as float) AS [DSTsComplete]
	  ,CAST(SUM([UniqDSTsinAcute]) as float) / CAST(SUM([UniqDSTsComplete]) as float) AS [Percentage_DSTsinAcute]

INTO [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_Recon_Quarterly_03] 

FROM #DSTdataSL

GROUP BY OrgIDComm
		,[Sub_ICB_Location_Name_Local_Reference]
		,ICB_Code
		,Integrated_Care_Board_Name
		,Region_Code
		,Region_Name
		,[Quarter]
		--,Unique_MonthID
		--,RPEndDate


-----------------------------------------------------------------
-- Check against raw data check using St Helens as an example
---------------------------------------------------------------

--select * from #RWtest2 
--where orgidcomm = '01X'
--order by [Quarter] 

--select * from [NHSE_Sandbox_CHC].[chc].[vw_reporting_101_ReferralAssessmentOutcome_Current]
--where orgidcomm = '01X'
--and DecSupportToolCompletionDateStandardCHC is not null 
--AND RecordEndDate IS NULL
--order by DecSupportToolCompletionDateStandardCHC




/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CHC_PLDS_Recon_04	Number eligible at the end of the quarter (snapshot) - Standard CHC
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

-- v1.4 Removed already eligibile section until corrected
-- v1.4 Changed one line of Eligible via LR WHERE clause, since field looked incorrect
-- v1.5 Added missing brackets around 3 different eligibility possibilities
-- v1.5 Have removed RIP patients
-- v1.6 Updated RIP clause to take account of EndDateFunding
-- v1.8 Removed duplicated LocalPatientIDs by selecting most recent record only
-- v1.10 Swapped AgeServReferRecDateYears >= 18 to AgeRepPeriodEndYears >= 18
-- v1.11 Logic was previously including any patient that was eligible during the quarter so have corrected it to include only those eligible at the end of the quarter

------**********************************-------
-------SUMMARY OF HOW METRIC IS WORKING
------**********************************-------
-- Sub query with PARTITION - For each patient ID, for each of their service request IDs, select the most recent per quarter e.g. If a patient has two service request IDs 
-- both appearing in April 24 and May 24 (4 records in total), then the partition will select the two May records only for Q1 2024
-- WHERE Clause - then checks if the service request records selected by the partition (the two May 24 records in the example) meet the conditions to be counted in the metric
-- (i.e. are eligible)
-- GROUP BY prevents patients from being counted multiple times if they have multiple service requests that meet the conditions (patient in example would only be counted once
-- instead of twice)

----------*************************----------
-----------SERVICE LEVEL STD SNAP-----------
----------*************************----------    

IF OBJECT_ID ('tempdb..#StdSnapShotSL') IS NOT NULL
DROP TABLE #StdSnapShotSL

SELECT   OrgIDComm
		,[Sub_ICB_Location_Name_Local_Reference]
		,ICB_Code
		,Integrated_Care_Board_Name
		,Region_Code
		,Region_Name
		,[Quarter]
		,LocalPatientID
	  
INTO #StdSnapShotSL

FROM (
	   SELECT ROW_NUMBER() OVER(PARTITION BY a.OrgIDComm, a.LocalPatientID, a.ServiceRequestId, d.[Quarter] ORDER BY c.RPEndDate DESC) RN  
	  ,a.LocalPatientID
	  ,a.ServiceRequestId
	  ,a.OrgIDComm
	  ,b.[Sub_ICB_Location_Name_Local_Reference]
	  ,b.ICB_Code
	  ,b.Integrated_Care_Board_Name
	  ,b.Region_Code
	  ,b.Region_Name
	  ,CASE WHEN EndDateFunding IS NOT NULL THEN EndDateFunding
			WHEN EndDateFunding IS NULL AND PersonDeathDate IS NOT NULL THEN PersonDeathDate
			ELSE NULL
			END AS [EndDate]
	  ,a.ActivityTypeCHC
	  ,a.ReferralRequestReceivedDateCHC
	  ,a.CommEligibilityDecisionDateStandardCHC
	  ,a.EndDateFunding
	  ,a.EndDateLocalResolution
	  ,a.CommEligibilityDecisionOutcomeStandardCHC
	  ,a.CommReviewOutcome
	  ,a.RefDiscountReasonCHC
	  ,a.RefDiscountedDateStandardCHC
	  ,a.DateEligibilityBeginsLocalResolution
	  ,mpi.AgeRepPeriodEndYears
	  ,mpi.PersonDeathDate
	  ,d.[Quarter]
	  ,d.QuarterStartDate
	  ,d.QuarterEndDate
	  ,c.RPEndDate
	  --,DATEADD(day,1,c.RPEndDate) AS [PopulationsDate]

FROM [NHSE_Sandbox_CHC].[chc].[vw_reporting_101_ReferralAssessmentOutcome_Current] a

LEFT JOIN [NHSE_Reference].[dbo].[vw_Ref_ODS_Commissioner_Hierarchies] b

ON b.Organisation_Code = a.OrgIDComm

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_001_MPI_Current] mpi 

ON mpi.LocalPatientId = a.LocalPatientId AND mpi.UniqSubmissionID = a.UniqSubmissionID

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_000_Header_Current] c

ON c.UniqSubmissionID = a.UniqSubmissionID

LEFT JOIN [NHSE_Sandbox_CHC].[dbo].[tbl_Period_Lookup_PLDS_temp] d

ON d.[RPEndDate] = c.RPEndDate

) r 

WHERE RN = 1  

AND

(
--Eligible via Std CHC ref   
(
ActivityTypeCHC = '01' 
AND CommEligibilityDecisionDateStandardCHC <= QuarterEndDate
AND CommEligibilityDecisionOutcomeStandardCHC = '01'
AND (	 (CASE WHEN EndDateFunding IS NOT NULL THEN EndDateFunding
			   WHEN EndDateFunding IS NULL AND PersonDeathDate IS NOT NULL THEN PersonDeathDate
			   ELSE NULL 
			   END IS NULL)
      OR (CASE WHEN EndDateFunding IS NOT NULL THEN EndDateFunding
			   WHEN EndDateFunding IS NULL AND PersonDeathDate IS NOT NULL THEN PersonDeathDate
			   ELSE NULL
			   END > QuarterEndDate)
	)
--30.01.23 Last condition added to exclude cases which are found eligible but application is withdrawn by family before funding starts)
AND RefDiscountReasonCHC IS NULL
AND (RefDiscountedDateStandardCHC IS NULL OR RefDiscountedDateStandardCHC > QuarterEndDate)
)

OR
--Eligible via LR     
(
ActivityTypeCHC = '04' 
AND CommEligibilityDecisionDateStandardCHC <= QuarterEndDate
AND (CommEligibilityDecisionOutcomeStandardCHC = '01' OR CommReviewOutcome = '01')
AND (   (EndDateLocalResolution IS NULL 
		 AND CASE WHEN EndDateFunding IS NOT NULL THEN EndDateFunding
				  WHEN EndDateFunding IS NULL AND PersonDeathDate IS NOT NULL THEN PersonDeathDate
				  ELSE NULL 
				  END  IS NULL
		)
	 OR (EndDateLocalResolution IS NULL 
		 AND CASE WHEN EndDateFunding IS NOT NULL THEN EndDateFunding
				  WHEN EndDateFunding IS NULL AND PersonDeathDate IS NOT NULL THEN PersonDeathDate
				  ELSE NULL 
				  END > QuarterEndDate
		) 
	 OR (EndDateLocalResolution > QuarterEndDate 
		 AND CASE WHEN EndDateFunding IS NOT NULL THEN EndDateFunding
				  WHEN EndDateFunding IS NULL AND PersonDeathDate IS NOT NULL THEN PersonDeathDate
				  ELSE NULL 
				  END  IS NULL
		) 
	 OR (CASE WHEN EndDateFunding IS NOT NULL THEN EndDateFunding
				  WHEN EndDateFunding IS NULL AND PersonDeathDate IS NOT NULL THEN PersonDeathDate
				  ELSE NULL 
				  END = EndDateLocalResolution 
		 AND EndDateLocalResolution > QuarterEndDate
		)
    )
)

OR
--Eligible via IR    
(DateEligibilityBeginsLocalResolution < QuarterStartDate
AND (	 (CASE WHEN EndDateFunding IS NOT NULL THEN EndDateFunding
			   WHEN EndDateFunding IS NULL AND PersonDeathDate IS NOT NULL THEN PersonDeathDate
			   ELSE NULL 
			   END IS NULL)
      OR (CASE WHEN EndDateFunding IS NOT NULL THEN EndDateFunding
			   WHEN EndDateFunding IS NULL AND PersonDeathDate IS NOT NULL THEN PersonDeathDate
			   ELSE NULL
			   END > QuarterEndDate)
	)
)
)

AND AgeRepPeriodEndYears >= 18      --  ungrouped: 236,319, grouped: 233,786 vs old version: 243,170 

GROUP BY OrgIDComm
		,[Sub_ICB_Location_Name_Local_Reference]
		,ICB_Code
		,Integrated_Care_Board_Name
		,Region_Code
		,Region_Name
		,[Quarter]
		,LocalPatientID



--IF OBJECT_ID ('tempdb..#snapshotMinusAlreadyEligible') IS NOT NULL
--DROP TABLE #snapshotMinusAlreadyEligible

--SELECT	a.LocalPatientID
--		,a.OrgIDComm
--		,a.[Sub_ICB_Location_Name_Local_Reference]
--		,a.ICB_Code
--		,a.Integrated_Care_Board_Name
--		,a.Region_Code
--		,a.Region_Name
--		,a.[Quarter]
--		--,a.RPEndDate
--		--,DATEADD(day,1,RPEndDate) AS [PopulationsDate]
--		,COUNT(a.ServiceRequestId) AS NewRefsCount
--		,COUNT(b.LocalPatientId) AS PtAlreadyEligibleCount
--		,COUNT(a.ServiceRequestId) - COUNT(b.LocalPatientId) AS NewRef

--INTO #snapshotMinusAlreadyEligible

--FROM #StdSnapShotSL a

--LEFT JOIN #AlreadyEligible b 

--ON b.LocalPatientId = a.LocalPatientId
--AND b.OrgIDComm = a.OrgIDComm
--AND b.[Quarter] = a.[Quarter]

--GROUP BY a.OrgIDComm
--		,a.[Sub_ICB_Location_Name_Local_Reference]
--		,a.ICB_Code
--		,a.Integrated_Care_Board_Name
--		,a.Region_Code
--		,a.Region_Name
--		,a.LocalPatientID
--		,a.[Quarter]
--		--,a.Unique_MonthID
--		--,a.RPEndDate


----------*************************----------
------------------OUTPUT---------------------
----------*************************----------

SELECT a.OrgIDComm
	  ,a.[Sub_ICB_Location_Name_Local_Reference]
	  ,a.ICB_Code
	  ,a.Integrated_Care_Board_Name
	  ,a.Region_Code
	  ,a.Region_Name
	  ,a.[Quarter]
	  --,a.RPEndDate
	  ,COUNT(*) AS [StdSnapshot]
	  --,b.[Population]
	  --,(COUNT(*) / CAST(SUM(b.[Population]) as float)) * 50000 AS [StdSnapshot50k]
	  	  
INTO [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_Recon_Quarterly_04]

FROM #StdSnapShotSL a

--INNER JOIN #Populations b ON b.Org_Code collate SQL_Latin1_General_CP1_CI_AS = a.OrgIDComm collate SQL_Latin1_General_CP1_CI_AS AND b.Effective_Snapshot_Date = a.PopulationsDate

GROUP BY a.OrgIDComm
		,a.[Sub_ICB_Location_Name_Local_Reference]
		,a.ICB_Code
		,a.Integrated_Care_Board_Name
		,a.Region_Code
		,a.Region_Name
		,a.[Quarter]
		--,a.RPEndDate
		--,[Population]



/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CHC_PLDS_Recon_05	Number eligible at the end of the quarter (snapshot) - Fast-Track CHC
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

-- v1.5 Have removed RIP patients
-- v1.6 Updated RIP clause to take account of EndDateFunding
-- v1.8 Removed duplicated LocalPatientIDs by selecting most recent record only
-- v1.10 Swapped AgeServReferRecDateYears >= 18 to AgeRepPeriodEndYears >= 18
-- v1.11 Logic was previously including any patient that was eligible during the quarter so have corrected it to include only those eligible at the end of the quarter

--------*************************----------
----------SERVICE LEVEL FT SNAP------------
--------*************************----------

IF OBJECT_ID ('tempdb..#FTSnapShotSL') IS NOT NULL
DROP TABLE #FTSnapShotSL

SELECT   OrgIDComm
		,[Sub_ICB_Location_Name_Local_Reference]
		,ICB_Code
		,Integrated_Care_Board_Name
		,Region_Code
		,Region_Name
		,[Quarter]
		,LocalPatientID

INTO #FTSnapShotSL

FROM (SELECT ROW_NUMBER() OVER(PARTITION BY a.OrgIDComm, a.LocalPatientID, a.ServiceRequestId, d.[Quarter] ORDER BY c.RPEndDate DESC) RN
	  ,a.LocalPatientID
	  ,a.ServiceRequestId
	  ,a.OrgIDComm
	  ,b.[Sub_ICB_Location_Name_Local_Reference]
	  ,b.ICB_Code
	  ,b.Integrated_Care_Board_Name
	  ,b.Region_Code
	  ,b.Region_Name
	  ,a.ActivityTypeCHC
	  ,a.ReferralRequestReceivedDateCHC
	  ,a.RefAcceptedDateFastTrack
	  ,a.RefDiscountedDateStandardCHC
	  ,a.RefDiscountReasonCHC
	  ,CASE WHEN EndDateFunding IS NOT NULL THEN EndDateFunding
			WHEN EndDateFunding IS NULL AND PersonDeathDate IS NOT NULL THEN PersonDeathDate
			ELSE NULL
			END AS [EndDate]
	  ,mpi.PersonDeathDate
	  ,a.EndDateFunding
	  ,mpi.AgeRepPeriodEndYears
	  ,d.[Quarter]
	  ,d.QuarterStartDate
	  ,d.QuarterEndDate
	  ,c.RPEndDate
	  --,DATEADD(day,1,c.RPEndDate) AS [PopulationsDate]

FROM [NHSE_Sandbox_CHC].[chc].[vw_reporting_101_ReferralAssessmentOutcome_Current] a

LEFT JOIN [NHSE_Reference].[dbo].[vw_Ref_ODS_Commissioner_Hierarchies] b

ON b.Organisation_Code = a.OrgIDComm

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_001_MPI_Current] mpi 

ON mpi.LocalPatientId = a.LocalPatientId AND mpi.UniqSubmissionID = a.UniqSubmissionID

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_000_Header_Current] c

ON c.UniqSubmissionID = a.UniqSubmissionID

LEFT JOIN [NHSE_Sandbox_CHC].[dbo].[tbl_Period_Lookup_PLDS_temp] d

ON d.[RPEndDate] = c.RPEndDate

) r

WHERE RN = 1  

AND ActivityTypeCHC = '02' 

AND RefAcceptedDateFastTrack <= QuarterEndDate

AND (	 (CASE WHEN EndDateFunding IS NOT NULL THEN EndDateFunding
			   WHEN EndDateFunding IS NULL AND PersonDeathDate IS NOT NULL THEN PersonDeathDate
			   ELSE NULL 
			   END IS NULL)
      OR (CASE WHEN EndDateFunding IS NOT NULL THEN EndDateFunding
			   WHEN EndDateFunding IS NULL AND PersonDeathDate IS NOT NULL THEN PersonDeathDate
			   ELSE NULL
			   END > QuarterEndDate)
	)

AND (RefDiscountedDateStandardCHC IS NULL OR RefDiscountedDateStandardCHC > QuarterEndDate)

AND RefDiscountReasonCHC IS NULL

AND AgeRepPeriodEndYears >= 18  -- 175,173 vs 171,392 previous version

GROUP BY OrgIDComm
		,[Sub_ICB_Location_Name_Local_Reference]
		,ICB_Code
		,Integrated_Care_Board_Name
		,Region_Code
		,Region_Name
		,[Quarter]
		,LocalPatientID


--------*************************----------
----------------OUTPUT---------------------
--------*************************----------

SELECT a.OrgIDComm
	  ,a.[Sub_ICB_Location_Name_Local_Reference]
	  ,a.ICB_Code
	  ,a.Integrated_Care_Board_Name
	  ,a.Region_Code
	  ,a.Region_Name
	  ,a.[Quarter]
	  --,a.RPEndDate
	  ,COUNT(*) AS [FTSnapshot]
	  --,[Population]
	  --,(COUNT(*) / [Population]) * 50000 AS [FTSnapshot50k]
	  	  
INTO [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_Recon_Quarterly_05]

FROM #FTSnapShotSL a

--INNER JOIN #Populations b ON b.Org_Code collate SQL_Latin1_General_CP1_CI_AS = a.OrgIDComm collate SQL_Latin1_General_CP1_CI_AS AND b.Effective_Snapshot_Date = a.PopulationsDate

GROUP BY a.OrgIDComm
		,a.[Sub_ICB_Location_Name_Local_Reference]
		,a.ICB_Code
		,a.Integrated_Care_Board_Name
		,a.Region_Code
		,a.Region_Name
		,a.[Quarter]
		--,a.RPEndDate
		--,[Population]


/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CHC_PLDS_Recon_06	Number of new referrals (Standard CHC)
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

-- v1.4 Removed already eligibile section until corrected
-- v1.4 Changed to assign quarter using ReferralRequestReceivedDateCH instead of ReportingPeriod quarter (and added in WHERE clause to include only FY 22/23 onwards referrals)
-- v1.5 Added missing brackets around different types of referrals
-- v1.7 Removed [RefRequestStandardCHC] to include referrals where this has been left blank, changed discounted referrals logic
-- v1.10 Swapped AgeServReferRecDateYears >= 18 to AgeRepPeriodEndYears >= 18

---------************************--------------
---------------NEW REFERRALS-------------------
----------************************-------------

--DECLARE @firstMonthOfFiscalQ1 int = 4; --1=January

IF OBJECT_ID ('tempdb..#NewStdRefsSL') IS NOT NULL
DROP TABLE #NewStdRefsSL

SELECT a.LocalPatientID
	  ,a.ServiceRequestId
	  ,a.OrgIDComm
	  ,b.[Sub_ICB_Location_Name_Local_Reference]
	  ,b.ICB_Code
	  ,b.Integrated_Care_Board_Name
	  ,b.Region_Code
	  ,b.Region_Name
	  --,a.ReferralRequestReceivedDateCHC
	  --,a.RefRequestStandardCHC
	  --,a.RefNotificationOutcomeStandardCHC
	  --,a.RefDiscountReasonCHC
	  --,c.RPEndDate
	  , CONVERT(varchar, YEAR(ReferralRequestReceivedDateCHC) - IIF(MONTH(ReferralRequestReceivedDateCHC) < @firstMonthOfFiscalQ1, 1, 0)) 
		  + '/'
		  + RIGHT(CONVERT(varchar, (YEAR(ReferralRequestReceivedDateCHC)+1) - IIF(MONTH(ReferralRequestReceivedDateCHC) < @firstMonthOfFiscalQ1, 1, 0)),2)
		  + ' Q' 
		  + CONVERT(varchar, FLOOR(((12 + MONTH(ReferralRequestReceivedDateCHC) - @firstMonthOfFiscalQ1) % 12) / 3 ) + 1) AS [Quarter]

INTO #NewStdRefsSL

FROM [NHSE_Sandbox_CHC].[chc].[vw_reporting_101_ReferralAssessmentOutcome_Current] a

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_001_MPI_Current] mpi 

ON mpi.LocalPatientId = a.LocalPatientId AND mpi.UniqSubmissionID = a.UniqSubmissionID

LEFT JOIN [NHSE_Reference].[dbo].[vw_Ref_ODS_Commissioner_Hierarchies] b

ON b.Organisation_Code = a.OrgIDComm

WHERE 

[ActivityTypeCHC] = '01' 

AND (
--Discounted (Below makes the assumption that where referral discounted reason or date is complete, that the service request started out as a 'referral for assessment')
( [RefDiscountReasonCHC] IN ('01','02','03','04','98')  OR  [RefDiscountedDateStandardCHC] is not NULL )
OR
-- Refer for full assessment 
( RefNotificationOutcomeStandardCHC = '01' AND [RefDiscountReasonCHC] is NULL  AND [RefDiscountedDateStandardCHC] is NULL )
    )
AND AgeRepPeriodEndYears >= 18

AND a.RecordEndDate IS NULL

GROUP BY a.OrgIDComm
		,b.[Sub_ICB_Location_Name_Local_Reference]
		,a.LocalPatientID
		,a.ServiceRequestId
		,b.ICB_Code
		,b.Integrated_Care_Board_Name
		,b.Region_Code
		,b.Region_Name
	    --,a.ReferralRequestReceivedDateCHC
	    --,a.RefRequestStandardCHC
	    --,a.RefNotificationOutcomeStandardCHC
	    --,a.RefDiscountReasonCHC
	    --,c.RPEndDate
	    , CONVERT(varchar, YEAR(ReferralRequestReceivedDateCHC) - IIF(MONTH(ReferralRequestReceivedDateCHC) < @firstMonthOfFiscalQ1, 1, 0)) 
		  + '/'
		  + RIGHT(CONVERT(varchar, (YEAR(ReferralRequestReceivedDateCHC)+1) - IIF(MONTH(ReferralRequestReceivedDateCHC) < @firstMonthOfFiscalQ1, 1, 0)),2)
		  + ' Q' 
		  + CONVERT(varchar, FLOOR(((12 + MONTH(ReferralRequestReceivedDateCHC) - @firstMonthOfFiscalQ1) % 12) / 3 ) + 1) 


-----------************************************----------
------------REMOVING PATIENTS ALREADY ELIGIBLE----------
-----------************************************----------

--*Patients with mulitple service request IDs

-----REMOVE PATIENTS ALREADY ELIGIBLE (currently looks at pts eligible via std route in absence of full dataset as noted above 

--IF OBJECT_ID ('tempdb..#NewStdRefsSLMinusAlreadyEligible') IS NOT NULL
--DROP TABLE #NewStdRefsSLMinusAlreadyEligible

--SELECT	a.OrgIDComm
--		,a.[Sub_ICB_Location_Name_Local_Reference]
--		,a.ICB_Code
--		,a.Integrated_Care_Board_Name
--		,a.Region_Code
--		,a.Region_Name
--		,a.[Quarter]
--		--,a.Unique_MonthID
--		--,a.RPEndDate
--		--,DATEADD(day,1,RPEndDate) AS [PopulationsDate]
--		,COUNT(a.ServiceRequestId) AS NewRefsCount
--		,COUNT(b.LocalPatientId) AS PtAlreadyEligibleCount
--		,COUNT(a.ServiceRequestId) - COUNT(b.LocalPatientId) AS NewRef

--INTO #NewStdRefsSLMinusAlreadyEligible

--FROM #NewStdRefsSL a

--LEFT JOIN #AlreadyEligible b 

--ON b.LocalPatientId = a.LocalPatientId
--AND b.OrgIDComm = a.OrgIDComm
--AND b.[Quarter] = a.[Quarter]

--GROUP BY a.OrgIDComm
--		,a.[Sub_ICB_Location_Name_Local_Reference]
--		,a.ICB_Code
--		,a.Integrated_Care_Board_Name
--		,a.Region_Code
--		,a.Region_Name
--		,a.LocalPatientID
--		,a.[Quarter]
--		--,a.Unique_MonthID
--		--,a.RPEndDate

-----------**************************----------
---------------------OUTPUT--------------------
-----------**************************----------
SELECT OrgIDComm
	  ,[Sub_ICB_Location_Name_Local_Reference]
	  ,ICB_Code
	  ,Integrated_Care_Board_Name
	  ,Region_Code
	  ,Region_Name
	  ,[Quarter]
	  --,RPEndDate
	  ,COUNT(*) AS [NewRefs]
	  --,[Population]
	 -- ,(COUNT(*) / CAST(SUM(b.[Population]) as float)) * 50000 AS [NewStdRefs50k]

INTO [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_Recon_Quarterly_06]

FROM #NewStdRefsSL a

WHERE CAST(LEFT(a.[Quarter],4) AS int) > 2021  -- excludes historic referrals 

--INNER JOIN #Populations b ON b.Org_Code collate SQL_Latin1_General_CP1_CI_AS = a.OrgIDComm collate SQL_Latin1_General_CP1_CI_AS AND b.Effective_Snapshot_Date = a.PopulationsDate

GROUP BY OrgIDComm
		,[Sub_ICB_Location_Name_Local_Reference]
		,ICB_Code
		,Integrated_Care_Board_Name
		,Region_Code
		,Region_Name
		,[Quarter]
		--,Unique_MonthID
		--,RPEndDate
		--,[Population]


/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CHC_PLDS_Recon_07	Number of new referrals (Fast-Track CHC)
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

-- v1.4 Changed to assign quarter using ReferralRequestReceivedDateCH instead of ReportingPeriod quarter (and added in WHERE clause to include only FY 22/23 onwards referrals)
-- v1.10 Swapped AgeServReferRecDateYears >= 18 to AgeRepPeriodEndYears >= 18

----------*************************----------
------------SERVICE LEVEL FT REFS------------
----------*************************----------

--DECLARE @firstMonthOfFiscalQ1 int = 4; --1=January

IF OBJECT_ID ('tempdb..#NewFTRefsSL') IS NOT NULL
DROP TABLE #NewFTRefsSL

SELECT a.LocalPatientID
	  ,a.ServiceRequestId
	  ,a.OrgIDComm
	  ,b.[Sub_ICB_Location_Name_Local_Reference]
	  ,b.ICB_Code
	  ,b.Integrated_Care_Board_Name
	  ,b.Region_Code
	  ,b.Region_Name
	  --,a.ReferralRequestReceivedDateCHC
	  --,a.ActivityTypeCHC
	  --,c.RPEndDate	 
	  ,CONVERT(varchar, YEAR(ReferralRequestReceivedDateCHC) - IIF(MONTH(ReferralRequestReceivedDateCHC) < @firstMonthOfFiscalQ1, 1, 0)) 
		  + '/'
		  + RIGHT(CONVERT(varchar, (YEAR(ReferralRequestReceivedDateCHC)+1) - IIF(MONTH(ReferralRequestReceivedDateCHC) < @firstMonthOfFiscalQ1, 1, 0)),2)
		  + ' Q' 
		  + CONVERT(varchar, FLOOR(((12 + MONTH(ReferralRequestReceivedDateCHC) - @firstMonthOfFiscalQ1) % 12) / 3 ) + 1) AS [Quarter]

INTO #NewFTRefsSL

FROM [NHSE_Sandbox_CHC].[chc].[vw_reporting_101_ReferralAssessmentOutcome_Current] a

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_001_MPI_Current] mpi 

ON mpi.LocalPatientId = a.LocalPatientId AND mpi.UniqSubmissionID = a.UniqSubmissionID

LEFT JOIN [NHSE_Reference].[dbo].[vw_Ref_ODS_Commissioner_Hierarchies] b

ON b.Organisation_Code = a.OrgIDComm

WHERE ActivityTypeCHC = '02' 

AND AgeRepPeriodEndYears >= 18

AND a.RecordEndDate IS NULL

GROUP BY a.OrgIDComm
		,b.[Sub_ICB_Location_Name_Local_Reference]
		,b.ICB_Code
		,b.Integrated_Care_Board_Name
		,b.Region_Code
		,b.Region_Name
		,CONVERT(varchar, YEAR(ReferralRequestReceivedDateCHC) - IIF(MONTH(ReferralRequestReceivedDateCHC) < @firstMonthOfFiscalQ1, 1, 0)) 
		  + '/'
		  + RIGHT(CONVERT(varchar, (YEAR(ReferralRequestReceivedDateCHC)+1) - IIF(MONTH(ReferralRequestReceivedDateCHC) < @firstMonthOfFiscalQ1, 1, 0)),2)
		  + ' Q' 
		  + CONVERT(varchar, FLOOR(((12 + MONTH(ReferralRequestReceivedDateCHC) - @firstMonthOfFiscalQ1) % 12) / 3 ) + 1)
		,a.LocalPatientID
		,a.ServiceRequestId
		--,a.ReferralRequestReceivedDateCHC
	    --,a.ActivityTypeCHC
		--,c.RPEndDate


----------*************************----------
------------------OUTPUT---------------------
----------*************************----------

SELECT a.OrgIDComm
	  ,a.[Sub_ICB_Location_Name_Local_Reference]
	  ,a.ICB_Code
	  ,a.Integrated_Care_Board_Name
	  ,a.Region_Code
	  ,a.Region_Name
	  ,a.[Quarter]
	  --,a.RPEndDate
	  ,COUNT(*) AS [NewFTRefs]
	  --,b.[Population]
	  --,(COUNT(*) / CAST(SUM(b.[Population]) as float)) * 50000 AS [NewFTRefs50k]
	  	  
INTO [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_Recon_Quarterly_07]

FROM #NewFTRefsSL a

WHERE CAST(LEFT(a.[Quarter],4) AS int) > 2021  -- excludes historic referrals 

--INNER JOIN #Populations b ON b.Org_Code collate SQL_Latin1_General_CP1_CI_AS = a.OrgIDComm collate SQL_Latin1_General_CP1_CI_AS AND b.Effective_Snapshot_Date = a.PopulationsDate

GROUP BY a.OrgIDComm
		,a.[Sub_ICB_Location_Name_Local_Reference]
		,a.ICB_Code
		,a.Integrated_Care_Board_Name
		,a.Region_Code
		,a.Region_Name
		,a.[Quarter]
		--,a.RPEndDate
		--,[Population]   



/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CHC_PLDS_Recon_08	Number eligible at the end of the quarter (snapshot) - Funded Nursing Care i.e. FNC
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

-- v1.7 created Dec 23
-- v1.10 Swapped AgeServReferRecDateYears >= 18 to AgeRepPeriodEndYears >= 18
-- v1.11 Logic was previously including any patient that was eligible during the quarter so have corrected it to include only those eligible at the end of the quarter

----------*************************----------
-----------SERVICE LEVEL FNC SNAP-----------
----------*************************----------

IF OBJECT_ID ('tempdb..#FNCSnapShotSL') IS NOT NULL
DROP TABLE #FNCSnapShotSL

SELECT   OrgIDComm
		,[Sub_ICB_Location_Name_Local_Reference]
		,ICB_Code
		,Integrated_Care_Board_Name
		,Region_Code
		,Region_Name
		,[Quarter]
		,LocalPatientID
	  
INTO #FNCSnapShotSL

FROM (
		SELECT ROW_NUMBER() OVER(PARTITION BY a.OrgIDComm, a.LocalPatientID, a.ServiceRequestId, d.[Quarter] ORDER BY c.RPEndDate DESC) RN
			  ,a.LocalPatientID
			  ,a.ServiceRequestId
			  ,a.OrgIDComm
			  ,b.[Sub_ICB_Location_Name_Local_Reference]
			  ,b.ICB_Code
			  ,b.Integrated_Care_Board_Name
			  ,b.Region_Code
			  ,b.Region_Name
			  ,a.ActivityTypeCHC
			  ,CASE WHEN EndDateFunding IS NOT NULL THEN EndDateFunding
					WHEN EndDateFunding IS NULL AND PersonDeathDate IS NOT NULL THEN PersonDeathDate
					ELSE NULL
					END AS [EndDate]
			  ,mpi.PersonDeathDate
			  ,a.EndDateFunding
			  ,a.CommEligibilityDecisionDateStandardCHC
			  ,a.CommEligibilityDecisionOutcomeStandardCHC
			  ,a.CommReviewOutcome
			  ,a.RefNotificationOutcomeStandardCHC
			  ,a.RefDiscountReasonCHC
			  ,a.RefDiscountedDateStandardCHC
			  ,a.DateEligibilityBeginsLocalResolution
			  ,a.EndDateLocalResolution
			  ,mpi.AgeRepPeriodEndYears
			  ,d.[Quarter]
			  ,d.QuarterStartDate
			  ,d.QuarterEndDate
			  ,c.RPEndDate
			  --,DATEADD(day,1,c.RPEndDate) AS [PopulationsDate]

FROM [NHSE_Sandbox_CHC].[chc].[vw_reporting_101_ReferralAssessmentOutcome_Current] a

LEFT JOIN [NHSE_Reference].[dbo].[vw_Ref_ODS_Commissioner_Hierarchies] b

ON b.Organisation_Code = a.OrgIDComm

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_001_MPI_Current] mpi 

ON mpi.LocalPatientId = a.LocalPatientId AND mpi.UniqSubmissionID = a.UniqSubmissionID

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_000_Header_Current] c

ON c.UniqSubmissionID = a.UniqSubmissionID

LEFT JOIN [NHSE_Sandbox_CHC].[dbo].[tbl_Period_Lookup_PLDS_temp] d

ON d.[RPEndDate] = c.RPEndDate

) r

WHERE RN = 1

AND

(
--Eligible via FNC assessment route 
(
ActivityTypeCHC = '01' 
AND CommEligibilityDecisionDateStandardCHC <= QuarterEndDate
AND CommEligibilityDecisionOutcomeStandardCHC = '02'
AND (	 (CASE WHEN EndDateFunding IS NOT NULL THEN EndDateFunding
			   WHEN EndDateFunding IS NULL AND PersonDeathDate IS NOT NULL THEN PersonDeathDate
			   ELSE NULL 
			   END IS NULL)
      OR (CASE WHEN EndDateFunding IS NOT NULL THEN EndDateFunding
			   WHEN EndDateFunding IS NULL AND PersonDeathDate IS NOT NULL THEN PersonDeathDate
			   ELSE NULL
			   END > QuarterEndDate)
	)
--30.01.23 Last condition added to exclude cases which are found eligible but application is withdrawn by family before funding starts
AND RefDiscountReasonCHC IS NULL
AND (RefDiscountedDateStandardCHC IS NULL OR RefDiscountedDateStandardCHC > QuarterEndDate)
)

OR 

--Eligible via FNC referral route  
(
ActivityTypeCHC = '01' 
AND RefNotificationOutcomeStandardCHC = '02'
AND (	 (CASE WHEN EndDateFunding IS NOT NULL THEN EndDateFunding
			   WHEN EndDateFunding IS NULL AND PersonDeathDate IS NOT NULL THEN PersonDeathDate
			   ELSE NULL 
			   END IS NULL)
      OR (CASE WHEN EndDateFunding IS NOT NULL THEN EndDateFunding
			   WHEN EndDateFunding IS NULL AND PersonDeathDate IS NOT NULL THEN PersonDeathDate
			   ELSE NULL
			   END > QuarterEndDate)
	)
AND RefDiscountReasonCHC IS NULL
AND (RefDiscountedDateStandardCHC IS NULL OR RefDiscountedDateStandardCHC > QuarterEndDate)
)

OR
--Eligible via LR     
(
ActivityTypeCHC = '04' 
AND CommEligibilityDecisionDateStandardCHC <= QuarterEndDate
AND (CommEligibilityDecisionOutcomeStandardCHC = '02' OR CommReviewOutcome = '03')
AND (   (EndDateLocalResolution IS NULL 
		 AND CASE WHEN EndDateFunding IS NOT NULL THEN EndDateFunding
				  WHEN EndDateFunding IS NULL AND PersonDeathDate IS NOT NULL THEN PersonDeathDate
				  ELSE NULL 
				  END  IS NULL
		)
	 OR (EndDateLocalResolution IS NULL 
		 AND CASE WHEN EndDateFunding IS NOT NULL THEN EndDateFunding
				  WHEN EndDateFunding IS NULL AND PersonDeathDate IS NOT NULL THEN PersonDeathDate
				  ELSE NULL 
				  END > QuarterEndDate
		) 
	 OR (EndDateLocalResolution > QuarterEndDate 
		 AND CASE WHEN EndDateFunding IS NOT NULL THEN EndDateFunding
				  WHEN EndDateFunding IS NULL AND PersonDeathDate IS NOT NULL THEN PersonDeathDate
				  ELSE NULL 
				  END  IS NULL
		) 
	 OR (CASE WHEN EndDateFunding IS NOT NULL THEN EndDateFunding
				  WHEN EndDateFunding IS NULL AND PersonDeathDate IS NOT NULL THEN PersonDeathDate
				  ELSE NULL 
				  END = EndDateLocalResolution 
		 AND EndDateLocalResolution > QuarterEndDate
		)
    )
)
)
AND AgeRepPeriodEndYears >= 18  -- 415,338 vs 444,279 old version

GROUP BY OrgIDComm
		,[Sub_ICB_Location_Name_Local_Reference]
		,ICB_Code
		,Integrated_Care_Board_Name
		,Region_Code
		,Region_Name
		,[Quarter]
		,LocalPatientID



--IF OBJECT_ID ('tempdb..#snapshotMinusAlreadyEligible') IS NOT NULL
--DROP TABLE #snapshotMinusAlreadyEligible

--SELECT	a.LocalPatientID
--		,a.OrgIDComm
--		,a.[Sub_ICB_Location_Name_Local_Reference]
--		,a.ICB_Code
--		,a.Integrated_Care_Board_Name
--		,a.Region_Code
--		,a.Region_Name
--		,a.[Quarter]
--		--,a.RPEndDate
--		--,DATEADD(day,1,RPEndDate) AS [PopulationsDate]
--		,COUNT(a.ServiceRequestId) AS NewRefsCount
--		,COUNT(b.LocalPatientId) AS PtAlreadyEligibleCount
--		,COUNT(a.ServiceRequestId) - COUNT(b.LocalPatientId) AS NewRef

--INTO #snapshotMinusAlreadyEligible

--FROM #StdSnapShotSL a

--LEFT JOIN #AlreadyEligible b 

--ON b.LocalPatientId = a.LocalPatientId
--AND b.OrgIDComm = a.OrgIDComm
--AND b.[Quarter] = a.[Quarter]

--GROUP BY a.OrgIDComm
--		,a.[Sub_ICB_Location_Name_Local_Reference]
--		,a.ICB_Code
--		,a.Integrated_Care_Board_Name
--		,a.Region_Code
--		,a.Region_Name
--		,a.LocalPatientID
--		,a.[Quarter]
--		--,a.Unique_MonthID
--		--,a.RPEndDate


----------*************************----------
------------------OUTPUT---------------------
----------*************************----------

SELECT a.OrgIDComm
	  ,a.[Sub_ICB_Location_Name_Local_Reference]
	  ,a.ICB_Code
	  ,a.Integrated_Care_Board_Name
	  ,a.Region_Code
	  ,a.Region_Name
	  ,a.[Quarter]
	  --,a.RPEndDate
	  ,COUNT(*) AS [FNCSnapshot]
	  --,b.[Population]
	  --,(COUNT(*) / CAST(SUM(b.[Population]) as float)) * 50000 AS [FNCSnapshot50k]
	  	  
INTO [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_Recon_Quarterly_08]

FROM #FNCSnapShotSL a

--INNER JOIN #Populations b ON b.Org_Code collate SQL_Latin1_General_CP1_CI_AS = a.OrgIDComm collate SQL_Latin1_General_CP1_CI_AS AND b.Effective_Snapshot_Date = a.PopulationsDate

GROUP BY a.OrgIDComm
		,a.[Sub_ICB_Location_Name_Local_Reference]
		,a.ICB_Code
		,a.Integrated_Care_Board_Name
		,a.Region_Code
		,a.Region_Name
		,a.[Quarter]
		--,a.RPEndDate
		--,[Population]



/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CHC_PLDS_Recon_9 (METRICS 9-14 in one table) Number of incomplete referrals exceeding 28 days by time buckets
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

-- V1.7 created Dec 23 
-- v1.9 Excluded historical referrals (prior to FY 22/23)
-- v1.10 Swapped AgeServReferRecDateYears >= 18 to AgeRepPeriodEndYears >= 18
-- v1.11 Added Sub Query with partition to select the most record of each referral (service request) per Quarter

----------************************************----------
----------GET REFERRALS EXCEEDING 28 DAYS DATA----------
----------************************************----------

IF OBJECT_ID ('tempdb..#RefsExc28') IS NOT NULL
DROP TABLE #RefsExc28

SELECT LocalPatientId   
	  ,ServiceRequestId 
	  ,OrgIDComm
	  ,[Sub_ICB_Location_Name_Local_Reference]
	  ,ICB_Code
	  ,Integrated_Care_Board_Name
	  ,Region_Code
	  ,Region_Name
	  ,[Quarter]
	  --,ReferralRequestReceivedDateCHC
	  --,RefDiscountedDateStandardCHC
	  --,CommEligibilityDecisionDateStandardCHC
	  , CASE WHEN DATEDIFF(DAY,[ReferralRequestReceivedDateCHC],CAST(QuarterEndDate AS DATE)) BETWEEN 29 AND 42 THEN 1 
	    ELSE 0
		END AS [Exc28Days_UpTo2Wks]
	  , CASE WHEN DATEDIFF(DAY,[ReferralRequestReceivedDateCHC],CAST(QuarterEndDate AS DATE)) BETWEEN 43 AND 56 THEN 1
	    ELSE 0
		END AS [Exc28Days_2-4Wks]
	  , CASE WHEN DATEDIFF(DAY,[ReferralRequestReceivedDateCHC],CAST(QuarterEndDate AS DATE)) BETWEEN 57 AND 112 THEN 1
	    ELSE 0
		END AS [Exc28Days_4-12Wks]
	  , CASE WHEN DATEDIFF(DAY,[ReferralRequestReceivedDateCHC],CAST(QuarterEndDate AS DATE)) BETWEEN 113 AND 210 THEN 1
	    ELSE 0
		END AS [Exc28Days_12-26Wks]
	  , CASE WHEN DATEDIFF(DAY,[ReferralRequestReceivedDateCHC],CAST(QuarterEndDate AS DATE)) > 210 THEN 1
	    ELSE 0
		END AS [Exc28Days_Over26Wks]
	  , CASE WHEN DATEDIFF(DAY,[ReferralRequestReceivedDateCHC],CAST(QuarterEndDate AS DATE)) > 28 THEN 1
	    ELSE 0
		END AS [Exc28Days_Total]

INTO #RefsExc28

FROM (
		SELECT ROW_NUMBER() OVER(PARTITION BY a.OrgIDComm, a.LocalPatientID, a.ServiceRequestId, d.[Quarter] ORDER BY c.RPEndDate DESC) RN  
			  ,a.ServiceRequestId  
			  ,a.LocalPatientId   
			  ,a.OrgIDComm
			  ,b.[Sub_ICB_Location_Name_Local_Reference]
			  ,b.ICB_Code
			  ,b.Integrated_Care_Board_Name
			  ,b.Region_Code
			  ,b.Region_Name
			  ,d.[Quarter]
			  --,c.RPEndDate
			  ,a.ActivityTypeCHC
			  ,a.ReferralRequestReceivedDateCHC
			  ,a.RefNotificationOutcomeStandardCHC
			  ,a.RefDiscountedDateStandardCHC
			  ,a.CommEligibilityDecisionDateStandardCHC
			  ,mpi.AgeRepPeriodEndYears
			  ,d.QuarterEndDate
--			  ,c.RPEndDate

FROM [NHSE_Sandbox_CHC].[chc].[vw_reporting_101_ReferralAssessmentOutcome_Current] a

LEFT JOIN [NHSE_Reference].[dbo].[vw_Ref_ODS_Commissioner_Hierarchies] b

ON b.Organisation_Code = a.OrgIDComm

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_001_MPI_Current] mpi 

ON mpi.LocalPatientId = a.LocalPatientId AND mpi.UniqSubmissionID = a.UniqSubmissionID

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_000_Header_Current] c

ON c.UniqSubmissionID = a.UniqSubmissionID

LEFT JOIN [NHSE_Sandbox_CHC].[dbo].[tbl_Period_Lookup_PLDS_temp] d

ON d.[RPEndDate] = c.RPEndDate

) r

WHERE RN = 1

AND ActivityTypeCHC = '01' 

AND ReferralRequestReceivedDateCHC < CAST(QuarterEndDate AS DATE)

AND RefNotificationOutcomeStandardCHC = '01'	

AND (CommEligibilityDecisionDateStandardCHC IS NULL OR CommEligibilityDecisionDateStandardCHC > CAST(QuarterEndDate AS date))

AND (RefDiscountedDateStandardCHC IS NULL OR RefDiscountedDateStandardCHC > CAST(QuarterEndDate AS date))

--AND [RefDiscountReasonCHC] is NULL

--30.01.23 added condition to exclude transition cases
AND AgeRepPeriodEndYears >= 18

-- FY 22/23 onwards only i.e. exclude historic referrals 
AND ReferralRequestReceivedDateCHC > '2022-03-31'

AND DATEDIFF(DAY,[ReferralRequestReceivedDateCHC],CAST(QuarterEndDate AS DATE)) > 28

GROUP BY  LocalPatientId   
		 ,ServiceRequestId 
		 ,OrgIDComm
		 ,[Sub_ICB_Location_Name_Local_Reference]
		 ,ICB_Code
		 ,Integrated_Care_Board_Name
		 ,Region_Code
		 ,Region_Name
		 ,[Quarter]
		 --,ReferralRequestReceivedDateCHC
		 --,RefDiscountedDateStandardCHC
		 --,CommEligibilityDecisionDateStandardCHC
    	  , CASE WHEN DATEDIFF(DAY,[ReferralRequestReceivedDateCHC],CAST(QuarterEndDate AS DATE)) BETWEEN 29 AND 42 THEN 1 
    	    ELSE 0
    		END 
    	  , CASE WHEN DATEDIFF(DAY,[ReferralRequestReceivedDateCHC],CAST(QuarterEndDate AS DATE)) BETWEEN 43 AND 56 THEN 1
    	    ELSE 0
    		END 
    	  , CASE WHEN DATEDIFF(DAY,[ReferralRequestReceivedDateCHC],CAST(QuarterEndDate AS DATE)) BETWEEN 57 AND 112 THEN 1
    	    ELSE 0
    		END 
    	  , CASE WHEN DATEDIFF(DAY,[ReferralRequestReceivedDateCHC],CAST(QuarterEndDate AS DATE)) BETWEEN 113 AND 210 THEN 1
    	    ELSE 0
    		END 
    	  , CASE WHEN DATEDIFF(DAY,[ReferralRequestReceivedDateCHC],CAST(QuarterEndDate AS DATE)) > 210 THEN 1
    	    ELSE 0
    		END 
    	  , CASE WHEN DATEDIFF(DAY,[ReferralRequestReceivedDateCHC],CAST(QuarterEndDate AS DATE)) > 28 THEN 1
    	    ELSE 0
    		END 
		 
-- 62,864 vs 60,922 v10

----------********************************************----------
-------------REFS OUTSTANDING BY TIME BUCKETS OUTPUT-----------
----------********************************************----------

SELECT OrgIDComm
	  ,[Sub_ICB_Location_Name_Local_Reference]
	  ,ICB_Code
	  ,Integrated_Care_Board_Name
	  ,Region_Code
	  ,Region_Name
	  --,Unique_MonthID
	  --,RPEndDate
	  ,[Quarter]
	  ,SUM([Exc28Days_UpTo2Wks]) AS [Exc28Days_UpTo2Wks]    -- Metric 9
	  ,SUM([Exc28Days_2-4Wks]) AS [Exc28Days_2-4Wks]        -- Metric 10
	  ,SUM([Exc28Days_4-12Wks]) AS [Exc28Days_4-12Wks]      -- Metric 11
	  ,SUM([Exc28Days_12-26Wks]) AS [Exc28Days_12-26Wks]    -- Metric 12
	  ,SUM([Exc28Days_Over26Wks]) AS [Exc28Days_Over26Wks]  -- Metric 13
	  ,SUM([Exc28Days_Total]) AS [Exc28Days_Total]          -- Metric 14

INTO [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_Recon_Quarterly_09]

FROM #RefsExc28

GROUP BY OrgIDComm
		,[Sub_ICB_Location_Name_Local_Reference]
		,ICB_Code
		,Integrated_Care_Board_Name
		,Region_Code
		,Region_Name
		,[Quarter]
		--,Unique_MonthID
		--,RPEndDate


/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CHC_PLDS_Recon_15   
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/





		
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
DELETE ALL TEMP TABLES
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/


DROP TABLE #Refsin28daysSL
DROP TABLE #AllRefsComp
DROP TABLE #StdSnapShotSL
DROP TABLE #FTSnapShotSL
DROP TABLE #NewStdRefsSL
--DROP TABLE #MultipleServiceIDs
--DROP TABLE #AlreadyEligible
--DROP TABLE #NewStdRefsSLMinusAlreadyEligible
DROP TABLE #NewFTRefsSL
DROP TABLE #DSTdataSL
DROP TABLE #Over12WeeksSL
--DROP TABLE #snapshotMinusAlreadyEligible
DROP TABLE #FNCSnapShotSL
DROP TABLE #RefsExc28
