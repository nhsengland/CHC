---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INNER JOIN on [chc].[vw_000_Header_Current] returns latest record per reporting period (re-submissions create duplicates which are all within the Header table, so view excludes the earlier versions) 
-- View also creates calculation of RecordEndDate based on the following record's RecordStartDate (RecordEndDate = NULL indicates the latest record)
-- Descriptive columns brought in from relevant reference tables [NHSE_Sandbox_CHC].[dbo].[PLDS.Ref_] 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT a.[CHC_Load_ID]	
      ,a.[CarePackageIDCHC]	
      ,[ReviewTypeCodeCHCCarePackage]	
      ,CASE WHEN [a].[ReviewTypeCodeCHCCarePackage] IS NULL THEN 'BLANK' ELSE COALESCE((SELECT [Ref_ReviewType] FROM [NHSE_Sandbox_CHC].[dbo].[PLDS.Ref_ReviewType] WHERE [Code]=[a].[ReviewTypeCodeCHCCarePackage]),'INVALID') END [ReviewTypeCodeCHCCarePackage_Ref] /*MforMANDATORY*/	
      ,[ReviewDateCHCCarePackage]	
      ,[ReviewOutcomeCHCCarePackage]	
      ,CASE WHEN [a].[ReviewOutcomeCHCCarePackage] IS NULL THEN 'BLANK' ELSE COALESCE((SELECT [Ref_ReviewOutcome] FROM [NHSE_Sandbox_CHC].[dbo].[PLDS.Ref_ReviewOutcome] WHERE [Code]=[a].[ReviewOutcomeCHCCarePackage]),'INVALID') END [ReviewOutcomeCHCCarePackage_Ref]	
      ,[ReviewOutcomeCHCEligibility]	
      ,CASE WHEN [a].[ReviewOutcomeCHCEligibility] IS NULL THEN 'BLANK' ELSE COALESCE((SELECT [Ref_ReviewOutcomeElig] FROM [NHSE_Sandbox_CHC].[dbo].[PLDS.Ref_ReviewOutcomeElig] WHERE [Code]=[a].[ReviewOutcomeCHCEligibility]),'INVALID') END [ReviewOutcomeCHCEligibility_Ref]	
      ,[EligibilityStatusDateOfChangeCHCCarePackage]	
      ,[PlannedReviewDateCHCCarePackage]	
      ,a.[Effective_From]	
      ,a.[RecordNumber]	
      ,[CHC103UniqID]	
      ,a.[OrgIDComm]	
      ,a.[UniqSubmissionID]	
      ,a.[UniqCarePackageID]	
	  ,CONCAT(a.OrgIDComm, a.CarePackageIDCHC, ReviewDateCHCCarePackage) AS [UniqReviewID]
      ,[AgeServReviewDateYears]	
      ,[AgeEligStatusDateYears]	
      ,a.[PCD_Indicator]	
      ,a.[RecordStartDate]	
      ,DATEADD(d,-1,LAG(a.RecordStartDate,1) OVER(PARTITION BY a.CarePackageIDCHC ORDER BY a.RecordStartDate DESC)) [RecordEndDate]	
      ,a.[Sub_OrgIDComm] [Sub_OrgID_Comm]	
      ,a.[Der_LoadDate]	
      ,a.[Der_FileName]	
      ,a.Token_Person_ID
	
	
  FROM [NHSE_Sandbox_CHC].[chc].[103_Review] a 	
  INNER JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_000_Header_Current] b	
  ON a.CHC_Load_ID=b.CHC_Load_ID	
  AND a.UniqSubmissionID=b.UniqSubmissionID		
