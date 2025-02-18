SELECT  a.*
FROM (
		SELECT ROW_NUMBER() OVER(PARTITION BY CarePackagePatientID, FinancialYear	ORDER BY  ReportingDate DESC) AS RN
			  , * 
	    FROM [NHSE_Sandbox_CHC].[dbo].[vw_PLDS_CarePackage]

	  ) a

WHERE RN = 1
