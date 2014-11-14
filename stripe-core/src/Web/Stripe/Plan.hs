{-# LANGUAGE OverloadedStrings #-}
-------------------------------------------
-- |
-- Module      : Web.Stripe.Plan
-- Copyright   : (c) David Johnson, 2014
-- Maintainer  : djohnson.m@gmail.com
-- Stability   : experimental
-- Portability : POSIX
--
-- < https:/\/\stripe.com/docs/api#plans >
--
-- @
-- import Web.Stripe
-- import Web.Stripe.Plan
--
-- main :: IO ()
-- main = do
--   let config = SecretKey "secret_key"
--   result <- stripe config $ do
--       createPlan (PlanId "free plan")
--                  (0 :: Amount)
--                  (USD :: Currency)
--                  (Month :: Interval)
--                  ("a sample free plan" :: Name)
--                  ([] :: MetaData)
--   case result of
--     Right plan     -> print plan
--     Left stripeError -> print stripeError
-- @
module Web.Stripe.Plan
    ( -- * API
      createPlan
    , createPlanIntervalCount
    , createPlanTrialPeriodDays
    , createPlanBase
    , getPlan
    , getPlans
    , updatePlanName
    , updatePlanDescription
    , updatePlanBase
    , deletePlan
      -- * Types
    , PlanId             (..)
    , Plan               (..)
    , Interval           (..)
    , StripeList         (..)
    , IntervalCount      (..)
    , TrialPeriodDays    (..)
    , StripeDeleteResult (..)
    , Currency           (..)
    , Limit
    , StartingAfter
    , EndingBefore
    , Name
    , Amount
    , Description
    , MetaData
    ) where

import           Web.Stripe.Client.Types   (Method(POST, GET, DELETE),
                                            StripeRequest(..), mkStripeRequest)
import           Web.Stripe.Client.Util    ( toText, getParams, toMetaData,
                                             toTextLower, (</>))
import           Web.Stripe.Types (PlanId (..) , Plan (..), Interval (..), StripeList(..),
                                   IntervalCount (..), TrialPeriodDays (..), Limit,
                                   StartingAfter, EndingBefore, StripeDeleteResult(..),
                                   Currency (..), Name, Amount, Description, MetaData)

------------------------------------------------------------------------------
-- | Base Request for creating a 'Plan', useful for making custom `Plan` creation requests
createPlanBase
    :: PlanId                -- ^ Unique string used to identify `Plan`
    -> Amount                -- ^ Positive integer in cents representing how much to charge on a recurring basis
    -> Currency              -- ^ `Currency` of `Plan`
    -> Interval              -- ^ Billing Frequency (i.e. `Day`, `Week` or `Month`)
    -> Name                  -- ^ Name of `Plan` to be displayed on `Invoice`s
    -> Maybe IntervalCount   -- ^ Number of intervals between each `Subscription` billing, default 1
    -> Maybe TrialPeriodDays -- ^ Integer number of days a trial will have
    -> Maybe Description     -- ^ An arbitrary string to be displayed on `Customer` credit card statements
    -> MetaData              -- ^ `MetaData` for the `Plan`
    -> StripeRequest Plan
createPlanBase
    (PlanId planid)
    amount
    currency
    interval
    name
    intervalCount
    trialPeriodDays
    description
    metadata    = request
  where request = mkStripeRequest POST url params
        url     = "plans"
        params  = toMetaData metadata ++ getParams [
                     ("id", Just planid)
                   , ("amount", toText `fmap` Just amount)
                   , ("currency", toTextLower `fmap` Just currency)
                   , ("interval", toText `fmap` Just interval)
                   , ("name", Just name)
                   , ("interval_count", (\(IntervalCount x) -> toText x) `fmap` intervalCount )
                   , ("trial_period_days", (\(TrialPeriodDays x) -> toText x) `fmap` trialPeriodDays )
                   , ("statement_description", description )
                 ]

------------------------------------------------------------------------------
-- | Create a `Plan`
createPlan
    :: PlanId        -- ^ Unique string used to identify `Plan`
    -> Amount        -- ^ Positive integer in cents (or 0 for a free plan) representing how much to charge on a recurring basis
    -> Currency      -- ^ `Currency` of `Plan`
    -> Interval      -- ^ Billing Frequency
    -> Name          -- ^ Name of `Plan` to be displayed on `Invoice`s
    -> MetaData      -- ^ MetaData for the Plan
    -> StripeRequest Plan
createPlan
    planid
    amount
    currency
    intervalCount
    name = createPlanBase planid amount currency intervalCount name Nothing Nothing Nothing

------------------------------------------------------------------------------
-- | Create a `Plan` with a specified `IntervalCount`
createPlanIntervalCount
    :: PlanId        -- ^ Unique string used to identify `Plan`
    -> Amount        -- ^ Positive integer in cents (or 0 for a free plan) representing how much to charge on a recurring basis
    -> Currency      -- ^ `Currency` of `Plan`
    -> Interval      -- ^ Billing Frequency
    -> Name          -- ^ Name of `Plan` to be displayed on `Invoice`s
    -> IntervalCount -- ^ # of billins between each `Subscription` billing
    -> StripeRequest Plan
createPlanIntervalCount
    planid
    amount
    currency
    interval
    name
    intervalCount = createPlanBase planid amount
                    currency interval name
                    (Just intervalCount) Nothing Nothing []

------------------------------------------------------------------------------
-- | Create a `Plan` with a specified number of `TrialPeriodDays`
createPlanTrialPeriodDays
    :: PlanId          -- ^ Unique string used to identify `Plan`
    -> Amount          -- ^ Positive integer in cents (or 0 for a free plan) representing how much to charge on a recurring basis
    -> Currency        -- ^ `Currency` of `Plan`
    -> Interval        -- ^ Billing Frequency
    -> Name            -- ^ Name of `Plan` to be displayed on `Invoice`s
    -> TrialPeriodDays -- ^ Number of Trial Period Days to be displayed on `Invoice`s
    -> StripeRequest Plan
createPlanTrialPeriodDays
    planid
    amount
    currency
    interval
    name
    trialPeriodDays =
        createPlanBase
          planid
          amount
          currency
          interval
          name
          Nothing
          (Just trialPeriodDays)
          Nothing
          []

------------------------------------------------------------------------------
-- | Retrieve a `Plan`
getPlan
    :: PlanId -- ^ The ID of the plan to retrieve
    -> StripeRequest Plan
getPlan
    (PlanId planid) = request
  where request = mkStripeRequest GET url params
        url     = "plans" </> planid
        params  = []

------------------------------------------------------------------------------
-- | Retrieve a `Plan`
getPlans
    :: Limit                -- ^ Defaults to 10 if `Nothing` specified
    -> StartingAfter PlanId -- ^ Paginate starting after the following `CustomerID`
    -> EndingBefore PlanId  -- ^ Paginate ending before the following `CustomerID`
    -> StripeRequest (StripeList Plan)
getPlans
    limit
    startingAfter
    endingBefore = request
  where request = mkStripeRequest GET url params
        url     = "plans"
        params  = getParams [
            ("limit", toText `fmap` limit )
          , ("starting_after", (\(PlanId x) -> x) `fmap` startingAfter)
          , ("ending_before", (\(PlanId x) -> x) `fmap` endingBefore)
          ]

------------------------------------------------------------------------------
-- | Base Request for updating a `Plan`, useful for creating customer `Plan` update functions
updatePlanBase
    :: PlanId            -- ^ The ID of the `Plan` to update
    -> Maybe Name        -- ^ The `Name` of the `Plan` to update
    -> Maybe Description -- ^ The `Description` of the `Plan` to update
    -> MetaData          -- ^ The `MetaData` for the `Plan`
    -> StripeRequest Plan
updatePlanBase
    (PlanId planid)
    name
    description
    metadata    = request
  where request = mkStripeRequest POST url params
        url     = "plans" </> planid
        params  = toMetaData metadata ++ getParams [
                      ("name", name)
                    , ("statement_description", description)
                  ]

------------------------------------------------------------------------------
-- | Update a `Plan` `Description`
updatePlanDescription
    :: PlanId      -- ^ The ID of the `Plan` to update
    -> Description -- ^ The `Description` of the `Plan` to update
    -> StripeRequest Plan
updatePlanDescription
    (PlanId planid)
    description = request
  where request = mkStripeRequest POST url params
        url     = "plans" </> planid
        params  = getParams [
                    ("statement_description", Just description)
                  ]

------------------------------------------------------------------------------
-- | Update a `Plan` `Name`
updatePlanName
    :: PlanId      -- ^ The ID of the `Plan` to update
    -> Description -- ^ The `Name` of the `Plan` to update
    -> StripeRequest Plan
updatePlanName
    (PlanId planid)
    name = request
  where request = mkStripeRequest POST url params
        url     = "plans" </> planid
        params  = getParams [
                    ("name", Just name)
                  ]

------------------------------------------------------------------------------
-- | Delete a `Plan`
deletePlan
    :: PlanId -- ^ The ID of the `Plan` to delete
    -> StripeRequest StripeDeleteResult
deletePlan
    (PlanId planid) = request
  where request = mkStripeRequest DELETE url params
        url     = "plans" </> planid
        params  = []
