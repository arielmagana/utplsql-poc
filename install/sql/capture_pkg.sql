CREATE OR REPLACE PACKAGE apps.capture_pkg
AS
    
    PROCEDURE capture_asset
        ( p_asset_id NUMBER
        , p_accounting_date DATE
        );
END capture_pkg;
/

CREATE OR REPLACE PACKAGE BODY apps.capture_pkg
AS
    --==[Private procedures]==--
    PROCEDURE insert_lease
        ( p_lease_record leases%ROWTYPE
        ) IS
    BEGIN
        INSERT INTO leases
            ( asset_id
            , lease_inception_date
            , lease_expiration_date
            , asset_life
            , num_payments_made
            )
        VALUES
            ( p_lease_record.asset_id
            , p_lease_record.lease_inception_date
            , p_lease_record.lease_expiration_date
            , p_lease_record.asset_life
            , p_lease_record.num_payments_made
            );
    END insert_lease;

    FUNCTION calculate_asset_life
        ( p_accounting_date        DATE
        , p_date_placed_in_service DATE
        , p_life_in_months         NUMBER
        ) RETURN NUMBER IS

        l_return_value NUMBER;
        l_months_left  NUMBER;
    BEGIN
        l_months_left := MONTHS_BETWEEN(p_accounting_date, p_date_placed_in_service);
        l_return_value := p_life_in_months - l_months_left;
        RETURN l_return_value;
    END calculate_asset_life;

    --==[Public procedures]==--
    PROCEDURE capture_asset
        ( p_asset_id        NUMBER
        , p_accounting_date DATE
        ) IS

        l_assert_rec asset_balances%ROWTYPE;
        l_lease_rec  leases%ROWTYPE;
    BEGIN
        
        BEGIN
            SELECT *
            INTO   l_assert_rec
            FROM   asset_balances
            WHERE  asset_id = p_asset_id
            ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                raise_application_error(-20001, 'Asset id '||p_asset_id|| ' doesn''t exist');
        END;

        l_lease_rec.asset_id := p_asset_id;
        l_lease_rec.lease_inception_date := p_accounting_date;
        l_lease_rec.asset_life := calculate_asset_life
                                    ( p_accounting_date
                                    , l_assert_rec.date_placed_in_service
                                    , l_assert_rec.life_in_months
                                    );
        l_lease_rec.lease_expiration_date := p_accounting_date + l_lease_rec.asset_life;

        insert_lease(l_lease_rec);
    END capture_asset;
END capture_pkg;
/
