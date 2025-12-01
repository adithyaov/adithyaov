--------------------------------------------------------------------------------

{-# LANGUAGE Arrows             #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE OverloadedStrings  #-}
{-# LANGUAGE QuasiQuotes        #-}

module Main (main) where

--------------------------------------------------------------------------------
-- Imports
--------------------------------------------------------------------------------

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
            posts <- recentFirst =<< loadAll "posts/*"
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

main :: IO ()
main = do
  postsDir <- takeWhile (/= '\n') <$> readFile "private/posts-dir.path"
  Cmd.toStdout [str|rm -r ./posts|]
  Cmd.toStdout [str|cp -r #{postsDir} ./posts|]
  hakyllMain
