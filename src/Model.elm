module Model exposing (..)

import Utils
import Constants exposing (..)

type Action =
    Move Float  -- move n units (backward if negative)
  | Load Float  -- load n units from the nearby tank
  | Fill Float  -- fill n units from the spare tank
  | Pick Float  -- pick a spare tank with n units of fuel
  | Dump        -- dump the spare tank on the ground
  | Stock Float -- (at base) refill the full tank, pick one spare with n units


type alias Rover =
  { pos : Float -- current rover position, clockwise, percent (100 is full circle)
  , dir : Float -- facing direction (1 - right, -1 - left)
  , fuel : Float -- current fuel in tank, percent
  , spare : Float -- amount of fuel in spare tank, percent (no tank when negative)
  , barrels : List (Float, Float) -- list of dumped barrels, (position, amount)
  }


--  initial rover state
init : Rover
init =
  { pos = 0
  , dir = 1
  , fuel = 0
  , spare = -1
  , barrels = []
  }


--  takes n units of fuel from the barrels
takeFuelAt : Float -> Float -> List (Float, Float) -> Maybe (List (Float, Float))
takeFuelAt pos fuel barrels =
  case barrels of
    (bpos, bfuel)::bs ->
      if Utils.isClose (Utils.frac pos) (Utils.frac bpos) && bfuel >= fuel then
        Just ((bpos, bfuel - fuel)::bs)
      else takeFuelAt pos fuel bs |> Maybe.andThen (\b -> Just ((bpos, bfuel)::b))
    _ -> if Utils.isClose pos 0 then (Just barrels) else Nothing


--  moves rover n units (can be negative, to move left)
move : Float -> Rover -> Maybe Rover
move n rover =
  let pos = rover.pos + n
      fuel = rover.fuel - abs(n)*fuelConsumption
  in
    if fuel >= 0 then
      Just {rover | pos = pos, fuel = max fuel 0,
        dir = if n < 0 then -1 else 1}
    else Nothing


--  loads n units of fuel from nearby tank (or base)
load : Float -> Rover -> Maybe Rover
load n rover =
  if rover.fuel + n <= 1 then
    takeFuelAt rover.pos n rover.barrels
    |> Maybe.andThen (\b -> Just {rover | fuel = rover.fuel + n, barrels = b})
  else Nothing


-- fill n units of fuel from the spare tank
fill : Float -> Rover -> Maybe Rover
fill n rover =
  if n <= rover.spare && n + rover.fuel <= 1 then
    Just {rover | spare = rover.spare - n, fuel = rover.fuel + n}
  else Nothing


-- pick a spare tank with n units of fuel
pick : Float -> Rover -> Maybe Rover
pick n rover =
  if Utils.isClose 0 rover.pos && rover.spare < 0 then Just {rover | spare = n }
  else Nothing


--  dump currently carried spare tank
dump : Rover -> Maybe Rover
dump rover =
  if rover.spare >= 0 then
    Just {rover | spare = -1, barrels = (rover.pos, rover.spare)::rover.barrels }
  else Nothing


--  evaluates a state according to an action
evalAction : Action -> Maybe Rover -> Maybe Rover
evalAction action rover =
  rover |> Maybe.andThen (\r ->
    case action of
      Move n -> move n r
      Load n -> load n r
      Fill n -> fill n r
      Pick n -> pick n r
      Stock n -> rover |> evalAction (Pick n) |> evalAction (Load (1 - r.fuel))
      Dump -> dump r)


--  evaluates list of actions from the initial state
evalActions : Maybe Rover -> List Action -> Maybe Rover
evalActions rover actions =
  List.foldl (\a r -> evalAction a r) rover actions


-- computes total fuel used on the route
totalFuel : List Action -> Float
totalFuel actions =
  case actions of
    (Move n)::xs -> abs(n)*fuelConsumption + totalFuel(xs)
    _::xs -> totalFuel(xs)
    _ -> 0


--  plans a route according to the problem
planRoute : List Action
planRoute = [
  Stock 1, Move 0.1, Dump, Move -0.1,
  Stock 1, Move -0.1, Dump, Move 0.1,
  Stock 1, Move 0.1, Load 0.5, Move 0.1, Dump, Move -0.1, Load 0.5, Move -0.1,
  Stock 1, Move -0.1, Load 0.5, Move -0.1, Dump, Move 0.1, Load 0.5, Move 0.1,
  Stock 1, Move 0.1, Dump, Move -0.1,
  Stock 1, Move -0.1, Dump, Move 0.1,
  Stock 1, Move 0.1, Load 0.5, Move 0.1, Load 0.5, Move 0.1, Dump, Move -0.1, Load 0.5, Move -0.1, Load 0.5, Move -0.1,
  Stock 1, Move -0.1, Load 0.5, Move -0.1, Load 0.5, Move -0.1, Dump, Move 0.1, Load 0.5, Move 0.1, Load 0.5, Move 0.1,
  Stock 0.5, Move 0.1, Dump, Move -0.1,
  Stock 0.5, Move -0.1, Dump, Move 0.1,
  Stock 1, Move 0.1, Load 0.5, Move 0.2, Load 1, Move 0.2, Fill 1, Move 0.2, Load 1, Move 0.2, Load 0.5, Move 0.1]
