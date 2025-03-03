--------------------------------------------------------------------------------------------------------------------------------------------------------
-- View calculates the number of days that a care package has been open for and assigns it to the relevant duration bucket.
-- The field 'FinancialYear' is assigned to each record based on the Reporting Period.  
-- WHERE clause excludes closed care packages that are being continually submitted and historic care packages (DQ issues).
-- View is on a 'per Reporting Period' basis. This means that if a Sub ICB misses a submission or a care package record is rejected for a certain 
-- reporting period, the care package(s) will not be counted for that reporting month even if they were open.
-- View feeds the tabs of the Care Package dashboard that are prefixed with 'MONTHLY'. 
--------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT hd.[UniqSubmissionID]			
      ,hd.[OrgIDComm] AS [SubICBCode]		
      ,hd.[Sub_ICB_Name] 	
      ,hd.[ICB_ODS_Code]  AS [ICBCode]				
      ,hd.[Integrated_Care_Board_Name]	AS [ICB_Name]		
      ,hd.[Region_Code]	AS [RegionCode]		
      ,hd.[Region_Name]	AS [RegionName]
      ,hd.[Sub_OrgIDComm] AS [Lower_Tier_Code]			
      ,hd.[Lower_Tier_Name]			
      ,hd.[PrimSystemInUse]	AS [System_Supplier]		
      ,mp.[LocalPatientId]			
      ,mp.[PersonDeathDate]			
      ,ra.[ServiceRequestId]			
      ,ra.[StartDateFunding]			
      ,ra.[EndDateFunding]			
      ,CASE WHEN ra.[EndDateFunding] IS NOT NULL THEN ra.[EndDateFunding] 
			WHEN mp.[PersonDeathDate] IS NOT NULL THEN mp.[PersonDeathDate] 
			END [FundingEndDate] 		
      ,cp.[CarePackageIDCHC]			
	  ,cp.[UniqCarePackageID] 
      ,cp.[UniqCarePackageID] + '-' + mp.[LocalPatientId] AS [CarePackagePatientID]
      ,cp.[StartDateCarePackage]			
      ,cp.[EndDateCarePackage]			
	  ,DATEDIFF(DAY,cp.[StartDateCarePackage],COALESCE(cp.[EndDateCarePackage],[RPEndDate])) AS [CarePackageDuration]		
      ,CASE WHEN cp.[StartDateCarePackage]>[RPEndDate] THEN 'Future'  	
			WHEN DATEDIFF(DAY,cp.[StartDateCarePackage],COALESCE(cp.[EndDateCarePackage],[RPEndDate]))<=92 THEN '0-3 months' 
			WHEN DATEDIFF(DAY,cp.[StartDateCarePackage],COALESCE(cp.[EndDateCarePackage],[RPEndDate]))<=183 THEN '4-6 months' 
			WHEN DATEDIFF(DAY,cp.[StartDateCarePackage],COALESCE(cp.[EndDateCarePackage],[RPEndDate]))<=365 THEN '7-12 months' 
			WHEN DATEDIFF(DAY,cp.[StartDateCarePackage],COALESCE(cp.[EndDateCarePackage],[RPEndDate]))<=730 THEN '13-24 months' 
			ELSE '24+ months' 
			END AS [GroupedCarePackageDuration]
      ,CASE WHEN cp.[EndDateCarePackage] IS NULL THEN 'Open' 			
			WHEN cp.[EndDateCarePackage] > [RPEndDate] THEN 'Open' 
			ELSE 'Closed' 
			END [CarePackageStatus]
	  ,ra.[ActivityTypeCHC] AS [CHCActivityTypeCode]
	  ,ra.[ActivityTypeCHC_Ref] AS [CHCActivityType]
      ,cp.[CareProductTypeCode]	as [CareProductTypeCode]		
      ,cp.[CareProductTypeCode_Ref]	[CareProductType]
	  	  ,cp.[PersonalHealthBudgetTypeCode] AS [PersonalHealthBudgetTypeCode]
	  ,cp.[PersonalHealthBudgetTypeCode_Ref] AS [PersonalHealthBudgetType]	
      ,cp.[RecordStartDate]			
      ,cp.[RecordEndDate] AS [CP_RecordEndDate]			
	  ,ra.[RecordEndDate] AS [RAO_RecordEndDate] 		
	  ,mp.[RecordEndDate] AS [MPI_RecordEndDate]
	  ,hd.[RPStartDate] AS [ReportingDate]
	  ,hd.[RPEndDate] 
	  ,CASE WHEN [RPStartDate] BETWEEN '2022-04-01' AND '2023-03-31' THEN '2022/23'
			WHEN [RPStartDate] BETWEEN '2023-04-01' AND '2024-03-31' THEN '2023/24'
			WHEN [RPStartDate] BETWEEN '2024-04-01' AND '2025-03-31' THEN '2024/25'
			WHEN [RPStartDate] BETWEEN '2025-04-01' AND '2026-03-31' THEN '2025/26'
			END AS [FinancialYear]

FROM [NHSE_Sandbox_CHC].[chc].[vw_reporting_102_CarePackage_Current] cp	

LEFT JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_000_Header_Current] hd			
ON cp.[UniqSubmissionID] = hd.[UniqSubmissionID]	

INNER JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_101_ReferralAssessmentOutcome_Current] ra			
ON cp.[ServiceRequestId] = ra.[ServiceRequestId]			
AND cp.[UniqSubmissionID] = ra.[UniqSubmissionID] 

INNER JOIN [NHSE_Sandbox_CHC].[chc].[vw_reporting_001_MPI_Current] mp			
ON ra.[LocalPatientId] = mp.[LocalPatientId]			
AND ra.[UniqSubmissionID] = mp.[UniqSubmissionID]


WHERE 1=1								
AND (CASE WHEN ra.[EndDateFunding] IS NOT NULL THEN ra.[EndDateFunding] 			
		  WHEN mp.[PersonDeathDate] IS NOT NULL THEN mp.[PersonDeathDate] 	
		  END IS NULL	
	OR CASE WHEN ra.[EndDateFunding] IS NOT NULL THEN ra.[EndDateFunding]    
			WHEN mp.[PersonDeathDate] IS NOT NULL THEN mp.[PersonDeathDate] 
			END > '2022-03-31'  -- Only includes care packages that have been beeing funded since April 2022 onwards and persons not deceased before then
	)
AND (  ([EndDateCarePackage] >= RPStartDate) OR [EndDateCarePackage] IS NULL) -- excludes closed care packages that are being continually submitted
AND NOT (cp.OrgIDComm = '00l' AND RPStartDate < '2023-03-01')
