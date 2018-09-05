--transaction count
SELECT count(t."Id")
FROM "Transaction" t;

--slaughtering trans count
SELECT count(t."Id")
FROM "Transaction" t
WHERE t."PurposeId" = 1;

--MT trans count
SELECT count(t."Id")
FROM "Transaction" t
WHERE "SourceState" = 'MT';

--MT slaughtering trans count
SELECT count(t."Id")
FROM "Transaction" t
WHERE "SourceState" = 'MT'
AND "PurposeId" = 1;

--PA trans count
SELECT count(t."Id")
FROM "Transaction" t
WHERE "SourceState" = 'PA';

--PA slaughtering trans count
SELECT count(t."Id")
FROM "Transaction" t
WHERE "SourceState" = 'PA'
AND "PurposeId" = 1;

--RO trans count
SELECT count(t."Id")
FROM "Transaction" t
WHERE "SourceState" = 'RO';

--RO slaughtering trans count
SELECT count(t."Id")
FROM "Transaction" t
WHERE "SourceState" = 'RO'
AND "PurposeId" = 1;

--entity count
SELECT count(e."Id")
FROM "Entity" e;

--MT GTA entities
SELECT DISTINCT e."Id"
FROM "Entity" e, "Entity_Transaction" et, "Transaction" t
WHERE e."Id" = et."EntityId"
AND t."Id" = et."TransactionId"
AND t."SourceState" = 'MT';

--PA GTA entities
SELECT DISTINCT e."Id"
FROM "Entity" e, "Entity_Transaction" et, "Transaction" t
WHERE e."Id" = et."EntityId"
AND t."Id" = et."TransactionId"
AND t."SourceState" = 'PA';

--RO GTA entities
SELECT DISTINCT e."Id"
FROM "Entity" e, "Entity_Transaction" et, "Transaction" t
WHERE e."Id" = et."EntityId"
AND t."Id" = et."TransactionId"
AND t."SourceState" = 'RO';

--property count
SELECT count(p."Id")
FROM "Property" p;

--MT props
SELECT count(p."Id")
FROM "Property" p, "Municipality" m
WHERE p."MunicipalId" = m."Id"
AND m."StateAbbr" = 'MT';

--PA props
SELECT count(p."Id")
FROM "Property" p, "Municipality" m
WHERE p."MunicipalId" = m."Id"
AND m."StateAbbr" = 'PA';

--RO props
SELECT count(p."Id")
FROM "Property" p, "Municipality" m
WHERE p."MunicipalId" = m."Id"
AND m."StateAbbr" = 'RO';

--PROPS W/ SHAPEIDS
SELECT DISTINCT p."Id" FROM "Property" p, "Property_Shape" ps
WHERE p."Id" = ps."PropertyId";

--MT PROPS W/ SHAPEIDS
SELECT DISTINCT p."Id" FROM "Property" p, "Property_Shape" ps, "Municipality" m
WHERE p."Id" = ps."PropertyId"
AND p."MunicipalId" = m."Id"
AND m."StateAbbr" = 'MT';

--PA PROPS W/ SHAPEIDS
SELECT DISTINCT p."Id" FROM "Property" p, "Property_Shape" ps, "Municipality" m
WHERE p."Id" = ps."PropertyId"
AND p."MunicipalId" = m."Id"
AND m."StateAbbr" = 'PA';

--RO PROPS W/ SHAPEIDS
SELECT DISTINCT p."Id" FROM "Property" p, "Property_Shape" ps, "Municipality" m
WHERE p."Id" = ps."PropertyId"
AND p."MunicipalId" = m."Id"
AND m."StateAbbr" = 'RO';

--TRANS W/ PROPS W/ SHAPEIDS
SELECT DISTINCT t."Id" 
FROM "Transaction" t, "Property" p, "Transaction_Property" tp, "Property_Shape" ps
WHERE p."Id" = tp."PropertyId"
AND t."Id" = tp."TransactionId"
AND p."Id" = ps."PropertyId";


--% of trans with a mappable selling property per year and state
SELECT matched.state,
       matched.year,
       matched.count::NUMERIC / state_year.count AS selling_coverage
FROM (

    SELECT "state", "year", COUNT(*)
    FROM (
        SELECT DISTINCT
            t."Id",
            t."SourceState" AS "state",
            EXTRACT(YEAR FROM t."EmissaoDate") AS "year"
        FROM "Transaction" t, (
            -- Could be more than one selling Property per txn; get distinct txns
            SELECT DISTINCT tp."TransactionId"
            FROM "Transaction_Property" tp,
                 "Property_Shape" ps
            WHERE tp."RoleId" = 1
              AND tp."PropertyId" = ps."PropertyId"
        ) tids
        WHERE t."Id" = tids."TransactionId"
    ) txn_info_with_mapped_sellers
    GROUP BY "state", "year"
    
) matched, (

    SELECT "state", "year", COUNT(*)
    FROM (
        SELECT DISTINCT
            t."Id",
            t."SourceState" AS "state",
            EXTRACT(YEAR FROM t."EmissaoDate") AS "year"
        FROM "Transaction" t
    ) txn_info
    GROUP BY "state", "year"

) state_year
WHERE matched.state = state_year.state
  AND matched.year = state_year.year
ORDER BY matched.state, matched.year;

--count of trans with >1 selling munic
SELECT COUNT(*) FROM (
    SELECT tm."TransactionId", COUNT(*) FROM (
        SELECT DISTINCT tp."TransactionId", p."MunicipalId"
        FROM "Property" p, "Transaction_Property" tp
        WHERE tp."PropertyId" = p."Id"
          AND tp."RoleId" = 1 -- Seller
    ) tm
    GROUP BY tm."TransactionId"
    HAVING COUNT(*) > 1
) tr;

--count of trans >1 buying munic;
SELECT COUNT(*) FROM (
    SELECT tm."TransactionId", COUNT(*) FROM (
        SELECT DISTINCT tp."TransactionId", p."MunicipalId"
        FROM "Property" p, "Transaction_Property" tp
        WHERE tp."PropertyId" = p."Id"
          AND tp."RoleId" = 2 -- Buyer
    ) tm
    GROUP BY tm."TransactionId"
    HAVING COUNT(*) > 1
) tr;

--% of slaughtering trans with a buying entity to a coded slaughterhouse
SELECT COUNT(*)::NUMERIC / (SELECT COUNT(*) FROM "Transaction" WHERE "PurposeId" = 1) FROM (
    SELECT DISTINCT et."TransactionId"
    FROM "Transaction" t,
         "Entity_Transaction" et,
         "Slaughterhouse_Entity" se,
         "Slaughterhouse_Coding" sc
    WHERE et."RoleId" IN (2, 3) -- Buyer
      AND et."EntityId" = se."EntityId"
      AND se."SlaughterhouseCodingId" = sc."Id"
      AND et."TransactionId" = t."Id"
      AND t."PurposeId" = 1 -- Slaughtering
) coded_slaughtering_transactions;

--MT % slaughtering trans to coded slaughterhouse
SELECT COUNT(*)::NUMERIC / (SELECT COUNT(*) FROM "Transaction" WHERE "PurposeId" = 1 AND "SourceState" = 'MT') FROM (
    SELECT DISTINCT et."TransactionId"
    FROM "Transaction" t,
         "Entity_Transaction" et,
         "Slaughterhouse_Entity" se,
         "Slaughterhouse_Coding" sc
    WHERE et."RoleId" IN (2, 3) -- Buyer
      AND et."EntityId" = se."EntityId"
      AND se."SlaughterhouseCodingId" = sc."Id"
      AND et."TransactionId" = t."Id"
      AND t."PurposeId" = 1 -- Slaughtering
      AND t."SourceState" = 'MT'
) coded_slaughtering_transactions;

--PA % slaughtering trans to coded slaughterhouse
SELECT COUNT(*)::NUMERIC / (SELECT COUNT(*) FROM "Transaction" WHERE "PurposeId" = 1 AND "SourceState" = 'PA') FROM (
    SELECT DISTINCT et."TransactionId"
    FROM "Transaction" t,
         "Entity_Transaction" et,
         "Slaughterhouse_Entity" se,
         "Slaughterhouse_Coding" sc
    WHERE et."RoleId" IN (2, 3) -- Buyer
      AND et."EntityId" = se."EntityId"
      AND se."SlaughterhouseCodingId" = sc."Id"
      AND et."TransactionId" = t."Id"
      AND t."PurposeId" = 1 -- Slaughtering
      AND t."SourceState" = 'PA'
) coded_slaughtering_transactions;

--RO % slaughtering trans to coded slaughterhouse
SELECT COUNT(*)::NUMERIC / (SELECT COUNT(*) FROM "Transaction" WHERE "PurposeId" = 1 AND "SourceState" = 'RO') FROM (
    SELECT DISTINCT et."TransactionId"
    FROM "Transaction" t,
         "Entity_Transaction" et,
         "Slaughterhouse_Entity" se,
         "Slaughterhouse_Coding" sc
    WHERE et."RoleId" IN (2, 3) -- Buyer
      AND et."EntityId" = se."EntityId"
      AND se."SlaughterhouseCodingId" = sc."Id"
      AND et."TransactionId" = t."Id"
      AND t."PurposeId" = 1 -- Slaughtering
      AND t."SourceState" = 'RO'
) coded_slaughtering_transactions;