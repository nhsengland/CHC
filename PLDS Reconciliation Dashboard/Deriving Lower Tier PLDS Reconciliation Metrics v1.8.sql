PRINT
'NHS CHC PLDS RECONCILIATION METRICS

LOWER TIER GEOGRAPHIES

CREATED BY LUCY SEVILLE 26/4/23
UPDATED BY REBECCA WATSON OCTOBER 2023'

-------Run time 00:00:45

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
DROP PREV TABLES
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

USE [NHSE_Sandbox_CHC]
IF OBJECT_ID (N'dbo.tbl_CHC_PLDS_LT_Recon_Quarterly_01') IS NOT NULL
DROP TABLE [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_LT_Recon_Quarterly_01]
IF OBJECT_ID (N'dbo.tbl_CHC_PLDS_LT_Recon_Quarterly_02') IS NOT NULL
DROP TABLE [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_LT_Recon_Quarterly_02]
IF OBJECT_ID (N'dbo.tbl_CHC_PLDS_LT_Recon_Quarterly_03') IS NOT NULL
DROP TABLE [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_LT_Recon_Quarterly_03]
IF OBJECT_ID (N'dbo.tbl_CHC_PLDS_LT_Recon_Quarterly_04') IS NOT NULL
DROP TABLE [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_LT_Recon_Quarterly_04]
IF OBJECT_ID (N'dbo.tbl_CHC_PLDS_LT_Recon_Quarterly_05') IS NOT NULL
DROP TABLE [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_LT_Recon_Quarterly_05]
IF OBJECT_ID (N'dbo.tbl_CHC_PLDS_LT_Recon_Quarterly_06') IS NOT NULL
DROP TABLE [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_LT_Recon_Quarterly_06]
IF OBJECT_ID (N'dbo.tbl_CHC_PLDS_LT_Recon_Quarterly_07') IS NOT NULL
DROP TABLE [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_LT_Recon_Quarterly_07]
IF OBJECT_ID (N'dbo.tbl_CHC_PLDS_LT_Recon_Quarterly_08') IS NOT NULL
DROP TABLE [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_LT_Recon_Quarterly_08]
IF OBJECT_ID (N'dbo.tbl_CHC_PLDS_LT_Recon_Quarterly_09') IS NOT NULL
DROP TABLE [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_LT_Recon_Quarterly_09]


/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
COHORT OF PATIENTS ALREADY ELIGILBE (TO USE IN METRICS 4 AND 6)
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

-------**********************************************----
--------Patients with multiple service request IDs------
------**********************************************----

--IF OBJECT_ID ('tempdb..#MultipleServiceIDs') IS NOT NULL
--DROP TABLE #MultipleServiceIDs

--SELECT	a.OrgIDComm
--		,a.Sub_OrgID_Comm
--		,a.LocalPatientID
--		,c.[Quarter]
--		,c.QuarterEndDate
--		,COUNT(ServiceRequestId) AS ServiceRequestsCount

--INTO #MultipleServiceIDs

--FROM [NHSE_Sandbox_CHC].[chc].[vw_reporting_101_ReferralAssessmentOutcome_Current] a

--LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_000_Header_Current] b

--ON b.UniqSubmissionID = a.UniqSubmissionID

--LEFT JOIN [NHSE_Sandbox_CHC].[dbo].[tbl_Period_Lookup_PLDS_temp] c

--ON c.[RPEndDate] = b.RPEndDate

--WHERE a.RecordEndDate IS NULL

--GROUP BY	LocalPatientID
--			,a.OrgIDComm
--			,a.Sub_OrgID_Comm
--			,c.[Quarter]
--			,c.QuarterEndDate

--HAVING COUNT(ServiceRequestId) > 1

-------*********************************************************----
--------Patients with multiple service request IDs AND eligible-----
------**********************************************************----
--IF OBJECT_ID ('tempdb..#AlreadyEligible') IS NOT NULL
--DROP TABLE #AlreadyEligible

--SELECT	a.OrgIDComm
--		,a.Sub_OrgID_Comm
--		,a.LocalPatientId
--		,b.ServiceRequestId
--		,d.QuarterEndDate
--		,d.[Quarter]

--INTO #AlreadyEligible

--FROM #MultipleServiceIDs a

--LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_101_ReferralAssessmentOutcome_Current] b 

--ON b.LocalPatientId = a.LocalPatientID AND b.Sub_OrgID_Comm = a.Sub_OrgID_Comm

--LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_000_Header_Current] c

--ON c.UniqSubmissionID = b.UniqSubmissionID

--LEFT JOIN [NHSE_Sandbox_CHC].[dbo].[tbl_Period_Lookup_PLDS_temp] d

--ON d.[RPEndDate] = c.RPEndDate

--WHERE 
----Eligible via Std route
--([ActivityTypeCHC] = '01'
--AND [CommEligibilityDecisionDateStandardCHC] < d.QuarterStartDate
--AND [CommEligibilityDecisionOutcomeStandardCHC] = '01'
--AND ([EndDateFunding] IS NULL OR [EndDateFunding] > d.QuarterEndDate))

--OR
----Eligible via LR
--([ActivityTypeCHC] = '04'
--AND [CommEligibilityDecisionDateStandardCHC] < d.QuarterStartDate
--AND ([CommEligibilityDecisionOutcomeStandardCHC] = '01' OR [CommReviewOutcome] = '01')
--AND ([EndDateFunding] IS NULL OR [EndDateFunding] > d.QuarterEndDate))

--OR
----Eligible via IR
--(DateEligibilityBeginsLocalResolution < d.QuarterStartDate
--AND ([EndDateFunding] IS NULL OR [EndDateFunding] > d.QuarterEndDate))

--AND b.RecordEndDate IS NULL

--GROUP BY a.OrgIDComm
--		,a.Sub_OrgID_Comm
--		,a.LocalPatientID
--		,b.ServiceRequestId
--		,d.QuarterEndDate
--		,d.[Quarter]

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CHC_PLDS_Recon_01	Percentage of standard CHC referrals completed within 28 days
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

----------*************************----------
------------REFERRALS IN 28 DAYS-------------
----------*************************----------

DECLARE @firstMonthOfFiscalQ1 int = 4; -- sets April (month 4) as start of Fiscal Q1

IF OBJECT_ID ('tempdb..#Refsin28daysSL') IS NOT NULL
DROP TABLE #Refsin28daysSL

SELECT a.LocalPatientID
	  ,a.ServiceRequestId
	  ,a.OrgIDComm
	  ,a.Sub_OrgID_Comm
	  ,b.[Sub_ICB_Name]
	  ,b.Lower_Tier_Name
      ,b.[ICB_Code]
      ,b.[ICB_Name]
      ,b.[Region_Code]
      ,b.[Region_Name]
--	  ,ReferralRequestReceivedDateCHC
--	  ,RefDiscountedDateStandardCHC   AS DecisionorDiscountedDate
	  , CONVERT(varchar, YEAR(RefDiscountedDateStandardCHC) - IIF(MONTH(RefDiscountedDateStandardCHC) < @firstMonthOfFiscalQ1, 1, 0)) 
		  + '/'
		  + RIGHT(CONVERT(varchar, (YEAR(RefDiscountedDateStandardCHC)+1) - IIF(MONTH(RefDiscountedDateStandardCHC) < @firstMonthOfFiscalQ1, 1, 0)),2)
		  + ' Q' 
		  + CONVERT(varchar, FLOOR(((12 + MONTH(RefDiscountedDateStandardCHC) - @firstMonthOfFiscalQ1) % 12) / 3 ) + 1) AS [Quarter]

INTO #Refsin28daysSL

FROM [NHSE_Sandbox_CHC].[chc].[vw_reporting_101_ReferralAssessmentOutcome_Current] a

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_001_MPI_Current] mpi 

ON mpi.LocalPatientId = a.LocalPatientId AND mpi.UniqSubmissionID = a.UniqSubmissionID

INNER JOIN [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_Sub_ICB_Lookup_Table] b

ON b.[Sub_ICB_Code] = a.OrgIDComm and b.[Lower_Tier_Code] = a.Sub_OrgID_Comm

WHERE

--Discounted (Below makes the assumption that where referral discounted date is complete, that the service request started out as a 'referral for assessment')

[ActivityTypeCHC] = '01' 

AND DATEDIFF(DAY,[ReferralRequestReceivedDateCHC],[RefDiscountedDateStandardCHC]) < 29

AND a.RecordEndDate is NULL 

--30.01.23 added condition to exclude transition cases
AND AgeRepPeriodEndYears >= 18

AND [RefDiscountedDateStandardCHC] > '2022-03-31'  -- FY 22/23 onwards only

AND a.OrgIDComm IN ('72Q', '91Q', 'D9Y0V', '36L', 'D4U1Y', 'B2M3M')

AND   a.Sub_OrgID_Comm IN  (
                              '07V',    '08J',    '08P',    '08R',    '08T',    '08X',    -- 36L
                              '07N',    '07Q',    '08A',    '08K',    '08L',    '08Q',    -- 72Q
                              '09C',    '09E',    '09J',    '10A',    '10E',    '99J',  '09J 09W 10D',  -- 91Q
                              --'09F',    '09P',    '99K',    -- 97R
                              '07L',    '07T',    '08F',    '08M',    '08N',    '08V',    '08W',    -- A3A8R
                              --'05L',    '05C',    '05Y',    '06A',    -- D2P2L
                              '15D',    '99M',    '10C',  -- D4U1Y
                              '10L',    '10X',  '10K',    -- D9Y0V
                              --'07P',    '07W',    '09A',  -- W2U3Z
                              --'99Q',  '99P', -- 15N 
                              --'12D',  '99N',  '11E',  -- 92G 
							  '05H',  '5MD',  '5M9', '05R') -- B2M3M 

UNION

-- Refer for full assessment

SELECT a.LocalPatientID
	  ,a.ServiceRequestId
	  ,a.OrgIDComm
	  ,a.Sub_OrgID_Comm
	  ,b.[Sub_ICB_Name]
	  ,b.Lower_Tier_Name
      ,b.[ICB_Code]
      ,b.[ICB_Name]
      ,b.[Region_Code]
      ,b.[Region_Name]
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

INNER JOIN [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_Sub_ICB_Lookup_Table] b

ON b.[Sub_ICB_Code] = a.OrgIDComm and b.[Lower_Tier_Code] = a.Sub_OrgID_Comm

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

AND a.OrgIDComm IN ('72Q', '91Q', 'D9Y0V', '36L', 'D4U1Y', 'B2M3M')

AND   a.Sub_OrgID_Comm IN  (
                             '07V',    '08J',    '08P',    '08R',    '08T',    '08X',    -- 36L
                             '07N',    '07Q',    '08A',    '08K',    '08L',    '08Q',    -- 72Q
                             '09C',    '09E',    '09J',    '10A',    '10E',    '99J',  '09J 09W 10D',  -- 91Q
                             --'09F',    '09P',    '99K',    -- 97R
                             '07L',    '07T',    '08F',    '08M',    '08N',    '08V',    '08W',    -- A3A8R
                             --'05L',    '05C',    '05Y',    '06A',    -- D2P2L
                             '15D',    '99M',    '10C',  -- D4U1Y
                             '10L',    '10X',  '10K',    -- D9Y0V
                             --'07P',    '07W',    '09A',  -- W2U3Z
                             --'99Q',  '99P', -- 15N 
                             --'12D',  '99N',  '11E',  -- 92G 
							 '05H',  '5MD',  '5M9', '05R') -- B2M3M 


----------*************************----------
---------------ALL REFERRALS-----------------
----------*************************----------

IF OBJECT_ID ('tempdb..#AllRefsComp') IS NOT NULL
DROP TABLE #AllRefsComp

-- DECLARE @firstMonthOfFiscalQ1 int = 4

SELECT a.LocalPatientID
	  ,a.ServiceRequestId
	  ,a.OrgIDComm
	  ,a.Sub_OrgID_Comm
	  ,b.[Sub_ICB_Name]
	  ,b.Lower_Tier_Name
      ,b.[ICB_Code]
      ,b.[ICB_Name]
      ,b.[Region_Code]
      ,b.[Region_Name]
--	  ,ReferralRequestReceivedDateCHC
--	  ,RefDiscountedDateStandardCHC   AS DecisionorDiscountedDate
	  , CONVERT(varchar, YEAR(RefDiscountedDateStandardCHC) - IIF(MONTH(RefDiscountedDateStandardCHC) < @firstMonthOfFiscalQ1, 1, 0)) 
		  + '/'
		  + RIGHT(CONVERT(varchar, (YEAR(RefDiscountedDateStandardCHC)+1) - IIF(MONTH(RefDiscountedDateStandardCHC) < @firstMonthOfFiscalQ1, 1, 0)),2)
		  + ' Q' 
		  + CONVERT(varchar, FLOOR(((12 + MONTH(RefDiscountedDateStandardCHC) - @firstMonthOfFiscalQ1) % 12) / 3 ) + 1) AS [Quarter]

INTO #AllRefsComp

FROM [NHSE_Sandbox_CHC].[chc].[vw_reporting_101_ReferralAssessmentOutcome_Current] a

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_001_MPI_Current] mpi 

ON mpi.LocalPatientId = a.LocalPatientId AND mpi.UniqSubmissionID = a.UniqSubmissionID

INNER JOIN [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_Sub_ICB_Lookup_Table] B

ON b.[Sub_ICB_Code] = a.OrgIDComm and b.[Lower_Tier_Code] = a.Sub_OrgID_Comm

WHERE

--Discounted (Below makes the assumption that where referral discounted date is complete, that the service request started out as a 'referral for assessment')

[ActivityTypeCHC] = '01' 

AND a.RecordEndDate is NULL 

--30.01.23 added condition to exclude transition cases
AND AgeRepPeriodEndYears >= 18

AND [RefDiscountedDateStandardCHC] > '2022-03-31'  -- FY 22/23 onwards only

AND a.OrgIDComm IN ('72Q', '91Q', 'D9Y0V', '36L', 'D4U1Y', 'B2M3M')

AND a.Sub_OrgID_Comm IN  (
                          '07V',    '08J',    '08P',    '08R',    '08T',    '08X',    -- 36L
                          '07N',    '07Q',    '08A',    '08K',    '08L',    '08Q',    -- 72Q
                          '09C',    '09E',    '09J',    '10A',    '10E',    '99J',  '09J 09W 10D',  -- 91Q
                          --'09F',    '09P',    '99K',    -- 97R
                          '07L',    '07T',    '08F',    '08M',    '08N',    '08V',    '08W',    -- A3A8R
                          --'05L',    '05C',    '05Y',    '06A',    -- D2P2L
                          '15D',    '99M',    '10C',  -- D4U1Y
                          '10L',    '10X',  '10K',    -- D9Y0V
                          --'07P',    '07W',    '09A',  -- W2U3Z
                          --'99Q',  '99P', -- 15N 
                          --'12D',  '99N',  '11E',  -- 92G 
						  '05H',  '5MD',  '5M9', '05R') -- B2M3M 
 
 UNION

 -- Refer for full assessment

 SELECT a.LocalPatientID
	  ,a.ServiceRequestId
	  ,a.OrgIDComm
	  ,a.Sub_OrgID_Comm
	  ,b.[Sub_ICB_Name]
	  ,b.Lower_Tier_Name
      ,b.[ICB_Code]
      ,b.[ICB_Name]
      ,b.[Region_Code]
      ,b.[Region_Name]
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

INNER JOIN [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_Sub_ICB_Lookup_Table] B

ON b.[Sub_ICB_Code] = a.OrgIDComm and b.[Lower_Tier_Code] = a.Sub_OrgID_Comm

WHERE

[ActivityTypeCHC] = '01' 

AND RefNotificationOutcomeStandardCHC = '01' 

AND [RefDiscountReasonCHC] is NULL  

AND [RefDiscountedDateStandardCHC] is NULL

AND [CommEligibilityDecisionOutcomeStandardCHC] IN ('01', '02', '03') -- Eligible for Std CHC, Not eligible for Std CHC but elgiible for FNC, Not elibile for Std CHC

AND a.RecordEndDate is NULL 

AND AgeRepPeriodEndYears >= 18

AND [CommEligibilityDecisionDateStandardCHC] > '2022-03-31' -- FY 22/23 onwards only

AND a.OrgIDComm IN ('72Q', '91Q', 'D9Y0V', '36L', 'D4U1Y', 'B2M3M')

AND a.Sub_OrgID_Comm IN  (
                              '07V',    '08J',    '08P',    '08R',    '08T',    '08X',    -- 36L
                              '07N',    '07Q',    '08A',    '08K',    '08L',    '08Q',    -- 72Q
                              '09C',    '09E',    '09J',    '10A',    '10E',    '99J',  '09J 09W 10D',  -- 91Q
                              --'09F',    '09P',    '99K',    -- 97R
                              --'07L',    '07T',    '08F',    '08M',    '08N',    '08V',    '08W',    -- A3A8R
                              --'05L',    '05C',    '05Y',    '06A',    -- D2P2L
                              '15D',    '99M',    '10C',  -- D4U1Y
                              '10L',    '10X',  '10K',    -- D9Y0V
                              --'07P',    '07W',    '09A',  -- W2U3Z
                              --'99Q',  '99P', -- 15N 
                              --'12D',  '99N',  '11E',  -- 92G 
							  '05H',  '5MD',  '5M9', '05R') -- B2M3M 


----------********************---------
---------------OUTPUT------------------
----------********************---------

SELECT	 a.OrgIDComm
		,a.Sub_OrgID_Comm
		,a.Sub_ICB_Name
		,a.Lower_Tier_Name
		,a.ICB_Code
		,a.ICB_Name
		,a.Region_Code
		,a.Region_Name
		,a.[Quarter]
--		,CAST(LEFT(a.[Quarter],4) AS int) AS [FY]
--		,a.LocalPatientID
		,COUNT(a.ServiceRequestId) AS AllReferrals
		,COUNT(b.ServiceRequestId) AS Referralsin28
		,CAST(COUNT(b.ServiceRequestId) AS float) / CAST(COUNT(a.ServiceRequestId) AS float) AS [Percentage_Refsin28]

INTO [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_LT_Recon_Quarterly_01]

FROM #AllRefsComp a

LEFT JOIN #Refsin28daysSL b

ON b.OrgIDComm = a.OrgIDComm AND b.Sub_OrgID_Comm = a.Sub_OrgID_Comm AND b.LocalPatientId = a.LocalPatientId AND b.ServiceRequestId = a.ServiceRequestId

GROUP BY a.OrgIDComm
		,a.Sub_OrgID_Comm
		,a.Sub_ICB_Name
		,a.Lower_Tier_Name
		,a.ICB_Code
		,a.ICB_Name
		,a.Region_Code
		,a.Region_Name
		,a.[Quarter]
--		,CAST(LEFT(a.[Quarter],4) AS int)
--		,a.LocalPatientId		
			   
			   
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CHC_PLDS_Recon_02	Number of incomplete referrals exceeding 28 days by 12+ weeks
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

----------*************************----------
----------GET 12+ WEEKS COHORT DATA----------
----------*************************----------

IF OBJECT_ID ('tempdb..#Over12WeeksSL') IS NOT NULL
DROP TABLE #Over12WeeksSL

SELECT LocalPatientId   
	  ,ServiceRequestId 
	  ,OrgIDComm
	  ,[Sub_ICB_Name]
	  ,Sub_OrgID_Comm
	  ,Lower_Tier_Name
	  ,ICB_Code
	  ,ICB_Name
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
			  ,b.[Sub_ICB_Name]
			  ,a.Sub_OrgID_Comm
			  ,b.Lower_Tier_Name
			  ,b.ICB_Code
			  ,b.ICB_Name
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

INNER JOIN [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_Sub_ICB_Lookup_Table] b

ON b.[Sub_ICB_Code] = a.OrgIDComm and b.[Lower_Tier_Code] = a.Sub_OrgID_Comm

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

AND OrgIDComm IN ('72Q', '91Q', 'D9Y0V', '36L', 'D4U1Y', 'B2M3M')

AND Sub_OrgID_Comm IN  (
                          '07V',    '08J',    '08P',    '08R',    '08T',    '08X',    -- 36L
                          '07N',    '07Q',    '08A',    '08K',    '08L',    '08Q',    -- 72Q
                          '09C',    '09E',    '09J',    '10A',    '10E',    '99J',  '09J 09W 10D',  -- 91Q
                          --'09F',    '09P',    '99K',    -- 97R
                          --'07L',    '07T',    '08F',    '08M',    '08N',    '08V',    '08W',    -- A3A8R
                          --'05L',    '05C',    '05Y',    '06A',    -- D2P2L
                          '15D',    '99M',    '10C',  -- D4U1Y
                          '10L',    '10X',  '10K',    -- D9Y0V
                          --'07P',    '07W',    '09A',  -- W2U3Z
                          --'99Q',  '99P', -- 15N 
                          --'12D',  '99N',  '11E',  -- 92G 
					  	  '05H',  '5MD',  '5M9', '05R') -- B2M3M 

GROUP BY  LocalPatientId   
		 ,ServiceRequestId 
		 ,OrgIDComm
		 ,[Sub_ICB_Name]
		 ,Sub_OrgID_Comm
		 ,Lower_Tier_Name
		 ,ICB_Code
		 ,ICB_Name
		 ,Region_Code
		 ,Region_Name
		 ,[Quarter]
		 --,ReferralRequestReceivedDateCHC
		 --,RefDiscountedDateStandardCHC
		 --,CommEligibilityDecisionDateStandardCHC


----------*************************----------
-------------REFS >12 WEEKS OUTPUT-----------
----------*************************----------

SELECT 	OrgIDComm
	   ,[Sub_ICB_Name]
	   ,Sub_OrgID_Comm
	   ,Lower_Tier_Name
	   ,[ICB_Code]
	   ,[ICB_Name]
	   ,[Region_Code]
	   ,[Region_Name]
--	   ,QuarterEndDate
	   --,RPEndDate
	   ,[Quarter]
	   ,COUNT (*) AS [Referrals>12Weeks]

INTO [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_LT_Recon_Quarterly_02]

FROM #Over12WeeksSL

GROUP BY OrgIDComm
		,Sub_OrgID_Comm
		,[Sub_ICB_Name]
		,Lower_Tier_Name
	    ,[ICB_Code]
	    ,[ICB_Name]
	    ,[Region_Code]
	    ,[Region_Name]
	    ,[Quarter]
--		,QuarterEndDate
		--,RPEndDate



/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CHC_PLDS_Recon_03	Percentage of Decision Support Tools carried out in an acute hospital setting
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

----------*************************----------
---------------GET DST DATA------------------
----------*************************----------

IF OBJECT_ID ('tempdb..#DSTdataSL') IS NOT NULL
DROP TABLE #DSTdataSL

--DECLARE @firstMonthOfFiscalQ1 int = 4 --1=January

SELECT a.LocalPatientID
	  ,a.ServiceRequestId
	  ,a.OrgIDComm
	  ,b.[Sub_ICB_Name]
	  ,a.Sub_OrgID_Comm
	  ,b.Lower_Tier_Name
	  ,b.[ICB_Code]
	  ,b.[ICB_Name]
	  ,b.[Region_Code]
	  ,b.[Region_Name]
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

INNER JOIN [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_Sub_ICB_Lookup_Table] b

ON b.[Sub_ICB_Code] = a.OrgIDComm and b.[Lower_Tier_Code] = a.Sub_OrgID_Comm

WHERE AgeRepPeriodEndYears >= 18

AND a.RecordEndDate IS NULL

AND a.DecSupportToolCompletionDateStandardCHC IS NOT NULL 

AND a.DecSupportToolCompletionDateStandardCHC > '2022-03-31'

AND a.OrgIDComm IN ('72Q', '91Q', 'D9Y0V', '36L', 'D4U1Y', 'B2M3M')

AND   a.Sub_OrgID_Comm IN  (
                              '07V',    '08J',    '08P',    '08R',    '08T',    '08X',    -- 36L
                              '07N',    '07Q',    '08A',    '08K',    '08L',    '08Q',    -- 72Q
                              '09C',    '09E',    '09J',    '10A',    '10E',    '99J',  '09J 09W 10D',  -- 91Q
                              --'09F',    '09P',    '99K',    -- 97R
                              --'07L',    '07T',    '08F',    '08M',    '08N',    '08V',    '08W',    -- A3A8R
                              --'05L',    '05C',    '05Y',    '06A',    -- D2P2L
                              '15D',    '99M',    '10C',  -- D4U1Y
                              '10L',    '10X',  '10K',    -- D9Y0V
                              --'07P',    '07W',    '09A',  -- W2U3Z
                              --'99Q',  '99P', -- 15N 
                              --'12D',  '99N',  '11E',  -- 92G 
							  '05H',  '5MD',  '5M9', '05R') -- B2M3M 

----------*************************----------
------------------DST OUTPUT-----------------
----------*************************----------

SELECT 	OrgIDComm
	   ,[Sub_ICB_Name]
	   ,Sub_OrgID_Comm
	   ,Lower_Tier_Name
	   ,[ICB_Code]
	   ,[ICB_Name]
	   ,[Region_Code]
	   ,[Region_Name]
	  --,RPEndDate
	  ,[Quarter]
	  ,CAST(SUM([UniqDSTsinAcute]) as float) AS [DSTsinAcute]
	  ,CAST(SUM([UniqDSTsComplete]) as float) AS [DSTsComplete]
	  ,CAST(SUM([UniqDSTsinAcute]) as float) / CAST(SUM([UniqDSTsComplete]) as float) AS [Percentage_DSTsinAcute]

INTO [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_LT_Recon_Quarterly_03]

FROM #DSTdataSL

GROUP BY OrgIDComm
		,Sub_OrgID_Comm
	    ,[Sub_ICB_Name]
	    ,Lower_Tier_Name
	    ,[ICB_Code]
	    ,[ICB_Name]
	    ,[Region_Code]
	    ,[Region_Name]
		,[Quarter]
		--,RPEndDate


/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CHC_PLDS_Recon_04	Number eligible at the end of the quarter (snapshot) - Standard CHC
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

----------*************************----------
-----------SERVICE LEVEL STD SNAP-----------
----------*************************----------

IF OBJECT_ID ('tempdb..#StdSnapShotSL') IS NOT NULL
DROP TABLE #StdSnapShotSL

SELECT   OrgIDComm
	    ,[Sub_ICB_Name]
	    ,Sub_OrgID_Comm
	    ,Lower_Tier_Name
	    ,[ICB_Code]
	    ,[ICB_Name]
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
	  ,b.[Sub_ICB_Name]
	  ,a.Sub_OrgID_Comm
	  ,b.Lower_Tier_Name
	  ,b.ICB_Code
	  ,b.ICB_Name
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

INNER JOIN [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_Sub_ICB_Lookup_Table] b

ON b.[Sub_ICB_Code] = a.OrgIDComm and b.[Lower_Tier_Code] = a.Sub_OrgID_Comm

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

AND AgeRepPeriodEndYears >= 18    

AND OrgIDComm IN ('72Q', '91Q', 'D9Y0V', '36L', 'D4U1Y', 'B2M3M')

AND   Sub_OrgID_Comm IN  (
                            '07V',    '08J',    '08P',    '08R',    '08T',    '08X',    -- 36L
                            '07N',    '07Q',    '08A',    '08K',    '08L',    '08Q',    -- 72Q
                            '09C',    '09E',    '09J',    '10A',    '10E',    '99J',  '09J 09W 10D',  -- 91Q
                            --'09F',    '09P',    '99K',    -- 97R
                            --'07L',    '07T',    '08F',    '08M',    '08N',    '08V',    '08W',    -- A3A8R
                            --'05L',    '05C',    '05Y',    '06A',    -- D2P2L
                            '15D',    '99M',    '10C',  -- D4U1Y
                            '10L',    '10X',  '10K',    -- D9Y0V
                            --'07P',    '07W',    '09A',  -- W2U3Z
                            --'99Q',  '99P', -- 15N 
                            --'12D',  '99N',  '11E',  -- 92G 
							'05H',  '5MD',  '5M9', '05R') -- B2M3M 

GROUP BY OrgIDComm
	    ,[Sub_ICB_Name]
	    ,Sub_OrgID_Comm
	    ,Lower_Tier_Name
	    ,[ICB_Code]
	    ,[ICB_Name]
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
	   ,a.[Sub_ICB_Name]
	   ,a.Sub_OrgID_Comm
	   ,a.Lower_Tier_Name
	   ,a.[ICB_Code]
	   ,a.[ICB_Name]
	   ,a.[Region_Code]
	   ,a.[Region_Name]
	   ,a.[Quarter]
--	   ,a.QuarterEndDate
	   ,COUNT(*) AS [StdSnapshot]
	  	  
INTO [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_LT_Recon_Quarterly_04]

FROM #StdSnapShotSL a

GROUP BY a.OrgIDComm
		,a.Sub_OrgID_Comm
	    ,a.[Sub_ICB_Name]
		,a.Lower_Tier_Name
	    ,a.[ICB_Code]
	    ,a.[ICB_Name]
	    ,a.[Region_Code]
	    ,a.[Region_Name]
		,a.[Quarter]
--		,a.QuarterEndDate



/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CHC_PLDS_Recon_05	Number eligible at the end of the quarter (snapshot) - Fast-Track CHC
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

--------*************************----------
----------SERVICE LEVEL FT SNAP------------
--------*************************----------

IF OBJECT_ID ('tempdb..#FTSnapShotSL') IS NOT NULL
DROP TABLE #FTSnapShotSL

SELECT   OrgIDComm
	    ,[Sub_ICB_Name]
	    ,Sub_OrgID_Comm
	    ,Lower_Tier_Name
	    ,[ICB_Code]
	    ,[ICB_Name]
	 	,Region_Code
		,Region_Name
		,[Quarter]
		,LocalPatientID

INTO #FTSnapShotSL

FROM (SELECT ROW_NUMBER() OVER(PARTITION BY a.OrgIDComm, a.LocalPatientID, a.ServiceRequestId, d.[Quarter] ORDER BY c.RPEndDate DESC) RN
	  ,a.LocalPatientID
	  ,a.ServiceRequestId
	  ,a.OrgIDComm
	  ,b.[Sub_ICB_Name]
	  ,a.Sub_OrgID_Comm
	  ,b.Lower_Tier_Name
	  ,b.ICB_Code
	  ,b.ICB_Name
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

INNER JOIN [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_Sub_ICB_Lookup_Table] b

ON b.[Sub_ICB_Code] = a.OrgIDComm and b.[Lower_Tier_Code] = a.Sub_OrgID_Comm

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

AND AgeRepPeriodEndYears >= 18  

AND OrgIDComm IN ('72Q', '91Q', 'D9Y0V', '36L', 'D4U1Y', 'B2M3M')

AND   Sub_OrgID_Comm IN  (
                            '07V',    '08J',    '08P',    '08R',    '08T',    '08X',    -- 36L
                            '07N',    '07Q',    '08A',    '08K',    '08L',    '08Q',    -- 72Q
                            '09C',    '09E',    '09J',    '10A',    '10E',    '99J',  '09J 09W 10D',  -- 91Q
                            --'09F',    '09P',    '99K',    -- 97R
                            --'07L',    '07T',    '08F',    '08M',    '08N',    '08V',    '08W',    -- A3A8R
                            --'05L',    '05C',    '05Y',    '06A',    -- D2P2L
                            '15D',    '99M',    '10C',  -- D4U1Y
                            '10L',    '10X',  '10K',    -- D9Y0V
                            --'07P',    '07W',    '09A',  -- W2U3Z
                            --'99Q',  '99P', -- 15N 
                            --'12D',  '99N',  '11E',  -- 92G 
							'05H',  '5MD',  '5M9', '05R') -- B2M3M 

GROUP BY OrgIDComm
	    ,[Sub_ICB_Name]
	    ,Sub_OrgID_Comm
	    ,Lower_Tier_Name
	    ,[ICB_Code]
	    ,[ICB_Name]
	 	,Region_Code
		,Region_Name
		,[Quarter]
		,LocalPatientID



--------*************************----------
----------------OUTPUT---------------------
--------*************************----------

SELECT a.OrgIDComm
	  ,a.[Sub_ICB_Name]
	  ,a.Sub_OrgID_Comm
	  ,a.Lower_Tier_Name
	  ,a.[ICB_Code]
	  ,a.[ICB_Name]
	  ,a.[Region_Code]
	  ,a.[Region_Name]
	  ,a.[Quarter]
--	  ,a.QuarterEndDate
	  ,COUNT(*) AS [FTSnapshot]
	  	  
INTO [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_LT_Recon_Quarterly_05]

FROM #FTSnapShotSL a

GROUP BY a.OrgIDComm
		,a.[Sub_OrgID_Comm]
		,a.[Sub_ICB_Name]
		,a.Lower_Tier_Name
		,a.ICB_Code
		,a.ICB_Name
		,a.Region_Code
		,a.Region_Name
		,a.[Quarter]
--		,a.QuarterEndDate


/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CHC_PLDS_Recon_06	Number of new referrals per 50,000 population (Standard CHC)
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

---------************************--------------
---------------NEW REFERRALS-------------------
----------************************-------------

--DECLARE @firstMonthOfFiscalQ1 int = 4; --1=January

IF OBJECT_ID ('tempdb..#NewStdRefsSL') IS NOT NULL
DROP TABLE #NewStdRefsSL

SELECT a.LocalPatientID
	  ,a.ServiceRequestId
	  ,a.OrgIDComm
	  ,b.Sub_ICB_Name
	  ,a.Sub_OrgID_Comm
	  ,b.Lower_Tier_Name
	  ,b.ICB_Code
	  ,b.ICB_Name
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

INNER JOIN [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_Sub_ICB_Lookup_Table] b

ON b.[Sub_ICB_Code] = a.OrgIDComm and b.[Lower_Tier_Code] = a.Sub_OrgID_Comm

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

AND a.OrgIDComm IN ('72Q', '91Q', 'D9Y0V', '36L', 'D4U1Y', 'B2M3M')

AND   a.Sub_OrgID_Comm IN  (
                             '07V',    '08J',    '08P',    '08R',    '08T',    '08X',    -- 36L
                             '07N',    '07Q',    '08A',    '08K',    '08L',    '08Q',    -- 72Q
                             '09C',    '09E',    '09J',    '10A',    '10E',    '99J',  '09J 09W 10D',  -- 91Q
                             --'09F',    '09P',    '99K',    -- 97R
                             --'07L',    '07T',    '08F',    '08M',    '08N',    '08V',    '08W',    -- A3A8R
                             --'05L',    '05C',    '05Y',    '06A',    -- D2P2L
                             '15D',    '99M',    '10C',  -- D4U1Y
                             '10L',    '10X',  '10K',    -- D9Y0V
                             --'07P',    '07W',    '09A',  -- W2U3Z
                             --'99Q',  '99P', -- 15N 
                             --'12D',  '99N',  '11E',  -- 92G 
							 '05H',  '5MD',  '5M9', '05R') -- B2M3M 

GROUP BY a.OrgIDComm
		,a.Sub_OrgID_Comm
		,b.[Sub_ICB_Name]
		,b.Lower_Tier_Name
		,a.LocalPatientID
		,a.ServiceRequestId
		,b.ICB_Code
		,b.ICB_Name
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

---REMOVE PATIENTS ALREADY ELIGIBLE (currently looks at pts eligible via std route in absence of full dataset as noted above 

--IF OBJECT_ID ('tempdb..#NewStdRefsSLMinusAlreadyEligible') IS NOT NULL
--DROP TABLE #NewStdRefsSLMinusAlreadyEligible

--SELECT	a.OrgIDComm
--		,a.Sub_OrgID_Comm
--		,a.Sub_ICB_Name
--		,Lower_Tier_Name
--		,a.ICB_Code
--		,a.ICB_Name
--		,a.Region_Code
--		,a.Region_Name
--		,a.[Quarter]
--		,a.QuarterEndDate
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
--		,a.Sub_OrgID_Comm
--		,a.Sub_ICB_Name
--		,a.Lower_Tier_Name
--		,a.ICB_Code
--		,a.ICB_Name
--		,a.Region_Code
--		,a.Region_Name
--		,a.LocalPatientID
--		,a.[Quarter]
--		,a.QuarterEndDate

-----------**************************----------
---------------------OUTPUT--------------------
-----------**************************----------

SELECT OrgIDComm
	  ,Sub_ICB_Name
	  ,Sub_OrgID_Comm
	  ,Lower_Tier_Name
	  ,ICB_Code
	  ,ICB_Name
	  ,Region_Code
	  ,Region_Name
	  ,[Quarter]
--	  ,QuarterEndDate
	  ,COUNT(*) AS [NewRefs]

INTO [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_LT_Recon_Quarterly_06]

FROM #NewStdRefsSL a

WHERE CAST(LEFT(a.[Quarter],4) AS int) > 2021  -- excludes historic referrals 

GROUP BY OrgIDComm
		,Sub_OrgID_Comm
		,Sub_ICB_Name
		,Lower_Tier_Name
		,ICB_Code
		,ICB_Name
		,Region_Code
		,Region_Name
		,[Quarter]
--		,QuarterEndDate



/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CHC_PLDS_Recon_07	Number of new referrals per 50,000 population (Fast-Track CHC)
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

----------*************************----------
------------SERVICE LEVEL FT REFS------------
----------*************************----------

--DECLARE @firstMonthOfFiscalQ1 int = 4; --1=January

IF OBJECT_ID ('tempdb..#NewFTRefsSL') IS NOT NULL
DROP TABLE #NewFTRefsSL

SELECT a.LocalPatientID
	  ,a.ServiceRequestId
	  ,a.OrgIDComm
	  ,b.Sub_ICB_Name
	  ,a.Sub_OrgID_Comm
	  ,b.Lower_Tier_Name
	  ,b.ICB_Code
	  ,b.ICB_Name
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

INNER JOIN [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_Sub_ICB_Lookup_Table] b

ON b.[Sub_ICB_Code] = a.OrgIDComm and b.[Lower_Tier_Code] = a.Sub_OrgID_Comm

WHERE ActivityTypeCHC = '02' 

AND AgeRepPeriodEndYears >= 18

AND a.RecordEndDate IS NULL

AND a.OrgIDComm IN ('72Q', '91Q', 'D9Y0V', '36L', 'D4U1Y', 'B2M3M')

AND a.Sub_OrgID_Comm IN  (
                             '07V',    '08J',    '08P',    '08R',    '08T',    '08X',    -- 36L
                             '07N',    '07Q',    '08A',    '08K',    '08L',    '08Q',    -- 72Q
                             '09C',    '09E',    '09J',    '10A',    '10E',    '99J',  '09J 09W 10D',  -- 91Q
                             --'09F',    '09P',    '99K',    -- 97R
                             --'07L',    '07T',    '08F',    '08M',    '08N',    '08V',    '08W',    -- A3A8R
                             --'05L',    '05C',    '05Y',    '06A',    -- D2P2L
                             '15D',    '99M',    '10C',  -- D4U1Y
                             '10L',    '10X',  '10K',    -- D9Y0V
                             --'07P',    '07W',    '09A',  -- W2U3Z
                             --'99Q',  '99P', -- 15N 
                             --'12D',  '99N',  '11E',  -- 92G 
							 '05H',  '5MD',  '5M9', '05R') -- B2M3M 

GROUP BY a.OrgIDComm
		,a.Sub_OrgID_Comm
		,b.Sub_ICB_Name
		,b.Lower_Tier_Name
		,b.ICB_Code
		,b.ICB_Name
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
	  ,a.Sub_ICB_Name
	  ,a.Sub_OrgID_Comm
	  ,a.Lower_Tier_Name
	  ,a.ICB_Code
	  ,a.ICB_Name
	  ,a.Region_Code
	  ,a.Region_Name
	  ,a.[Quarter]
--	  ,a.QuarterEndDate
	  ,COUNT(*) AS [NewFTRefs]

INTO [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_LT_Recon_Quarterly_07]

FROM #NewFTRefsSL a

WHERE CAST(LEFT(a.[Quarter],4) AS int) > 2021  -- excludes historic referrals 

GROUP BY a.OrgIDComm
		,a.Sub_OrgID_Comm
		,a.Sub_ICB_Name
		,a.Lower_Tier_Name
		,a.ICB_Code
		,a.ICB_Name
		,a.Region_Code
		,a.Region_Name
		,a.[Quarter]
--		,a.QuarterEndDate



/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CHC_PLDS_Recon_08	Number eligible at the end of the quarter (snapshot) - Funded Nursing Care i.e. FNC
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

----------*************************----------
-----------SERVICE LEVEL FNC SNAP-----------
----------*************************----------

IF OBJECT_ID ('tempdb..#FNCSnapShotSL') IS NOT NULL
DROP TABLE #FNCSnapShotSL

SELECT   OrgIDComm
	    ,[Sub_ICB_Name]
	    ,Sub_OrgID_Comm
	    ,Lower_Tier_Name
	    ,[ICB_Code]
	    ,[ICB_Name]
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
			  ,b.Sub_ICB_Name
			  ,a.Sub_OrgID_Comm
			  ,b.Lower_Tier_Name
			  ,b.ICB_Code
			  ,b.ICB_Name
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

INNER JOIN [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_Sub_ICB_Lookup_Table] b

ON b.[Sub_ICB_Code] = a.OrgIDComm and b.[Lower_Tier_Code] = a.Sub_OrgID_Comm

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
AND AgeRepPeriodEndYears >= 18  

AND OrgIDComm IN ('72Q', '91Q', 'D9Y0V', '36L', 'D4U1Y', 'B2M3M')

AND   Sub_OrgID_Comm IN  (
                             '07V',    '08J',    '08P',    '08R',    '08T',    '08X',    -- 36L
                             '07N',    '07Q',    '08A',    '08K',    '08L',    '08Q',    -- 72Q
                             '09C',    '09E',    '09J',    '10A',    '10E',    '99J',  '09J 09W 10D',  -- 91Q
                             --'09F',    '09P',    '99K',    -- 97R
                             --'07L',    '07T',    '08F',    '08M',    '08N',    '08V',    '08W',    -- A3A8R
                             --'05L',    '05C',    '05Y',    '06A',    -- D2P2L
                             '15D',    '99M',    '10C',  -- D4U1Y
                             '10L',    '10X',  '10K',    -- D9Y0V
                             --'07P',    '07W',    '09A',  -- W2U3Z
                             --'99Q',  '99P', -- 15N 
                             --'12D',  '99N',  '11E',  -- 92G 
							 '05H',  '5MD',  '5M9', '05R') -- B2M3M 

GROUP BY OrgIDComm
	    ,[Sub_ICB_Name]
	    ,Sub_OrgID_Comm
	    ,Lower_Tier_Name
	    ,[ICB_Code]
	    ,[ICB_Name]
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
	  ,a.Sub_ICB_Name
	  ,a.Sub_OrgID_Comm
	  ,a.Lower_Tier_Name
	  ,a.ICB_Code
	  ,a.ICB_Name
	  ,a.Region_Code
	  ,a.Region_Name
	  ,a.[Quarter]
	  --,a.RPEndDate
	  ,COUNT(*) AS [FNCSnapshot]
	  --,b.[Population]
	  --,(COUNT(*) / CAST(SUM(b.[Population]) as float)) * 50000 AS [FNCSnapshot50k]
	  	  
INTO [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_LT_Recon_Quarterly_08]

FROM #FNCSnapShotSL a

--INNER JOIN #Populations b ON b.Org_Code collate SQL_Latin1_General_CP1_CI_AS = a.OrgIDComm collate SQL_Latin1_General_CP1_CI_AS AND b.Effective_Snapshot_Date = a.PopulationsDate

GROUP BY a.OrgIDComm
	    ,a.Sub_OrgID_Comm
	    ,a.Sub_ICB_Name
	    ,a.Lower_Tier_Name
	    ,a.ICB_Code
	    ,a.ICB_Name
	    ,a.Region_Code
	    ,a.Region_Name
		,a.[Quarter]
		--,a.RPEndDate
		--,[Population]




/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CHC_PLDS_Recon_9 (METRICS 9-14 in one table) Number of incomplete referrals exceeding 28 days by time buckets
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

----------************************************----------
----------GET REFERRALS EXCEEDING 28 DAYS DATA----------
----------************************************----------

IF OBJECT_ID ('tempdb..#RefsExc28') IS NOT NULL
DROP TABLE #RefsExc28

SELECT LocalPatientId   
	  ,ServiceRequestId 
	  ,OrgIDComm
	  ,[Sub_ICB_Name]
	  ,Sub_OrgID_Comm
	  ,Lower_Tier_Name
	  ,ICB_Code
	  ,ICB_Name
	  ,Region_Code
	  ,Region_Name
	  ,[Quarter]
	  --,ReferralRequestReceivedDateCHC
	  --,RefDiscountedDateStandardCHC
	  --,CommEligibilityDecisionDateStandardCHC
	  , CASE WHEN DATEDIFF(DAY,[ReferralRequestReceivedDateCHC],CAST(QuarterEndDate AS DATE)) BETWEEN 29 AND 42 THEN 1  -- Is day of referral counted as day 1 or day 0??
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
			  ,b.[Sub_ICB_Name]
			  ,a.Sub_OrgID_Comm
			  ,b.Lower_Tier_Name
			  ,b.ICB_Code
			  ,b.ICB_Name
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

INNER JOIN [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_Sub_ICB_Lookup_Table] b

ON b.[Sub_ICB_Code] = a.OrgIDComm and b.[Lower_Tier_Code] = a.Sub_OrgID_Comm

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

AND OrgIDComm IN ('72Q', '91Q', 'D9Y0V', '36L', 'D4U1Y', 'B2M3M')

AND Sub_OrgID_Comm IN  (
                          '07V',    '08J',    '08P',    '08R',    '08T',    '08X',    -- 36L
                          '07N',    '07Q',    '08A',    '08K',    '08L',    '08Q',    -- 72Q
                          '09C',    '09E',    '09J',    '10A',    '10E',    '99J',  '09J 09W 10D',  -- 91Q
                          --'09F',    '09P',    '99K',    -- 97R
                          --'07L',    '07T',    '08F',    '08M',    '08N',    '08V',    '08W',    -- A3A8R
                          --'05L',    '05C',    '05Y',    '06A',    -- D2P2L
                          '15D',    '99M',    '10C',  -- D4U1Y
                          '10L',    '10X',  '10K',    -- D9Y0V
                          --'07P',    '07W',    '09A',  -- W2U3Z
                          --'99Q',  '99P', -- 15N 
                          --'12D',  '99N',  '11E',  -- 92G 
					  	  '05H',  '5MD',  '5M9', '05R') -- B2M3M 

GROUP BY  LocalPatientId   
		 ,ServiceRequestId 
		 ,OrgIDComm
		 ,[Sub_ICB_Name]
		 ,Sub_OrgID_Comm
		 ,Lower_Tier_Name
		 ,ICB_Code
		 ,ICB_Name
		 ,Region_Code
		 ,Region_Name
		 ,[Quarter]
		 --,ReferralRequestReceivedDateCHC
		 --,RefDiscountedDateStandardCHC
		 --,CommEligibilityDecisionDateStandardCHC
	  , CASE WHEN DATEDIFF(DAY,[ReferralRequestReceivedDateCHC],CAST(QuarterEndDate AS DATE)) BETWEEN 29 AND 42 THEN 1  -- Is day of referral counted as day 1 or day 0??
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


----------********************************************----------
-------------REFS OUTSTANDING BY TIME BUCKETS OUTPUT-----------
----------********************************************----------

SELECT OrgIDComm
	  ,Sub_ICB_Name
	  ,Sub_OrgID_Comm
	  ,Lower_Tier_Name
	  ,ICB_Code
	  ,ICB_Name
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

INTO [NHSE_Sandbox_CHC].[dbo].[tbl_CHC_PLDS_LT_Recon_Quarterly_09]

FROM #RefsExc28

GROUP BY OrgIDComm
	    ,Sub_OrgID_Comm
	    ,Sub_ICB_Name
	    ,Lower_Tier_Name
	    ,ICB_Code
	    ,ICB_Name
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
