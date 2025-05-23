/* <begin connected objects> */
/*
This file is auto generated by pgrx.

The ordering of items is not stable, it is driven by a dependency graph.
*/
/* </end connected objects> */

/* <begin connected objects> */
-- pgvectorscale/src/access_method/mod.rs:29
-- vectorscale::access_method::amhandler

    CREATE OR REPLACE FUNCTION diskann_amhandler(internal) RETURNS index_am_handler PARALLEL SAFE IMMUTABLE STRICT COST 0.0001 LANGUAGE c AS '$libdir/vectorscale-0.5.1', 'amhandler_wrapper';

    DO $$
    DECLARE
        c int;
    BEGIN
        SELECT count(*)
        INTO c
        FROM pg_catalog.pg_am a
        WHERE a.amname = 'diskann';

        IF c = 0 THEN
            CREATE ACCESS METHOD diskann TYPE INDEX HANDLER diskann_amhandler;
        END IF;
    END;
    $$;
/* </end connected objects> */

/* <begin connected objects> */
-- pgvectorscale/src/access_method/distance.rs:42
-- vectorscale::access_method::distance::distance_type_cosine
CREATE OR REPLACE FUNCTION "distance_type_cosine"() RETURNS smallint /* i16 */
IMMUTABLE STRICT PARALLEL SAFE
LANGUAGE c /* Rust */
AS '$libdir/vectorscale-0.5.1', 'distance_type_cosine_wrapper';
/* </end connected objects> */

/* <begin connected objects> */
-- pgvectorscale/src/access_method/distance.rs:47
-- vectorscale::access_method::distance::distance_type_l2
CREATE OR REPLACE FUNCTION "distance_type_l2"() RETURNS smallint /* i16 */
IMMUTABLE STRICT PARALLEL SAFE
LANGUAGE c /* Rust */
AS '$libdir/vectorscale-0.5.1', 'distance_type_l2_wrapper';
/* </end connected objects> */

/* <begin connected objects> */
-- pgvectorscale/src/access_method/mod.rs:163
-- requires:
--   amhandler
--   distance_type_cosine
--   distance_type_l2


DO $$
DECLARE
  have_cos_ops int;
  have_l2_ops int;
BEGIN
    -- Has cosine operator class been installed previously?
    SELECT count(*)
    INTO have_cos_ops
    FROM pg_catalog.pg_opclass c
    WHERE c.opcname = 'vector_cosine_ops'
    AND c.opcmethod = (SELECT oid FROM pg_catalog.pg_am am WHERE am.amname = 'diskann')
    AND c.opcnamespace = (SELECT oid FROM pg_catalog.pg_namespace where nspname='@extschema@');

    -- Has L2 operator class been installed previously?
    SELECT count(*)
    INTO have_l2_ops
    FROM pg_catalog.pg_opclass c
    WHERE c.opcname = 'vector_l2_ops'
    AND c.opcmethod = (SELECT oid FROM pg_catalog.pg_am am WHERE am.amname = 'diskann')
    AND c.opcnamespace = (SELECT oid FROM pg_catalog.pg_namespace where nspname='@extschema@');

    IF have_cos_ops = 0 THEN
        -- Fresh install from scratch
        CREATE OPERATOR CLASS vector_cosine_ops DEFAULT
        FOR TYPE vector USING diskann AS
	        OPERATOR 1 <=> (vector, vector) FOR ORDER BY float_ops,
            FUNCTION 1 distance_type_cosine();

        CREATE OPERATOR CLASS vector_l2_ops
        FOR TYPE vector USING diskann AS
            OPERATOR 1 <-> (vector, vector) FOR ORDER BY float_ops,
            FUNCTION 1 distance_type_l2();
    ELSIF have_l2_ops = 0 THEN
        -- Upgrade to add L2 distance support and update cosine opclass to
        -- include the distance_type_cosine function
        INSERT INTO pg_amproc (oid, amprocfamily, amproclefttype, amprocrighttype, amprocnum, amproc)
        SELECT  (select (max(oid)::int + 1)::oid from pg_amproc), c.opcfamily, c.opcintype, c.opcintype, 1, '@extschema@.distance_type_l2'::regproc
        FROM pg_opclass c, pg_am a
        WHERE a.oid = c.opcmethod AND c.opcname = 'vector_cosine_ops' AND a.amname = 'diskann';

        CREATE OPERATOR CLASS vector_l2_ops
        FOR TYPE vector USING diskann AS
            OPERATOR 1 <-> (vector, vector) FOR ORDER BY float_ops,
            FUNCTION 1 distance_type_l2();
    END IF;
END;
$$;
/* </end connected objects> */

