------------------------------------------------------------------------------------------------------------------------------------------------------------
-- First CTE - using the PLDS_Reviews view, where a care package has two or more reviews associated with it, the number of days between subsequent reviews
-- is calculated. 
-- Second CTE - joins the care package and referral data from the main PLDS views (102, 101, 000) to the number of days calculated in the first CTE.
-- Various combinations of the fields [ReviewTypeCodeCHCCarePackage], [ReviewNumber], [DaysBetweenReviews] and [CommEligibilityDecisionDateStandardCHC] are
-- used to identify whether a review was due, whether it took place on schedule or if various data quality issues are present.
-- This view feeds the PLDS Reviews dashboard.
------------------------------------------------------------------------------------------------------------------------------------------------------------

WITH CTE AS (
SELECT   a.[ReviewNumber]
		,a.[CarePackageLocalPatientID]
		,a.[ServiceRequestId]
		,a.[CommEligibilityDecisionDateStandardCHC]
		,a.[CommEligibilityDecisionOutcomeStandardCHC_Ref]
		,a.[ReviewTypeCodeCHCCarePackage]
		,a.[ReviewTypeCodeCHCCarePackage_Ref]
		,a.[ReviewDateCHCCarePackage]
		,a.[ReviewOutcomeCHCCarePackage_Ref]
		,a.[UniqReviewID]
	   ,CASE WHEN a.ReviewDateCHCCarePackage IS NULL THEN '99999'
			 WHEN a.[ReviewTypeCodeCHCCarePackage] = '01' AND a.[ReviewNumber] = 1 THEN DATEDIFF(DAY,a.[CommEligibilityDecisionDateStandardCHC],a.[ReviewDateCHCCarePackage])
		     ELSE DATEDIFF(DAY,b.[ReviewDateCHCCarePackage],a.[ReviewDateCHCCarePackage]) 
		     END AS [DaysBetweenReviews]
	   ,CASE WHEN a.ReviewDateCHCCarePackage IS NULL THEN '99999'
			 WHEN a.[ReviewTypeCodeCHCCarePackage] = '01' AND a.[ReviewNumber] = 1 THEN DATEDIFF(MONTH,a.[CommEligibilityDecisionDateStandardCHC],a.[ReviewDateCHCCarePackage]) 
			 ELSE DATEDIFF(MONTH,b.[ReviewDateCHCCarePackage],a.[ReviewDateCHCCarePackage])  
		     END AS [MonthsBetweenReviews]

FROM  [dbo].[vw_PLDS_Reviews] a

LEFT JOIN [dbo].[vw_PLDS_Reviews] b 
ON a.[CarePackageLocalPatientID] = b.[CarePackageLocalPatientID] AND (a.[ReviewNumber]-1)=b.[ReviewNumber]

--WHERE a.ReviewDateCHCCarePackage IS NOT NULL -- exclude records where review date has been left blank
),


CTE2 AS (
SELECT   cp.[UniqCarePackageID]
		,r.[LocalPatientID]
		,cp.[UniqCarePackageID] + '-' + r.[LocalPatientId] AS [CarePackageLocalPatientID]
		,r.[ServiceRequestId]
		,[PersonalHealthBudgetTypeCode]
		,[PersonalHealthBudgetTypeCode_Ref]
		,[CareProductTypeCode]
		,[CareProductTypeCode_Ref]
		,[CommEligibilityDecisionDateStandardCHC]
		,[CommEligibilityDecisionOutcomeStandardCHC_Ref]
		,[EndDateCarePackage]
		,cp.[RecordEndDate]
		,cp.[OrgIDComm] AS [SubICBCode]	
		,[Sub_ICB_Name] 		
        ,[ICB_ODS_Code] AS [ICB_Code]		
        ,[Integrated_Care_Board_Name]	
        ,[Region_Code]	
        ,[Region_Name]	
	    ,[RPStartDate] AS [ReportingDate]
		,[RPEndDate]
		,CASE WHEN cp.[EndDateCarePackage] IS NULL THEN 'Open' 			
			  WHEN cp.[EndDateCarePackage] > [RPEndDate] THEN 'Open' 
			  ELSE 'Closed' 
			  END [CarePackageStatus]
		
FROM 	[NHSE_Sandbox_CHC].[chc].[vw_reporting_102_CarePackage_Current]	cp		

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_101_ReferralAssessmentOutcome_Current] r
ON (cp.UniqSubmissionID=r.UniqSubmissionID AND cp.UniqServReqID=r.UniqServReqID)

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_000_Header_Current] h
ON cp.UniqSubmissionID=h.UniqSubmissionID

WHERE cp.RecordEndDate IS NULL

AND NOT (cp.OrgIDComm = '00L' AND RPStartDate < '2023-03-01')

)


SELECT b.[CarePackageLocalPatientID]
	  ,[PersonalHealthBudgetTypeCode]
      ,[PersonalHealthBudgetTypeCode_Ref]
      ,[CareProductTypeCode]
      ,[CareProductTypeCode_Ref]
	  ,[CarePackageStatus]
	  ,b.[CommEligibilityDecisionDateStandardCHC]
	  ,b.[CommEligibilityDecisionOutcomeStandardCHC_Ref]
	  ,[ReviewNumber]
	  ,[ReviewTypeCodeCHCCarePackage_Ref] AS [ReviewType]
	  ,[ReviewDateCHCCarePackage] AS [ReviewDate]
	  ,[ReviewOutcomeCHCCarePackage_Ref] AS [ReviewOutcome]
	  ,[DaysBetweenReviews]
	  ,[MonthsBetweenReviews]
	  ,[UniqReviewID]
	  ,[SubICBCode]		
      ,[Sub_ICB_Name] 		
      ,[ICB_Code]				
      ,[Integrated_Care_Board_Name]				
      ,[Region_Code]		
      ,[Region_Name]
	  ,[ReportingDate]
	  ,[RecordEndDate]
	  ,CASE WHEN [ReviewTypeCodeCHCCarePackage] = '01' AND [ReviewNumber] =1 AND [DaysBetweenReviews] BETWEEN 1 AND 92 THEN 'Review completed on schedule' 
			WHEN [ReviewTypeCodeCHCCarePackage] = '01' AND [ReviewNumber] =1 AND [DaysBetweenReviews] BETWEEN 93 AND 99998 THEN 'Review not completed on schedule' 
			WHEN [ReviewTypeCodeCHCCarePackage] = '01' AND [ReviewNumber] =1 AND [DaysBetweenReviews]<=0 THEN 'Review Date <= Eligibility Decision Date ' 
			WHEN [ReviewTypeCodeCHCCarePackage] = '02' AND [DaysBetweenReviews] BETWEEN 1 AND 365 THEN 'Review completed on schedule'
			WHEN [ReviewTypeCodeCHCCarePackage] = '02' AND [DaysBetweenReviews] BETWEEN 366 AND 99998 THEN 'Review not completed on schedule'
			WHEN [ReviewTypeCodeCHCCarePackage_Ref] IN ('BLANK','Invalid') THEN 'Invalid Review Type' 
			WHEN [ReviewTypeCodeCHCCarePackage] = '03' THEN 'Other/Ad Hoc review'
			WHEN [ReviewTypeCodeCHCCarePackage] = '01' AND [ReviewNumber] >1 THEN 'Multiple 3 month reviews' 
			WHEN [ReviewTypeCodeCHCCarePackage] = '01' AND [ReviewNumber] =1 AND a.[CommEligibilityDecisionDateStandardCHC] IS NULL THEN 'No Eligibility Decision Date'
			WHEN [ReviewTypeCodeCHCCarePackage] = '02' AND [DaysBetweenReviews] IS NULL then 'One 12 month review record' 
			WHEN [ReviewTypeCodeCHCCarePackage] IN ('01', '02') AND [DaysBetweenReviews] = 99999 THEN 'No Review Date'
			WHEN [ReviewDateCHCCarePackage] IS NULL AND DATEDIFF(DAY,b.[CommEligibilityDecisionDateStandardCHC],b.[RPEndDate])<=92 AND ([EndDateCarePackage] IS NULL OR [EndDateCarePackage] > b.[RPEndDate]) THEN 'Review not required yet' 
			ELSE 'No reviews' 
			END AS [ReviewStatus]
FROM CTE2 b

LEFT JOIN CTE a 
ON a.[CarePackageLocalPatientID] = b.[CarePackageLocalPatientID] AND a.[ServiceRequestId] = b.[ServiceRequestId]

