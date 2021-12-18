CREATE OR REPLACE PACKAGE test_capture_pkg
AS
    --%suite(Capture)

    PROCEDURE insert_test_asset;

    --%test(Run capture for nonexistent asset)
    --%throws(-20001)
    PROCEDURE capture_nonexistent_asset;

    --%test(Run capture for valid asset)
    --%beforetest(insert_test_asset)
    PROCEDURE capture_asset;
END test_capture_pkg;
/

CREATE OR REPLACE PACKAGE BODY test_capture_pkg
AS

    PROCEDURE insert_test_asset
    IS
    BEGIN
        dbms_output.put_line('Inserting test asset');

        INSERT INTO asset_balances
            ( asset_id
            , date_placed_in_service
            , life_in_months
            , book_cost
            , units
            , ltd_depreciation
            )
        VALUES
            ( -1
            , TO_DATE('4/22/2021', 'MM/DD/YYYY')
            , 120
            , 10000
            , 10
            , 300
            );
    END insert_test_asset;

    PROCEDURE capture_nonexistent_asset
    IS
    BEGIN
        capture_pkg.capture_asset(-99999, TO_DATE('6/30/2021', 'MM/DD/YYYY'));
    END;

    PROCEDURE capture_asset
    IS
        l_lease_rec leases%ROWTYPE;
    BEGIN
        --Run capture
        capture_pkg.capture_asset(-1, TO_DATE('6/30/2021', 'MM/DD/YYYY'));

        --Get lease information for validation
        BEGIN
            SELECT *
            INTO   l_lease_rec
            FROM   leases
            WHERE  asset_id = -1
            ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                l_lease_rec := NULL;
        END;

        ut.expect(l_lease_rec.asset_id).to_equal(-1);
        ut.expect(l_lease_rec.lease_inception_date, 'Lease inception date is the first day of the accounting month').to_equal(TO_DATE('6/1/2021', 'MM/DD/YYYY'));
        ut.expect(l_lease_rec.asset_life, 'Asset life is how much of life is months is left between date place and running month').to_equal(118);
        ut.expect(l_lease_rec.lease_expiration_date, 'Expiration date based on asset life').to_equal(TO_DATE('4/30/2031', 'MM/DD/YYYY'));

    END;
END test_capture_pkg;
/
