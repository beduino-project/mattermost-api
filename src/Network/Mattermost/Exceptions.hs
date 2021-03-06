{-# LANGUAGE DeriveDataTypeable #-}
module Network.Mattermost.Exceptions
( -- Exception Types
  LoginFailureException(..)
, URIParseException(..)
, ContentTypeException(..)
, JSONDecodeException(..)
, HeaderNotFoundException(..)
, HTTPResponseException(..)
, ConnectionException(..)
, MattermostServerError(..)
) where

import qualified Data.Text as T
import           Data.Typeable ( Typeable )
import           Control.Exception ( Exception(..) )
import           Network.Stream ( ConnError )

--

-- Unlike many exceptions in this file, this is a mattermost specific exception
data LoginFailureException = LoginFailureException String
  deriving (Show, Typeable)

instance Exception LoginFailureException

--

data URIParseException = URIParseException String
  deriving (Show, Typeable)

instance Exception URIParseException

--

data ContentTypeException = ContentTypeException String
  deriving (Show, Typeable)

instance Exception ContentTypeException

--

data JSONDecodeException
  = JSONDecodeException
  { jsonDecodeExceptionMsg  :: String
  , jsonDecodeExceptionJSON :: String
  } deriving (Show, Typeable)

instance Exception JSONDecodeException

--

data HeaderNotFoundException = HeaderNotFoundException String
  deriving (Show, Typeable)

instance Exception HeaderNotFoundException

--

data MattermostServerError = MattermostServerError T.Text
  deriving (Show, Typeable)

instance Exception MattermostServerError

--

data HTTPResponseException = HTTPResponseException String
  deriving (Show, Typeable)

instance Exception HTTPResponseException

--

data ConnectionException = ConnectionException ConnError
 deriving (Show, Typeable)

instance Exception ConnectionException
