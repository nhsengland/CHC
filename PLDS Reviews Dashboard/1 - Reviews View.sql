---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Since [UniqCarePackageID] is not a truly unique identifier, [UniqCarePackageID] and [LocalPatientID] are concatenated to create 'CarePackageLocalPatientID'
-- which acts as a truly unique care package identifier.
-- The [RecordEndDate] field was built incorrectly in the 103_Review table which makes it difficult to identify the most recent record per review. Therefore,
-- a flag column, 'LatestRecord', has been built in the script to do this.
-- Another column, 'ReviewNumber', has also been built, to order the reviews per care package i.e. the earliest review associated with a care package 
-- has ReviewNumber = 1, the next review that took place has ReviewNumber = 2 etc.
-- This view feeds the PLDS_Reviews_Analysis_SR view.
---------------------------------------------------------------------------------------------------------------------------------------------------------------	

WITH CTE AS (

       SELECT a.*
       FROM (SELECT ROW_NUMBER() OVER(PARTITION BY rv.[UniqCarePackageID], r.[LocalPatientID], rv.[ReviewDateCHCCarePackage] ORDER BY rv.[RecordStartDate] DESC) AS LatestRecord -- i.e. RecordEndDate = NULL
             ,rv.[UniqCarePackageID]
			 ,rv.[UniqSubmissionID]
			 ,r.[LocalPatientID]
			 ,rv.[UniqCarePackageID] + '-' + r.[LocalPatientId] AS CarePackageLocalPatientID
			 ,r.[ServiceRequestId]
			 ,[CommEligibilityDecisionDateStandardCHC]
			 ,[CommEligibilityDecisionOutcomeStandardCHC_Ref]
             ,[ReviewTypeCodeCHCCarePackage]
             ,[ReviewTypeCodeCHCCarePackage_Ref]
             ,[ReviewDateCHCCarePackage]
             ,[ReviewOutcomeCHCCarePackage_Ref]
			 ,[UniqReviewID]
			 ,rv.[OrgIDComm] AS [SubICBCode]		
		     ,[RPStartDate] 


         FROM 	[NHSE_Sandbox_CHC].[chc].[vw_reporting_103_Review_Current] rv

		 LEFT JOIN  [NHSE_Sandbox_CHC].[chc].[vw_reporting_102_CarePackage_Current]	cp	
		 ON (cp.UniqSubmissionID=rv.UniqSubmissionID AND cp.UniqCarePackageID=rv.UniqCarePackageID)
		 
		 LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_101_ReferralAssessmentOutcome_Current] r
		 ON (cp.UniqSubmissionID=r.UniqSubmissionID AND cp.UniqServReqID=r.UniqServReqID)

		 LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_000_Header_Current] h
		 ON rv.UniqSubmissionID=h.UniqSubmissionID
		 )a 

         WHERE LatestRecord = 1
) 

SELECT ROW_NUMBER() OVER(PARTITION BY [UniqCarePackageID], [LocalPatientID] ORDER BY [ReviewDateCHCCarePackage]) AS ReviewNumber
	   ,[UniqReviewID]
	   ,[UniqCarePackageID]
	   ,[LocalPatientID]
	   ,[CarePackageLocalPatientID]
	   ,[ServiceRequestId]
	   ,[CommEligibilityDecisionDateStandardCHC]
	   ,[CommEligibilityDecisionOutcomeStandardCHC_Ref]
       ,[ReviewTypeCodeCHCCarePackage]
       ,[ReviewTypeCodeCHCCarePackage_Ref]
       ,[ReviewDateCHCCarePackage]
       ,[ReviewOutcomeCHCCarePackage_Ref]
	   ,[SubICBCode]		
	   ,[RPStartDate]
	   ,[UniqSubmissionID]
FROM CTE


