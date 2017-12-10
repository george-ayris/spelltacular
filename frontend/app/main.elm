module Main exposing (main)

import Html exposing (Html, div, button, h1, text)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode
import List.Extra as ListE
import Time
import Task
import Array
import SpellingPage


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { currentPage : Page, spellingPageModel : SpellingPage.Model }


type Page
    = Home
    | LoadingSpellings
    | Spelling
    | SpellingResults SpellingPage.SpellingsCompletedModel
    | Error String


init : ( Model, Cmd Msg )
init =
    ( Model Home SpellingPage.initialModel, Cmd.none )


type Msg
    = StartSpellings
    | SpellingsLoaded (Result Http.Error (List String))
    | SpellingPageMsg SpellingPage.Msg
    | SpellingCompleted SpellingPage.SpellingsCompletedModel


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartSpellings ->
            ( { model | currentPage = LoadingSpellings }, loadSpellings )

        SpellingsLoaded result ->
            case result of
                Ok spellings ->
                    ( { model | currentPage = Spelling }, Task.perform (\t -> SpellingPageMsg (SpellingPage.start t spellings)) Time.now )

                Err error ->
                    ( { model | currentPage = Error (toString error) }, Cmd.none )

        SpellingPageMsg subMsg ->
            let
                ( newSpellingPageModel, spellingPageCmd ) =
                    SpellingPage.update subMsg model.spellingPageModel
            in
                ( { model | spellingPageModel = newSpellingPageModel }, Cmd.map (SpellingPage.translator SpellingCompleted SpellingPageMsg) spellingPageCmd )

        SpellingCompleted completedModel ->
            ( { model | currentPage = SpellingResults completedModel }, Cmd.none )


loadSpellings : Cmd Msg
loadSpellings =
    Http.send SpellingsLoaded (Http.get "http://localhost:5000/spellings" (Decode.list Decode.string))


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

        Spelling ->
            Html.map (SpellingPage.translator SpellingCompleted SpellingPageMsg) <| SpellingPage.view model.spellingPageModel

        SpellingResults results ->
            div [] [ text "Well done, spellings completed", div [] <| List.map renderResult results ]

        Error errorMessage ->
            div [] [ text ("Error: " ++ errorMessage) ]


renderResult : { spelling : String, timeTaken : Time.Time } -> Html Msg
renderResult { spelling, timeTaken } =
    div [] [ text spelling, text (toString timeTaken) ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
