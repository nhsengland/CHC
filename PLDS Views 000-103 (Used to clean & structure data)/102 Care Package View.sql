SELECT /*TOP (1000)*/ a.[CHC_Load_ID]
      ,[CarePackageIDCHC]
      ,[ServiceRequestId]
      ,[StartDateCarePackage]
      ,[EndDateCarePackage]
      ,[PersonalHealthBudgetTypeCode]
      ,CASE WHEN [a].[PersonalHealthBudgetTypeCode] IS NULL THEN 'BLANK' ELSE COALESCE((SELECT [Ref_PHBType] FROM [NHSE_Sandbox_CHC].[dbo].[PLDS.Ref_PHBType] WHERE [Code]=[a].[PersonalHealthBudgetTypeCode]),'INVALID') END [PersonalHealthBudgetTypeCode_Ref]
      ,[OrgIDProvider]
      ,[CostCentreCode]
      ,[SubjectiveCode]
      ,[CareProductTypeCode]
      ,CASE WHEN [a].[CareProductTypeCode] IS NULL THEN 'BLANK' ELSE COALESCE((SELECT [Ref_CareProductType] FROM [NHSE_Sandbox_CHC].[dbo].[PLDS.Ref_CareProductType] WHERE [Code]=[a].[CareProductTypeCode]),'INVALID') END [CareProductTypeCode_Ref]
      ,[ContractUnitCost]
      ,[ContractUnitFrequency]
      ,CASE WHEN [a].[ContractUnitFrequency] IS NULL THEN 'BLANK' ELSE COALESCE((SELECT [Ref_ContractUnitFrequency] FROM [NHSE_Sandbox_CHC].[dbo].[PLDS.Ref_ContractUnitFrequency] WHERE [Code]=[a].[ContractUnitFrequency]),'INVALID') END [ContractUnitFrequency_Ref]
      ,[CommissionedWeeklyHoursOfCare]
      ,a.[Effective_From]
      ,[RecordNumber]
      ,[CHC102UniqID]
      ,a.[OrgIDComm]
      ,a.[UniqSubmissionID]
      ,[UniqServReqID]
      ,[UniqCarePackageID]
      ,[AgeCarePackStartDateYears]
      ,[AgeCarePackEndDateYears]
      ,[PCD_Indicator]
      ,[RecordStartDate]
      ,DATEADD(d,-1,LAG(RecordStartDate,1) OVER(PARTITION BY ServiceRequestID, CarePackageIDCHC ORDER BY RecordStartDate DESC)) [RecordEndDate]
      ,a.[Sub_OrgIDComm] [Sub_OrgID_Comm] 
      ,a.[Der_LoadDate]
      ,a.[Der_FileName]
      ,a.[OrgNameProviderDerived]
      ,a.Token_Person_ID
      ,a.PostcodeProviderDerived

  FROM [NHSE_Sandbox_CHC].[chc].[102_CarePackage] a 
  INNER JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_000_Header_Current] b
  ON a.CHC_Load_ID=b.CHC_Load_ID
  AND a.UniqSubmissionID=b.UniqSubmissionID
