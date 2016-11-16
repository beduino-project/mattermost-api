{-# LANGUAGE OverloadedStrings #-}
module Main (
  main
) where

import           Data.Text (Text)
import qualified Data.Text as T

import           Control.Monad ( join )
import           Control.Exception

import           System.Exit

import           Text.Show.Pretty ( pPrint )

import           Network.Mattermost
import           Network.Mattermost.Logging
import           Network.Mattermost.Util

data Config
  = Config
  { configUsername :: Text
  , configHostname :: Text
  , configTeam     :: Text
  , configPort     :: Int
  , configPassword :: Text
  , configEmail    :: Text
  }

testConfig :: Config
testConfig = Config
  { configUsername = "test"
  , configEmail    = "test@example.com"
  , configHostname = "localhost"
  , configTeam     = "testteam"
  , configPort     = 8065
  , configPassword = "password"
  }

main :: IO ()
main = do
  _token <- setup `catch` \(SomeException e) -> do
    print e
    exitFailure
  exitSuccess

setup :: IO Token
setup = do
  cd' <- initConnectionDataInsecure (T.unpack (configHostname testConfig))
                                    (fromIntegral (configPort testConfig))
  let newAccount = UsersCreate { usersCreateEmail          = configEmail    testConfig
                               , usersCreatePassword       = configPassword testConfig
                               , usersCreateUsername       = configUsername testConfig
                               , usersCreateAllowMarketing = True
                               }
      cd = cd' `withLogger` mmLoggerDebugErr

  newUser <- mmUsersCreate cd newAccount
  let login = Login { username = configUsername testConfig
                    , password = configPassword testConfig
                    }
  putStrLn "New user created:"
  pPrint newUser
  (token, mmUser) <- join (hoistE <$> mmLogin cd login)
  putStrLn "Authenticated as:"
  pPrint mmUser
  return token