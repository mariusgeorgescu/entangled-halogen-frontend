module AppEnv where

-----------------
-- Env Type
-----------------
-- | The application environment
type Env
  = { buildTxURL :: String
    , submitTxURL :: String
    , allowedNetworkId :: Int
    , myPoolId :: String
    , myDRepHash :: String
    }

--------------------------------------------------------------------------------}
defaultEnv :: Env
defaultEnv =
  { buildTxURL: "/api/delegation-service/build-tx"
  , submitTxURL: "/api/delegation-service/submit-tx"
  , allowedNetworkId: 1 -- Mainnet
  , myPoolId: "pool1sj3gnahsms73uxxu43rgwczdw596en7dtsfcqf6297vzgcedquv"
  , myDRepHash: "70687a06149aafc3c89492b06e743a10a051327371d14f8f95e3c605"
  }

-- { buildTxURL: "/api/delegation-service/build-tx"
-- , submitTxURL: "/api/delegation-service/submit-tx"
-- , allowedNetworkId: 0 -- Preprod
-- , myPoolId: "pool1rr53gk9vaxqhvm0uuvyu4yzcvuc5zxqktvcl39k9swhewvaf7t2"
-- , myDRepHash: "6bec808ca4fae34548a6384e79bf18877914a04b57d5022d56007d1b"
-- }
