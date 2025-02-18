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


