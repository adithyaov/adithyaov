--------------------------------------------------------------------------------

{-# LANGUAGE Arrows             #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE OverloadedStrings  #-}
{-# LANGUAGE QuasiQuotes        #-}

module Main (main) where

--------------------------------------------------------------------------------
-- Imports
--------------------------------------------------------------------------------

import Control.Monad (filterM)
import Streamly.Unicode.String (str)
import qualified Streamly.Internal.System.Command as Cmd
import Hakyll

--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

config :: Configuration
config =
    defaultConfiguration
        { destinationDirectory = "./docs"
        }

--------------------------------------------------------------------------------
-- Utils
--------------------------------------------------------------------------------

postCtx :: Context String
postCtx = defaultContext <> dateField "date" "%B %e, %Y"

isDraft :: Identifier -> Compiler Bool
isDraft ident = do
  meta <- getMetadata ident
  pure $
       case lookupString "draft" meta of
           Just "true" -> True
           Just "True" -> True
           _ -> False

--------------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------------

-- | Entry point
hakyllMain :: IO ()
hakyllMain = hakyllWith config $ do
    -- Dot images
    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    -- Render each and every post
    match "posts/*.md" $ do
        route   $ setExtension ".html"
        compile $ do
            pandocCompiler
                >>= return . fmap demoteHeaders
                >>= loadAndApplyTemplate "templates/post.html" postCtx
                >>= loadAndApplyTemplate "templates/default.html" defaultContext
                >>= relativizeUrls

    -- Index
    create [ "index.html" ] $ do
        route idRoute
        compile $ do
            posts <-
                loadAll "posts/*"
                    >>= filterM (fmap not . isDraft . itemIdentifier)
                    >>= recentFirst
            let ctx = constField "title" "Index" <>
                      listField "posts" postCtx (return posts) <>
                      defaultContext
            makeItem ""
                >>= loadAndApplyTemplate "templates/post-list.html" ctx
                >>= loadAndApplyTemplate "templates/default.html" ctx
                >>= relativizeUrls

    -- Read templates
    match "templates/*" $ compile $ templateCompiler

    -- Render the 404 page, we don't relativize URL's here.
    match "404.html" $ do
        route idRoute
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext

    match "CNAME" $ do
        route idRoute
        compile copyFileCompiler

main :: IO ()
main = do
    postsDir <- takeWhile (/= '\n') <$> readFile "private/posts-dir.path"
    cmd [str|rm -r ./posts|]
    cmd [str|cp -r #{postsDir} ./posts|]
    hakyllMain
  where
    cmd x = putStrLn x >> Cmd.toStdout x
