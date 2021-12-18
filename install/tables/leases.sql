CREATE TABLE apps.leases
    ( lease_id NUMBER GENERATED ALWAYS AS IDENTITY
    , asset_id NUMBER
    , lease_inception_date DATE
    , lease_expiration_date DATE
    , asset_life NUMBER
    , num_payments_made NUMBER
    );
