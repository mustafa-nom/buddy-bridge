# TODO

## Current Priority

Build a playable MVP of Buddy Bridge.

## Setup

- [ ] Confirm Rojo project structure
- [ ] Confirm Selene config
- [ ] Create base folder structure
- [ ] Create RemoteService
- [ ] Create Constants, RoleTypes, RoomTypes
- [ ] Create ServerBootstrap
- [ ] Create ClientBootstrap

## Core Services

- [ ] Implement MatchService
- [ ] Implement RoleService
- [ ] Implement RoundService skeleton
- [ ] Implement RoomService skeleton
- [ ] Implement ScenarioService
- [ ] Implement ScoringService
- [ ] Implement RewardService session data

## UI Controllers

- [ ] Implement RoleSelectController
- [ ] Implement RoundHudController
- [ ] Implement GuideManualController
- [ ] Implement GuideControlsController
- [ ] Implement RunnerController
- [ ] Implement ScoreScreenController
- [ ] Implement NotificationController
- [ ] Implement LobbyProgressionController

## MVP Gameplay

### Lobby

- [ ] Pair two players
- [ ] Select Runner/Guide roles
- [ ] Start round
- [ ] Return to lobby

### Button Room

- [ ] Generate button scenario server-side
- [ ] Display buttons to Runner
- [ ] Display guide clues to Guide
- [ ] Validate button press server-side
- [ ] Correct button opens path
- [ ] Wrong button triggers consequence
- [ ] Update mistakes and trust points

### Bridge Builder

- [ ] Add bridge objects
- [ ] Guide can activate bridge pieces
- [ ] Runner can cross
- [ ] Server validates Guide controls
- [ ] Room completes at endpoint

### Door Decoder

- [ ] Generate door scenario server-side
- [ ] Display door messages
- [ ] Display guide clue card
- [ ] Validate door choice server-side
- [ ] Correct door advances
- [ ] Wrong door triggers consequence

## Scoring and Rewards

- [ ] Track timer
- [ ] Track mistakes
- [ ] Track trust points
- [ ] Calculate rank
- [ ] Grant Trust Seeds
- [ ] Show final score screen
- [ ] Update lobby progression

## Polish

- [ ] Add sounds
- [ ] Add simple effects
- [ ] Add clear UI styling
- [ ] Add short tutorial prompts
- [ ] Add replay button
- [ ] Add demo-friendly flow

## Verification

- [ ] Test in 1-player debug mode if implemented
- [ ] Test in 2-player Studio server
- [ ] Test Runner leaving
- [ ] Test Guide leaving
- [ ] Test remote spam
- [ ] Run `selene src/`
- [ ] Check all files under 500 lines
- [ ] Confirm no critical output errors
