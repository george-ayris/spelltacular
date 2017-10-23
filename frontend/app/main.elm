module Main exposing (main)

import Html exposing (Html, div, button, h1, text)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode
import List.Extra as ListE
import Time
import Task
import Array


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { currentPage : Page }


type Page
    = Home
    | LoadingSpellings
    | Spelling SpellingData
    | SpellingCompleted SpellingData
    | Error String


type Timing
    = NoTimings
    | StartTime Time.Time
    | Difference Time.Time


type alias SpellingWithTiming =
    { spelling : String, timing : Timing }


type alias SpellingData =
    { spellings : Array.Array SpellingWithTiming, currentSpellingIndex : Int }


init : ( Model, Cmd Msg )
init =
    ( Model Home, Cmd.none )


type Msg
    = StartSpellings
    | SpellingsLoaded (Result Http.Error SpellingData)
    | SpellingStarted SpellingData Time.Time
    | StopSpellingTimer SpellingData
    | CorrectSpelling SpellingData Time.Time


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartSpellings ->
            ( { model | currentPage = LoadingSpellings }, loadSpellings )

        SpellingsLoaded result ->
            case result of
                Ok spellingData ->
                    ( { model | currentPage = Spelling spellingData }, Task.perform (SpellingStarted spellingData) Time.now )

                Err error ->
                    ( { model | currentPage = Error (toString error) }, Cmd.none )

        SpellingStarted ({ spellings, currentSpellingIndex } as spellingData) now ->
            let
                currentSpelling =
                    Maybe.withDefault (SpellingWithTiming "Error" NoTimings) <| Array.get currentSpellingIndex spellings

                newSpellings =
                    Array.set currentSpellingIndex ({ currentSpelling | timing = StartTime now }) spellings
            in
                ( { model | currentPage = Spelling { spellingData | spellings = newSpellings } }, Cmd.none )

        StopSpellingTimer spellingData ->
            ( model, Task.perform (CorrectSpelling spellingData) Time.now )

        CorrectSpelling ({ spellings, currentSpellingIndex } as spellingData) now ->
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

                newSpellingData =
                    { spellingData | spellings = newSpellings, currentSpellingIndex = nextSpellingIndex }
            in
                if nextSpellingIndex < Array.length spellings then
                    ( { model | currentPage = Spelling newSpellingData }, Task.perform (SpellingStarted newSpellingData) Time.now )
                else
                    ( { model | currentPage = SpellingCompleted newSpellingData }, Cmd.none )


loadSpellings : Cmd Msg
loadSpellings =
    Http.send SpellingsLoaded (Http.get "http://localhost:5000/spellings" decodeSpellingsData)


decodeSpellingsData : Decode.Decoder SpellingData
decodeSpellingsData =
    let
        mapStringToSpelling =
            \string -> { spelling = string, timing = NoTimings }
    in
        Decode.map (\x -> SpellingData (Array.fromList <| List.map mapStringToSpelling x) 0) (Decode.list Decode.string)


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Spelltacular" ]
        , renderPage model
        ]


renderPage : Model -> Html Msg
renderPage model =
    case model.currentPage of
        Home ->
            div []
                [ text "Welcome"
                , button [ onClick StartSpellings ] [ text "Start" ]
                ]

        LoadingSpellings ->
            div []
                [ text "Conjuring spellings" ]

        Spelling ({ spellings, currentSpellingIndex } as spellingData) ->
            div []
                [ text (Maybe.withDefault "ERROR" <| Maybe.map .spelling <| Array.get currentSpellingIndex spellings)
                , button [ onClick <| StopSpellingTimer spellingData ] [ text "Next" ]
                ]

        SpellingCompleted { spellings } ->
            div [] [ text "Well done, spellings completed", div [] <| Array.toList <| Array.map getTimeDifference spellings ]

        Error errorMessage ->
            div [] [ text ("Error: " ++ errorMessage) ]


getTimeDifference : SpellingWithTiming -> Html Msg
getTimeDifference s =
    case s.timing of
        NoTimings ->
            div [] [ text "No timing" ]

        StartTime _ ->
            div [] [ text "Only start" ]

        Difference d ->
            div [] [ text (toString d) ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
