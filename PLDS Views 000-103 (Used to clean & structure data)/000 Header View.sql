-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- View returns latest record per reporting period (re-submissions create duplicates which are all included within the Header table, so view excludes the earlier versions) 
-- View makes accomodations for lower tier submitters (past and present)
-- See comments throughout script for detail of what each section is doing
-- Numbered comments are steps to take when a lower tier submitter migrates to making singular submissions (See How To Guide for more detail on this)
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT 
 a.*
,d.Sub_ICB_Location_Name_Local_Reference AS [Sub_ICB_Name]
,d.Integrated_Care_Board_Name
,d.Region_Code
,d.Region_Name
  FROM (
		SELECT ROW_NUMBER() OVER(PARTITION BY  OrgIDComm, 
											   RPStartDate 
											   ORDER BY  UniqSubmissionID DESC, 
														 CHC_Load_ID	DESC	
								  ) RN
				, * 
				, NULL AS [Lower_Tier_Name]
				FROM [NHSE_Sandbox_CHC].[chc].[000_Header]
				WHERE OrgIDComm IN (
									'00L',	'00N',	'00P',	'00Q',	'00R',	'00T',	'00V',	'00X',	'00Y',	'01A',	'01D',	'01E',	'01F',	'01G',	'01H',	'01J',	'01K',	'01T',	'01V',	'01W',
									'01X',	'01Y',	'02A',	'02E',	'02G',	'02M',	'02P',	'02Q',	'02T',	'02X',	'02Y',	'03F',	'03H',	'03K',	'03L',	'03N',	'03Q',	'03R',	'03W',	'04C',
									'04V',	'04Y',	'05D',	'05G',	'05Q',	'05V',	'05W',	'06H',	'06K',	'06L',	'06N',	'06Q',	'06T',	'07G',	'07H',	'07K',	'09D',	'10Q',	'10R',	'11J',
									'11M',	'11N',	'11X',	'12F',	'13T',	'14L',	'14Y',	'15A',	'15C',	'15E',	'15F',	'15M',	'16C',	'18C',	'26A',	'27D',	'36J',	'42D',	'52R',
									'70F',	'71E',	'78H',	'84H',	'92A',	'93C',	'99A',	'99C',	'99E',	'99F',	'99G',	'M1J4Y', 'M2L0M', 'X2C4Y' )

		UNION ALL   -- Data for Sub ICBs that are currently Lower Tiers

		SELECT ROW_NUMBER() OVER(PARTITION BY  OrgIDComm, 
											   Sub_OrgIDComm,   
											   RPStartDate 
											   ORDER BY  UniqSubmissionID DESC, 
														 CHC_Load_ID	DESC	 
								) RN
			    ,h.* 
				,[Lower_Tier_Name]
		FROM [NHSE_Sandbox_CHC].[chc].[000_Header] h
		LEFT JOIN [dbo].[tbl_CHC_Sub_ICB_Lookup_Table] lt
		ON lt.Lower_Tier_Code = h.Sub_OrgIDComm
		WHERE OrgIDComm IN ('72Q', '91Q', 'D9Y0V', '36L', 'D4U1Y', 'B2M3M')    -- 1 REMOVE LOWER TIERS ONCE MOVED TO SINGULAR 
		AND   Sub_OrgIDComm  IN  (
									'07V',	'08J',	'08P',	'08R',	'08T',	'08X',	-- 36L     -- 2 COPY LOWER TIERS ONCE MOVED TO SINGULAR AND PASTE IN 5, THEN DELETE FROM HERE
									'07N',	'07Q',	'08A',	'08K',	'08L',	'08Q',	-- 72Q
									'09C',	'09E',	'09J',	'10A',	'10E',	'99J',  '09J 09W 10D',  -- 91Q
									'15D',	'99M',	'10C',  -- D4U1Y
									'10L',	'10X',  '10K',	-- D9Y0V
									'05H',  '5MD',  '5M9', '05R' -- B2M3M 
								 )

		UNION  -- Data for Wigan who previously made multiple submissions per Reporting Period

		SELECT ROW_NUMBER() OVER(PARTITION BY UniqSubmissionID
								ORDER BY CHC_Load_ID DESC) RN
			    ,* 
				, NULL AS [Lower_Tier_Name]
		FROM [NHSE_Sandbox_CHC].[chc].[000_Header]
		WHERE OrgIDComm = '02H' 


		UNION ALL   -- Singular data for Sub ICBs (Bath, Devon, East Sussex, Black Country, NW London) who were previously Lower Tiers but moved to singular submissions in 24/25

		SELECT ROW_NUMBER() OVER(PARTITION BY  OrgIDComm, 
											   RPStartDate 
											   ORDER BY  UniqSubmissionID DESC, 
														 CHC_Load_ID	DESC	
								  ) RN
				, * 
				, NULL AS [Lower_Tier_Name]
				FROM [NHSE_Sandbox_CHC].[chc].[000_Header]
				WHERE (OrgIDComm IN ('97R', '15N', '92G') AND RPStartDate >= '2024-04-01')   -- 3 ADD LOWER TIERS THAT HAVE MOVED WITH THE RELEVANT DATE
				OR (OrgIDComm = 'D2P2L' AND RPStartDate >= '2024-06-01')
				OR (OrgIDComm = 'W2U3Z' AND RPStartDate >= '2024-08-01')
				OR (OrgIDComm = 'A3A8R' AND RPStartDate >= '2024-11-01')

		UNION ALL   -- Lower Tier data for Sub ICBs (Bath, Devon, East Sussex, Black Country, NW London) who were previously Lower Tiers but moved to singular submissions in 24/25

		SELECT ROW_NUMBER() OVER(PARTITION BY  OrgIDComm, 
											   Sub_OrgIDComm,
											   RPStartDate 
											   ORDER BY  UniqSubmissionID DESC, 
														 CHC_Load_ID	DESC	 
								) RN
			    ,h.* 
				,[Lower_Tier_Name]
		FROM [NHSE_Sandbox_CHC].[chc].[000_Header] h
		LEFT JOIN [dbo].[tbl_CHC_Sub_ICB_Lookup_Table] lt
		ON lt.Lower_Tier_Code = h.Sub_OrgIDComm
		WHERE (
			   (OrgIDComm IN ('97R', '15N', '92G') AND RPStartDate < '2024-04-01')   -- 4 ADD LOWER TIERS THAT HAVE MOVED WITH THE RELEVANT DATE
		    OR (OrgIDComm = 'D2P2L' AND RPStartDate < '2024-06-01')
			OR (OrgIDComm = 'W2U3Z' AND RPStartDate < '2024-08-01')
			OR (OrgIDComm = 'A3A8R' AND RPStartDate < '2024-11-01')
			  )
		AND   Sub_OrgIDComm  IN  (
									'09F',	'09P',	'99K',	-- 97R    -- 5 PASTE LOWER TIERS FROM 2 HERE
									'99Q',  '99P', -- 15N 
									'07P',	'07W',	'09A',  -- W2U3Z
									'12D',  '99N',  '11E', -- 92G 
									'05L',	'05C',	'05Y',	'06A',	-- D2P2L 
									'07L',	'07T',	'08F',	'08M',	'08N',	'08V',	'08W'	-- A3A8R
								 )

		) a

 LEFT JOIN [NHSE_Sandbox_CHC].[chc].[SubmissionExclusions] b --list of submission IDs to be excluded
 ON a.UniqSubmissionID=b.UniqSubmissionID
 
 LEFT JOIN [NHSE_Sandbox_CHC].[chc].[SubmissionInclusions] c --list of submission IDs to be included
 ON a.UniqSubmissionID=c.UniqSubmissionID

 LEFT JOIN [NHSE_Reference].[dbo].[vw_Ref_ODS_Commissioner_Hierarchies] d
 ON d.Organisation_Code = a.OrgIDComm


 WHERE (RN = 1							   --returns latest submission 
		OR c.UniqSubmissionID IS NOT NULL) --includes records that are in the [SubmissionInclusions] table
 AND b.UniqSubmissionID IS NULL            --removes submission ids included in the [submissionExclusions] table
