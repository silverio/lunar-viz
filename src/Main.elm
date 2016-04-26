module Main where

import Window
import Signal exposing (..)

import List
import Time exposing (..)

import Model
import View
import Anim exposing (RoverAnim, advance)

import Model exposing (..)
import Constants exposing (..)

port locationSearch : String

type Update = Tick Float

updates : Signal Update
updates =
  mergeMany [ map Tick (Time.every (Time.second*tickTime)) ]


foldUpd : Update -> RoverAnim -> RoverAnim
foldUpd update anim =
  case update of
    Tick _ ->
      case Anim.advance anim tickTime of
        Nothing -> anim
        Just a -> a

main : Signal Element
main =
  map2 View.scene
  (foldp foldUpd Anim.init updates)
  Window.dimensions
