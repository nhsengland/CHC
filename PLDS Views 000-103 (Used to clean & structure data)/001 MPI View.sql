----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INNER JOIN on [chc].[vw_000_Header_Current] returns latest record per reporting period (re-submissions create duplicates which are all within the Header table, so view excludes the earlier versions) 
-- View also creates calculation of RecordEndDate based on the following record's RecordStartDate (RecordEndDate = NULL indicates the latest record)
-- Descriptive columns brought in from relevant reference tables [NHSE_Sandbox_CHC].[dbo].[PLDS.Ref_] 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT a.[CHC_Load_ID]
      ,[LocalPatientId]
      ,[OrgIDLocalPatientId]
      ,[NHSNumberStatus]
      ,CASE WHEN [a].[NHSNumberStatus] IS NULL THEN 'BLANK' ELSE COALESCE((SELECT [Ref_NHSNumberStatus] FROM [NHSE_Sandbox_CHC].[dbo].[PLDS.Ref_NHSNumberStatus] WHERE [Code]=[a].[NHSNumberStatus]),'INVALID') END [NHSNumberStatus_Ref]
      ,[Gender]
      ,CASE WHEN [a].[Gender] IS NULL THEN 'BLANK' ELSE COALESCE((SELECT [Ref_Gender] FROM [NHSE_Sandbox_CHC].[dbo].[PLDS.Ref_Gender] WHERE [Code]=[a].[Gender]),'INVALID') END [Gender_Ref]
      ,[EthnicCategory]
      ,CASE WHEN [a].[EthnicCategory] IS NULL THEN 'BLANK' ELSE COALESCE((SELECT [Ref_EthnicCategory] FROM [NHSE_Sandbox_CHC].[dbo].[PLDS.Ref_EthnicCategory] WHERE [Code]=[a].[EthnicCategory]),'INVALID') END [EthnicCategory_Ref]
      ,[PersonDeathDate]
      ,a.[Effective_From]
      ,[RecordNumber]
      ,[CHC001UniqID]
      ,a.[OrgIDComm]
      ,[OrgIDCCGRes]
      ,a.[UniqSubmissionID]
      ,[ValidNHSNumber_Flag]
      ,[ValidPostcode_Flag]
      ,[AgeRepPeriodStartYears]
      ,[AgeRepPeriodEndYears]
      ,[AgeDeathYears]
      ,[PostcodeDistrict]
      ,[LSOAResidence2011]
      ,[LADistrictAuth]
      ,[County]
      ,[ElectoralWard]
      ,[NHSDEthnicity]
      ,[PatMRecInRP]
      ,[IMDQuart]
      ,[Reg_GP_Current]
      ,[LSOARegistration2011]
      ,[LARegistration]
      ,[OrgIDCCGGP]
      ,[OrgIDSubICBLocGP]
      ,[OrgIDSubICBLocRes]
      ,[OrgIDICBRes]
      ,[OrgIDICBGP]
      ,[SexualOrientation]
      ,CASE WHEN [a].[SexualOrientation] IS NULL THEN 'BLANK' ELSE COALESCE((SELECT [Ref_SexualOrientation] FROM [NHSE_Sandbox_CHC].[dbo].[PLDS.Ref_SexualOrientation] WHERE [Code]=[a].[SexualOrientation]),'INVALID') END [SexualOrientation_Ref]
      ,[ReligionCHC]
      ,CASE WHEN [a].[ReligionCHC] IS NULL THEN 'BLANK' ELSE COALESCE((SELECT [Ref_Religion] FROM [NHSE_Sandbox_CHC].[dbo].[PLDS.Ref_Religion] WHERE [Code]=[a].[ReligionCHC]),'INVALID') END [ReligionCHC_Ref]
      ,[RecordStartDate]
      ,DATEADD(d,-1,LAG(RecordStartDate,1) OVER(PARTITION BY LocalPatientID ORDER BY RecordStartDate DESC)) [RecordEndDate]
      ,a.[Sub_OrgIDComm] [Sub_OrgID_Comm]
      ,[Der_Pseudo_NHS_Number]
      ,[Der_Postcode_Sector]
      ,[Der_Postcode_CCG_Code]
      ,[PCD_Indicator]
      ,a.[Der_LoadDate]
      ,a.[Der_FileName]
      ,[PostcodeGP]
      ,a.[Token_Person_ID]
  FROM [NHSE_Sandbox_CHC].[chc].[001_MPI] a 
  INNER JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_000_Header_Current] b --
  ON a.CHC_Load_ID=b.CHC_Load_ID
  AND a.UniqSubmissionID=b.UniqSubmissionID
