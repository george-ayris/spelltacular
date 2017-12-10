module SpellingPage exposing (Msg, Model, update, view, start, initialModel, SpellingsCompletedModel, translator)

import Time
import Html exposing (Html, div, button, h1, text, input)
import Html.Events exposing (onClick, onInput)
import Array
import Task


type Msg
    = SpellingsLoaded Time.Time Model
    | SpellingStarted Time.Time
    | SpellingBeingWritten String
    | StopSpellingTimer
    | CheckSpelling Time.Time
    | SpellingsCompleted SpellingsCompletedModel


translator : (SpellingsCompletedModel -> parentMsg) -> (Msg -> parentMsg) -> (Msg -> parentMsg)
translator translateCompletedMessage wrapOtherMessages msg =
    case msg of
        SpellingsCompleted model ->
            translateCompletedMessage model

        x ->
            wrapOtherMessages x


type Timing
    = NoTimings
    | StartTime Time.Time
    | Difference Time.Time


type alias SpellingWithTiming =
    { spelling : String, timing : Timing }


type alias Model =
    { unTestedSpellings : List String, currentSpellingIndex : Int }


type alias SpellingsCompletedModel =
    List { spelling : String, timeTaken : Time.Time }


initialModel : Model
initialModel =
    Model Array.empty -1


start : Time.Time -> List String -> Msg
start time spellings =
    SpellingsLoaded time (mapToModel spellings)


mapToModel : List String -> Model
mapToModel words =
    let
        mapStringToSpelling =
            \string -> { spelling = string, timing = NoTimings }
    in
        { spellings = (Array.fromList <| List.map mapStringToSpelling words), currentSpellingIndex = 0 }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ spellings, currentSpellingIndex } as model) =
    case msg of
        SpellingsLoaded now loadedSpellings ->
            let
                firstSpelling =
                    getSpelling 0 loadedSpellings.spellings

                spellingsWithTiming =
                    Array.set 0 ({ firstSpelling | timing = StartTime now }) loadedSpellings.spellings
            in
                ( Model spellingsWithTiming 0, Cmd.none )

        SpellingStarted now ->
            let
                currentSpelling =
                    getSpelling currentSpellingIndex spellings

                newSpellings =
                    Array.set currentSpellingIndex ({ currentSpelling | timing = StartTime now }) spellings
            in
                ( { model | spellings = newSpellings }, Cmd.none )

        SpellingBeingWritten updatedSpelling ->
            let
                currentSpelling =
                    getSpelling currentSpellingIndex spellings

                newSpellings =
                    Array.set currentSpellingIndex { currentSpelling | spelling = updatedSpelling } spellings
            in
                ( { model | spellings = newSpellings }, Cmd.none )

        StopSpellingTimer ->
            ( model, Task.perform CheckSpelling Time.now )

        CheckSpelling now ->
            let
                nextSpellingIndex =
                    currentSpellingIndex + 1

                currentSpelling =
                    Maybe.withDefault (SpellingWithTiming "Error" NoTimings) <| Array.get currentSpellingIndex spellings

                startTime =
                    case currentSpelling.timing of
                        NoTimings ->
                            Time.second

                        StartTime t ->
                            t

                        Difference t ->
                            Time.second

                newSpellings =
                    Array.set currentSpellingIndex ({ currentSpelling | timing = Difference (now - startTime) }) spellings

                newModel =
                    { model | spellings = newSpellings, currentSpellingIndex = nextSpellingIndex }
            in
                if nextSpellingIndex < Array.length spellings then
                    ( newModel, Task.perform SpellingStarted Time.now )
                else
                    ( newModel, Task.succeed (SpellingsCompleted <| createCompletedSpellingsInfo newModel) |> Task.perform identity )

        SpellingsCompleted x ->
            ( model, Cmd.none )


getSpelling : Int -> Array.Array SpellingWithTiming -> SpellingWithTiming
getSpelling i spellings =
    Maybe.withDefault (SpellingWithTiming "Error" NoTimings) <| Array.get i spellings


createCompletedSpellingsInfo : Model -> SpellingsCompletedModel
createCompletedSpellingsInfo model =
    let
        mapSpellingWithTiming spellingWithTiming =
            { spelling = spellingWithTiming.spelling
            , timeTaken =
                case spellingWithTiming.timing of
                    NoTimings ->
                        0

                    StartTime x ->
                        0

                    Difference t ->
                        t
            }
    in
        List.map mapSpellingWithTiming (Array.toList model.spellings)


view : Model -> Html Msg
view ({ spellings, currentSpellingIndex } as model) =
    div []
        [ text (Maybe.withDefault "ERROR" <| Maybe.map .spelling <| Array.get currentSpellingIndex spellings)
        , input [ onInput SpellingBeingWritten ] []
        , button [ onClick <| StopSpellingTimer ] [ text "Submit" ]
        ]
