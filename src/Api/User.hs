{-# LANGUAGE DataKinds                  #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE TypeOperators              #-}

module Api.User where

import           Control.Monad.Except
import           Control.Monad.Reader        (ReaderT, runReaderT)
import           Control.Monad.Reader.Class
import           Data.Int                    (Int64)
import           Database.Persist.Postgresql (Entity (..), fromSqlKey, insert,
                                              selectFirst, selectList, (==.))
import           Network.Wai                 (Application)
import           Servant
import           Servant.JS                  (vanillaJS, writeJSForAPI)

import           Config                      (AppT (..), Config (..))
import           Models
import           Data.Text (Text)

type UserAPI =
         "users" :> Get '[JSON] [Entity User]
    :<|> "users" :> Capture "name" Text :> Get '[JSON] (Entity User)
    :<|> "users" :> ReqBody '[JSON] User :> Post '[JSON] Int64

-- | The server that runs the UserAPI
userServer :: MonadIO m => ServerT UserAPI (AppT m)
userServer = allUsers :<|> singleUser :<|> createUser

-- | Returns all users in the database.
allUsers :: MonadIO m => AppT m [Entity User]
allUsers =
    runDb (selectList [] [])

-- | Returns a user by name or throws a 404 error.
singleUser :: MonadIO m => Text -> AppT m (Entity User)
singleUser str = do
    maybeUser <- runDb (selectFirst [UserName ==. str] [])
    case maybeUser of
         Nothing ->
            throwError err404
         Just person ->
            return person

-- | Creates a user in the database.
createUser :: MonadIO m => User -> AppT m Int64
createUser p = do
    newUser <- runDb (insert (User (userName p) (userEmail p)))
    return $ fromSqlKey newUser

-- | Generates JavaScript to query the User API.
generateJavaScript :: IO ()
generateJavaScript =
    writeJSForAPI (Proxy :: Proxy UserAPI) vanillaJS "./assets/api.js"
