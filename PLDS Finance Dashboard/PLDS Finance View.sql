--------------------------------------------------------------------------------------------------------------------------------------------------------
-- View calculates the number of days that a care package was open during each Reporting Period (month) in which it was submitted.
-- This duration field is then used to calculate the cost per reporting period with the formula dependent on the [ContractUnitFrequency]. 
-- See WHERE clause for exclusions to the data.
-- Providers, Subjective codes and Cost centre codes are pulled in from reference tables.
-- Since the cost is calculated per reporting period, if a submission has been missed or key fields such as [ContractUnitFrequency], [ContractUnitCost]
-- or [CommissionedWeeklyHoursOfCare] are incorrect/incomplete/missing, it will affect a Sub ICB’s cumulative YTD Total Cost figure.
--------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT			
h.[RPStartDate]
,h.[RPEndDate]
,p.[Quarter]
,h.[PrimSystemInUse]
,h.[OrgIDComm] AS [Sub_ICB_Code]
,h.[ICB_ODS_Code] AS [ICB_Code]
,[CarePackageIDCHC]
,cp.[ServiceRequestId]
,[UniqCarePackageID] + '-' + [LocalPatientId] AS CarePackagePatientID
,[StartDateCarePackage]
,[EndDateCarePackage]
,[ActivityTypeCHC]
,[ActivityTypeCHC_Ref]
,[PersonalHealthBudgetTypeCode]
,[OrgIDProvider]
,RefH.[NHSE_Organisation_Type] AS [Provider_Type]
,cp.[CostCentreCode]
,cc.CostCentreCode AS [cc_CostCentreCode]
,cc.CostCentreCodeDescription AS [cc_CostCentreCodeDesc]
,cch.CostCentreCode AS [cch_CostCentreCode]
,cch.CostCentreCodeDescription AS [cch_CostCentreCodeDesc]
,cp.[SubjectiveCode]
,[SubjectiveCodeDesc]
,[CareProductTypeCode]
,[CareProductTypeCode_Ref]
,CAST([ContractUnitCost] AS NUMERIC) AS [ContractUnitCost] --so can sum later one - doesn't like being an INT but NUMERIC works fine
,[ContractUnitFrequency]
,[ContractUnitFrequency_Ref]
,CAST([CommissionedWeeklyHoursOfCare] AS NUMERIC) AS [CommissionedWeeklyHoursOfCare]
,cp.[UniqSubmissionID]
,cp.[Sub_OrgID_Comm] AS [Lower_Tier_Code]
,h.[Sub_ICB_Name] 
,h.[Integrated_Care_Board_Name] AS [ICB_Name]
,h.[Region_Name]
,cp.OrgNameProviderDerived AS Provider_Name
,[UniqCarePackageID]

--**QUESTION** - how to deal with contract frequency type 5 'Other' - use contract unit cost or exclude and caveat? 120 records with this code.

,CAST(CASE WHEN EndDateCarePackage IS NULL THEN DATEDIFF(DAY,CASE WHEN StartDateCarePackage < RPStartDate THEN RPStartDate 
																  ELSE StartDateCarePackage 
																  END,
														 h.RPEndDate)
		   WHEN EndDateCarePackage > h.RPEndDate THEN DATEDIFF(DAY,CASE WHEN StartDateCarePackage < RPStartDate THEN RPStartDate 
																	  ELSE StartDateCarePackage 
																	  END,
															 h.RPEndDate)
		   ELSE DATEDIFF(DAY,CASE WHEN StartDateCarePackage < RPStartDate THEN RPStartDate 
								  ELSE StartDateCarePackage 
								  END,
						 EndDateCarePackage) 
		   END AS DECIMAL) +1 AS [Days_Open_During_RP]

FROM [NHSE_Sandbox_CHC].[chc].[vw_reporting_102_CarePackage_Current] cp

LEFT JOIN [chc].[vw_reporting_101_ReferralAssessmentOutcome_Current] rao
ON cp.UniqSubmissionID = rao.UniqSubmissionID AND cp.ServiceRequestId = rao.ServiceRequestId

LEFT OUTER JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_000_Header_Current] h
ON cp.UniqSubmissionID = h.UniqSubmissionID

LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Provider_Hierarchies] RefH
ON cp.OrgIDProvider = RefH.Organisation_Code

LEFT JOIN [NHSE_Sandbox_CHC].[dbo].[tbl_Period_Lookup_PLDS_temp] p
ON h.RPEndDate = p.RPEndDate

LEFT JOIN [dbo].[PLDS.Ref_SubjectiveCodes] sc 
ON cp.SubjectiveCode = sc.SubjectiveCode

LEFT JOIN [dbo].[PLDS.Ref_CostCentreCodes] cc  -- July 22 onwards cost centre codes 
ON RIGHT(cp.CostCentreCode,3) = cc.CostCentreCode

LEFT JOIN [dbo].[PLDS.Ref_CostCentreCodes] cch   -- historic (CCG) cost centre codes 
ON RIGHT(cp.CostCentreCode,2) = cch.CostCentreCode

WHERE

(EndDateCarePackage >= h.RPStartDate OR EndDateCarePackage IS NULL) -- include open care packages only

AND StartDateCarePackage <= h.RPEndDate  -- exclude care packages opening in future

AND NOT (cp.OrgIDComm = '00l' AND RPStartDate < '2023-03-01')  -- exclude Northumberland poor DQ 

)


SELECT [RPStartDate]
	  ,[RPEndDate]
	  ,[Quarter]
      ,[PrimSystemInUse]
      ,[Sub_ICB_Code]
      ,[ServiceRequestId]
      ,[CarePackageIDCHC]
	  ,[UniqCarePackageID]
	  ,[CarePackagePatientID]
      ,[StartDateCarePackage]
      ,[EndDateCarePackage]
	  ,[ActivityTypeCHC]
	  ,[ActivityTypeCHC_Ref]
      ,[PersonalHealthBudgetTypeCode]
      ,[OrgIDProvider]
	  ,CASE WHEN [Provider_Type] IS NULL AND [OrgIDProvider] IS NULL THEN 'Blank'
			WHEN [Provider_Type] IS NULL AND [OrgIDProvider] IS NOT NULL THEN 'Unknown'
			ELSE [Provider_Type]
			END AS [Provider_Type]
	  ,[Provider_Name]
      ,[CostCentreCode]
	  ,CASE WHEN [cc_CostCentreCode] IS NOT NULL THEN cc_CostCentreCodeDesc
			WHEN [cch_CostCentreCode] IS NOT NULL THEN cch_CostCentreCodeDesc
			WHEN [CostCentreCode] IS NOT NULL AND cc_CostCentreCodeDesc IS NULL AND cch_CostCentreCodeDesc IS NULL THEN 'INVALID'
			ELSE 'BLANK'
			END AS [CostCentreCodeDesc]
	  ,CASE WHEN [cch_CostCentreCode] IS NOT NULL THEN 'H'
			WHEN [cc_CostCentreCode] IS NOT NULL THEN 'C'
			ELSE NULL
			END AS [HistoricCostCentreFlag]
      ,[SubjectiveCode]
	  ,CASE WHEN SubjectiveCodeDesc IS NOT NULL THEN SubjectiveCodeDesc
			WHEN SubjectiveCode IS NOT NULL AND SubjectiveCodeDesc IS NULL THEN 'INVALID'
			ELSE 'BLANK'
			END AS [SubjectiveCodeDesc]
      ,[CareProductTypeCode]
	  ,[CareProductTypeCode_Ref] 
      ,[ContractUnitCost]
	  ,[ContractUnitFrequency]
      ,[ContractUnitFrequency_Ref]
      ,[CommissionedWeeklyHoursOfCare]
      ,[UniqSubmissionID]
      ,[Sub_ICB_Name]
	  ,[Lower_Tier_Code]
	  ,[ICB_Code]
      ,[ICB_Name]
	  ,[Region_Name]				
      ,[Days_Open_During_RP]
	, ROUND(CASE WHEN [ContractUnitFrequency] = 1 AND StartDateCarePackage BETWEEN RPStartDate AND RPEndDate THEN [ContractUnitCost] 
				 WHEN [ContractUnitFrequency] = 2 THEN SUM([ContractUnitCost]) * SUM([CommissionedWeeklyHoursOfCare]) * SUM([Days_Open_During_RP]/7) 
--				 WHEN [ContractUnitFrequency] = 3 AND (CommissionedWeeklyHoursOfCare IS NULL OR CommissionedWeeklyHoursOfCare = 0) THEN SUM([ContractUnitCost]) * SUM([Days_Open_During_RP]) 
				 WHEN [ContractUnitFrequency] = 3 THEN SUM([ContractUnitCost]) * SUM([CommissionedWeeklyHoursOfCare]/24) * SUM([Days_Open_During_RP]/7) 
				 WHEN [ContractUnitFrequency] = 4 THEN SUM([ContractUnitCost]) * SUM([Days_Open_During_RP]/7) 
				 ELSE 0
			END,2) AS [Total_Package_Cost]
	  ,[CommissionedWeeklyHoursOfCare]/24 AS CommissionedWeeklyDAYSOfCare  -- working column used for checking above formulas
	  ,[Days_Open_During_RP]/7 AS [Weeks_Open_During_RP]   -- working column used for checking above formulas

FROM a

GROUP BY 
       [RPStartDate]
	  ,[RPEndDate]
	  ,[Quarter]
      ,[PrimSystemInUse]
      ,[Sub_ICB_Code]
      ,[ICB_Code]
      ,[CarePackageIDCHC]
      ,[ServiceRequestId]
	  ,[UniqCarePackageID]
	  ,[CarePackagePatientID]
      ,[StartDateCarePackage]
      ,[EndDateCarePackage]
	  ,[ActivityTypeCHC]
	  ,[ActivityTypeCHC_Ref]
      ,[PersonalHealthBudgetTypeCode]
      ,[OrgIDProvider]
	  ,CASE WHEN [Provider_Type] IS NULL AND [OrgIDProvider] IS NULL THEN 'Blank'
			WHEN [Provider_Type] IS NULL AND [OrgIDProvider] IS NOT NULL THEN 'Unknown'
			ELSE [Provider_Type]
			END 
      ,[CostCentreCode]
	  ,CASE WHEN [cc_CostCentreCode] IS NOT NULL THEN cc_CostCentreCodeDesc
			WHEN [cch_CostCentreCode] IS NOT NULL THEN cch_CostCentreCodeDesc
			WHEN [CostCentreCode] IS NOT NULL AND cc_CostCentreCodeDesc IS NULL AND cch_CostCentreCodeDesc IS NULL THEN 'INVALID'
			ELSE 'BLANK'
			END 
	  ,CASE WHEN [cch_CostCentreCode] IS NOT NULL THEN 'H'
			WHEN [cc_CostCentreCode] IS NOT NULL THEN 'C'
			ELSE NULL
			END 
      ,[SubjectiveCode]
	  ,CASE WHEN SubjectiveCodeDesc IS NOT NULL THEN SubjectiveCodeDesc
			WHEN SubjectiveCode IS NOT NULL AND SubjectiveCodeDesc IS NULL THEN 'INVALID'
			ELSE 'BLANK'
			END 
      ,[CareProductTypeCode]
	  ,[CareProductTypeCode_Ref] 
      ,[ContractUnitCost]
	  ,[ContractUnitFrequency]
      ,[ContractUnitFrequency_Ref]
      ,[CommissionedWeeklyHoursOfCare]
      ,[UniqSubmissionID]
      ,[Lower_Tier_Code]
      ,[Sub_ICB_Name]
      ,[ICB_Name]
	  ,[Region_Name]				
      ,[Provider_Name]
      ,[Days_Open_During_RP]
	  ,ROUND([CommissionedWeeklyHoursOfCare]/24,2) 
	  ,[Days_Open_During_RP]/7
