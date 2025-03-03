--------------------------------------------------------------------------------------------------------------------------------------------------------
-- View selects the latest care package record per Financial Year from the Care Package view. This can be used to count the number of open care
-- packages per Financial Year.
-- View feeds the tabs of the Care Package dashboard that are prefixed with 'FY'. 
--------------------------------------------------------------------------------------------------------------------------------------------------------	

SELECT  a.*
FROM (
		SELECT ROW_NUMBER() OVER(PARTITION BY CarePackagePatientID, FinancialYear	ORDER BY  ReportingDate DESC) AS RN
			  , * 
	    FROM [NHSE_Sandbox_CHC].[dbo].[vw_PLDS_CarePackage]

	  ) a

WHERE RN = 1
